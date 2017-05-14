package Games::Rezrov::StoryFile;
# manages game file data and implements many non-io-related opcodes.
# Opcode inclusion made more sense in Java, where the data was a
# more sensible instance variable; oh well.
#
# This package is now STATIC, and does not instantiate objects, because:
#  - it's faster not to have to dereference instance data
#  - it's faster not to have to pass $self with every opcode/method call
#
# Not pretty, but v5+ games need all the speed they can get.
# See TPJ #13 for why  :)
#

use strict;
use FileHandle;
use Carp qw(cluck croak confess);
#use integer;
# "use integer" is required for mod() to work correctly; see
# math tests in "etude.z5"

use Games::Rezrov::ZHeader;
use Games::Rezrov::ZObject;
use Games::Rezrov::ZText;
use Games::Rezrov::ZStatus;
use Games::Rezrov::ZDict;
use Games::Rezrov::ZReceiver;
use Games::Rezrov::ZConst;
use Games::Rezrov::ZIO_Tools;
use Games::Rezrov::ZObjectCache;
use Games::Rezrov::Inliner;
use Games::Rezrov::Quetzal;
use Games::Rezrov::ZObjectStatus;

# constants are SLOWER when they're accessed in other packages...WTF??
use constant FRAME_MAX_LOCAL_VARIABLES => 15;
use constant FRAME_DUMMY => 0;
use constant FRAME_PROCEDURE => 1;
use constant FRAME_FUNCTION => 2;

use constant GV_SCORE => 1;
# 8.2.3.1: global variable holding game score (v3)

# frame indices:
use constant FRAME_RPC => 0;
use constant FRAME_ARGC => 1;
use constant FRAME_CALL_TYPE => 2;
use constant FRAME_LOCAL => 3;
use constant FRAME_ROUTINE => 18;
# spec 5.2; there are 15 local vars

use constant CALL => 1;
use constant PRINT_PADDR => 2;

my $global_variable_address;
my $global_variable_word_addr;
my $header;
my $prompt_buffer;

my $call_stack;
my $lines_wrote;
my $transcript_filename;

# FIX ME, RESET THESE AS NECESSARY:
my $fm = 0;
my $selected_streams;
my $last_score = 0;
my $zios;
my $flushing;
my $wrote_something;
my $version;
my $groks_f3;
my $columns;
my $rows;
my ($ztext, $zstatus);
my $last_savefile;
my $quetzal;
my $tailing;
my $player_object;
my $player_confirmed;

my $current_room;
my $object_cache;
my $current_input_stream;
my $input_filehandle;
my $window_cursors;
my $zdict;
my $push_command;
my $guessing_title;
my $full_version_output;
my $game_title;
my $last_prompt;
my $undo_slots;
my $last_input;
my $game_filename;
my $font_3_disabled;

my %alternate_dictionaries;

my %candidate_po;

$Games::Rezrov::StoryFile::PC = 1;
# current game PC.

$Games::Rezrov::StoryFile::STORY_BYTES = undef;
# story file data.
# HACK: this is *static* for speed.  having to deref $self->bytes()
# all the time seems like it's going to be really slow.
# a further compromise might be to ditch the "object" approach altogether
# and just export all these functions; story data can still be kept
# "privately" in this module.

my $dynamic_area;
# bytes in the story that can be changed by the game.
# Used for "verify" opcode and game saves/restores.
# (Also traditionally usually used for restarts, but we Lazily just 
# reload the whole image)

# more for-speed hacks related to writing bytes to the transcript stream:
my $current_window = Games::Rezrov::ZConst::LOWER_WIN;

use constant UNSIGNED_BYTE => 0xff;

use constant LINEFEED => 10;
# ascii

my $buffering;
my ($upper_lines, $lower_lines);
# HACKS, FIX ME

my $current_frame;

my $lines_read = 0;

my $TYPO_NOTIFY;

my $GLOBAL_TEMP_CONTROL;
my $GLOBAL_TEMP_OFFSET;

my %Z_TRANSLATIONS = (
		       0x18 => "UP",
		       0x19 => "DOWN",
		       0x1a => "LEFT",
		       0x1b => "RIGHT",
		       179 => '|',
		       186 => '#',
		       196 => '-',
		       205 => '=',
		     );
# in beyond zork, when the ZIO can't handle font 3, game can
# send control characters

my $INLINE_CODE = '
sub call {
  my ($argv, $type) = @_;
  # call a routine, either as a procedure (result thrown away)
  # or a function (result stored).  First argument of argv
  # is address of function to call.
  if ($argv->[0] == 0) {
    # spec 6.4.3: calls to address 0 return 0
    store_result(0) if ($type == FRAME_FUNCTION);
  } else {
    push_frame($type);
    # make a new frame of specified type
    
    $Games::Rezrov::StoryFile::PC = convert_packed_address($argv->[0], CALL);
    # set the current PC
    
    my $args = GET_BYTE();
    # spec 5.2: routine begins with an arg count
    die "impossible arg count of $args"
      if ($args < 0 || $args > FRAME_MAX_LOCAL_VARIABLES);
    
    #      ZInterpreter.zdb.save("call type " + type + " argc:" + argc + " args:" + args);  # debug
    #      current.arg_count = args;
    my $argc = scalar @{$argv};
    frame_argc($argc - 1);
    # do not count procedure being called in argument count
    
    my $arg;
    my $local_count = 0;
    my $i = 1;
    while (--$args >= 0) {
      # set local variables
      $arg = $version >= 5 ? 0 : GET_WORD();
      # spec 5.2.1: default variables follow if version < 5
#      $_[0]->set_local_var(++$local_count, (--$argc > 0) ? $argv->[$i++] : $arg);
      $current_frame->[FRAME_LOCAL + ++$local_count - 1] =
	(--$argc > 0) ? $argv->[$i++] : $arg;
      # set local variables.  There used to be a set_local_var()
      # method, but it was inlined for speed :(
    }
  }
}

sub store_result_MV {
  # called by opcodes producing a result (stores it).
  my $where = GET_BYTE();
  # see spec 4.2.2, 4.6.
  # zip code handles this in store_operand, and in the case of
  # variable zero, pushes a new variable onto the stack.
  # The store_variable() call only SETS the topmost variable,
  # and does not add a new one.   Is that code ever reached?  WTF!

#  printf STDERR "store_result: %s where:%d\n", $_[1], $where;
#  print STDERR "$where\n";

  if ($where == 0) {
    # routine stack: push value
    # see zmach06e.txt section 7.1 (page 33):

    # A variable number is a byte that indicates a certain variable.
    # The meaning of a variable number is:
    #      0: the top of the routine stack;
    #   1-15: the local variable with that number;
    # 16-255: the global variable with that number minus 16.
    
    # Writing to the variable with number 0 means to push a value onto
    # the routine stack; reading this variable means pulling a value off.
    routine_push(UNSIGNED_WORD($_[0]));
    # make sure the value is cast into unsigned form.
    # see add() for a lengthy debate on the subject.
  } else {
    set_variable($where, $_[0]);
    # set_variable does casting for us
  }
}

sub store_result_GV {
  # called by opcodes producing a result (stores it).
  $GLOBAL_TEMP_CONTROL = GET_BYTE();
  # see spec 4.2.2, 4.6.
  # zip code handles this in store_operand, and in the case of
  # variable zero, pushes a new variable onto the stack.
  # The store_variable() call only SETS the topmost variable,
  # and does not add a new one.   Is that code ever reached?  WTF!

#  printf STDERR "store_result: %s where:%d\n", $_[1], $GLOBAL_TEMP_CONTROL;
#  print STDERR "$GLOBAL_TEMP_CONTROL\n";

  if ($GLOBAL_TEMP_CONTROL == 0) {
    # routine stack: push value
    # see zmach06e.txt section 7.1 (page 33):

    # A variable number is a byte that indicates a certain variable.
    # The meaning of a variable number is:
    #      0: the top of the routine stack;
    #   1-15: the local variable with that number;
    # 16-255: the global variable with that number minus 16.
    
    # Writing to the variable with number 0 means to push a value onto
    # the routine stack; reading this variable means pulling a value off.
    routine_push(UNSIGNED_WORD($_[0]));
    # make sure the value is cast into unsigned form.
    # see add() for a lengthy debate on the subject.
  } else {
    set_variable($GLOBAL_TEMP_CONTROL, $_[0]);
    # set_variable does casting for us
  }
}

sub conditional_jump_MV {
  # see spec section 4.7, zmach06e.txt section 7.3
  # argument: condition
  # "my" vars version: prettier, but slower
  my $control = GET_BYTE();
  
  my $offset = $control & 0x3f;
  # basic address is six low bits of the first byte.
  if (($control & 0x40) == 0) {
    # if "bit 6" is not set, address consists of the six (low) bits 
    # of the first byte plus the next 8 bits.
    $offset = ($offset << 8) + GET_BYTE();
    if (($offset & 0x2000) > 0) {
      # if the highest bit (formerly bit 6 of the first byte)
      # is set...
      $offset |= 0xc000;
      # turn on top two bits
      # FIX ME: EXPLAIN THIS
    }
  }
  
  if ($control & 0x80 ? $_[0] : !$_[0]) {
    # normally, branch occurs when condition is false.
    # however, if topmost bit is set, jump occurs when condition is true.
    if ($offset > 1) {
      # jump
      jump($offset);
    } else {
      # instead of jump, this is a RTRUE (1) or RFALSE (0)
      ret($offset);
    }
  }
}

sub conditional_jump_GV {
  # see spec section 4.7, zmach06e.txt section 7.3
  # argument: condition
  # global variables version: hideous, but faster? (no "my" variable create/destroy)
  $GLOBAL_TEMP_CONTROL = GET_BYTE();
  
  $GLOBAL_TEMP_OFFSET = $GLOBAL_TEMP_CONTROL & 0x3f;
  # basic address is six low bits of the first byte.
  if (($GLOBAL_TEMP_CONTROL & 0x40) == 0) {
    # if "bit 6" is not set, address consists of the six (low) bits 
    # of the first byte plus the next 8 bits.
    $GLOBAL_TEMP_OFFSET = ($GLOBAL_TEMP_OFFSET << 8) + GET_BYTE();
    if (($GLOBAL_TEMP_OFFSET & 0x2000) > 0) {
      # if the highest bit (formerly bit 6 of the first byte)
      # is set...
      $GLOBAL_TEMP_OFFSET |= 0xc000;
      # turn on top two bits
      # FIX ME: EXPLAIN THIS
    }
  }
  
  if ($GLOBAL_TEMP_CONTROL & 0x80 ? $_[0] : !$_[0]) {
    # normally, branch occurs when condition is false.
    # however, if topmost bit is set, jump occurs when condition is true.
    if ($GLOBAL_TEMP_OFFSET > 1) {
      # jump
      jump($GLOBAL_TEMP_OFFSET);
    } else {
      # instead of jump, this is a RTRUE (1) or RFALSE (0)
      ret($GLOBAL_TEMP_OFFSET);
    }
  }
}


sub add {
  # signed 16-bit addition
  # args: x, y
#  my ($self, $x, $y) = @_;
#  die if $x & 0x8000 or $y & 0x8000;

#  my $result = unsigned_word(signed_word($x) + signed_word($y));
  # this does not work correctly; example:
  # die in zork 1 (teleport chasm, N [grue]), score has -10 added
  # to it, result is 65526.  Since value is always stored internally,
  # do not worry about converting to unsigned.  Brings up a larger issue:
  # sometimes store_result writes data to the story, in which case
  # we need an unsigned value!  Solution -- do this casting only if
  # we _need_ to, ie writing bytes to the story: see set_global_var()

  # Unfortunately, this breaks Trinity:
  # count:538 pc:97444 type:2OP opcode:20 (add) operands:36910,100
  # here we get into trouble because the sum uses the sign bit (0x8000) 
  # but it is an UNSIGNED value!  So in this case we *must* make sure
  # the result is unsigned.  Solution #2: change store_result to
  # make sure everything is unsigned.  Cast to signed only when we are
  # sure the data is signed (see set_variable, scores)
  
#  store_result(signed_word($x) + signed_word($y));
  store_result(SIGNED_WORD($_[0]) + SIGNED_WORD($_[1]));
}

sub subtract {
  # signed 16-bit subtraction: args: $x, $y
  store_result(SIGNED_WORD($_[0]) - SIGNED_WORD($_[1]));
}

sub multiply {
  # signed 16-bit multiplication; args: $x, $y
  store_result(SIGNED_WORD($_[0]) * SIGNED_WORD($_[1]));
}

sub divide {
  # signed 16-bit division; args: $x, $y
  store_result(SIGNED_WORD($_[0]) / SIGNED_WORD($_[1]));
}

sub compare_jg {
  # jump if a is greater than b; signed 16-bit comparison
  conditional_jump(SIGNED_WORD($_[0]) > SIGNED_WORD($_[1]));
}

sub compare_jl {
  # jump if a is less than b; signed 16-bit comparison
  conditional_jump(SIGNED_WORD($_[0]) < SIGNED_WORD($_[1]));
}

sub output_stream {
  #
  # select/deselect output streams.
  # 
  my $str = SIGNED_WORD($_[0]);
  my $table_start = $_[1];

  return if $str == 0;
  # selecting stream 0 does nothing

#  print STDERR "output_stream $str\n";
  my $astr = abs($str);
  my $selecting = $str > 0 ? 1 : 0;
  if ($astr == Games::Rezrov::ZConst::STREAM_REDIRECT) {
    #
    #  stream 3: redirect output to a table exclusively (no other streams)
    #
    my $stack = $zios->[Games::Rezrov::ZConst::STREAM_REDIRECT];
    if ($selecting) {
      #
      # selecting
      #
      my $buf = new Games::Rezrov::ZReceiver();
      $buf->misc($table_start);
      push @{$stack}, $buf;
      fatal_error("illegal number of stream3 opens!") if @{$stack} > 16;
      # 7.1.2.1.1: max 16 legal redirects
    } else {
      #
      # deselecting: copy table to memory
      #
      my $buf = pop @{$stack};
      my $table_start = $buf->misc();
      my $pointer = $table_start + 2;
      my $buffer = $buf->buffer();
#      printf STDERR "Writing redirected chunk %s to %d\n", $buffer, $pointer;
      for (my $i=0; $i < length($buffer); $i++) {
	set_byte_at($pointer++, ord substr($buffer,$i,1));
      }
      set_word_at($table_start, ($pointer - $table_start - 2));
      # record number of bytes written

#      printf STDERR "table redir; %d / %d = %s\n", length($buffer), get_word_at($table_start), get_string_at(24663, length($buffer));

      if (@{$stack}) {
	# this is stacked; keep redirection on (7.1.2.1.1)
	$selected_streams->[$astr] = 1;
      }
      if ($version == 6) {
	# 7.1.2.1
	fatal_error("stream 3 close under v6, needs a-fixin");
      }
    }
  } elsif ($astr == Games::Rezrov::ZConst::STREAM_TRANSCRIPT) {
    if ($selecting) {
#      print STDERR "opening transcript\n";
      if (my $filename = $transcript_filename ||
	  filename_prompt("-check" => 1,
			  "-ext" => "txt",
			 )) {
	$transcript_filename = $filename;
	# 7.1.1.2: only ask once per session
	my $fh = new FileHandle;
	if ($fh->open(">$filename")) {
	  $zios->[Games::Rezrov::ZConst::STREAM_TRANSCRIPT] = $fh;
	} else {
	  write_text(sprintf "Yikes, I can\'t open %s: %s...", $filename, lc($!));
	  $selecting = 0;
	}
      } else {
	$selecting = 0;
      }
      unless ($selecting) {
	newline();
	newline();
      }
    } else {
      # closing transcript
      my $fh = $zios->[Games::Rezrov::ZConst::STREAM_TRANSCRIPT];
      $fh->close() if $fh;
    }
  } elsif ($astr == Games::Rezrov::ZConst::STREAM_COMMANDS) {
    if ($selecting) {
      my $filename = filename_prompt("-ext" => "cmd",
				     "-check" => 1);
      if ($filename) {
	my $fh = new FileHandle();
	if ($fh->open(">$filename")) {
	  $zios->[Games::Rezrov::ZConst::STREAM_COMMANDS] = $fh;
	  write_text("Recording to $filename.");
	} else {
	  write_text("Can\'t write to $filename.");
	  $selecting = 0;
	}
      }
    } else {
      my $fh = $zios->[Games::Rezrov::ZConst::STREAM_COMMANDS];
      if ($fh) {
	$fh->close();
	write_text("Recording stopped.");
      } else {
	write_text("Um, I\'m not recording now.");
      }
    }
    newline();
  } elsif ($astr == Games::Rezrov::ZConst::STREAM_STEAL) {
#    printf STDERR "steal: %s\n", $selecting;
    $zios->[Games::Rezrov::ZConst::STREAM_STEAL] = $selecting ? new Games::Rezrov::ZReceiver() : undef;
  } elsif ($astr != Games::Rezrov::ZConst::STREAM_SCREEN) {
    fatal_error("Unknown stream $str");
  }

  $selected_streams->[$astr] = $selecting;
}

sub erase_window {
  my $window = SIGNED_WORD($_[0]);
  my $zio = screen_zio();
  if ($window == -1) {
    # 8.7.3.3:
#    $self->split_window(Games::Rezrov::ZConst::UPPER_WIN, 0);
    # WRONG!
    split_window(0);
    # collapse upper window to size 0
    clear_screen();
    # erase the entire screen
    reset_write_count();
    set_window(Games::Rezrov::ZConst::LOWER_WIN);
    set_cursor(($version == 4 ? $rows : 1), 1);
    # move cursor to the appropriate line for this version;
    # hack: at least it\'s abstracted :)
  } elsif ($window < 0 or $window > 1) {
    $zio->fatal_error("erase_window $window !");
  } else {
    #
    #  erase specified window
    #
    my $restore = $zio->get_position(1);
    my ($start, $end);
    if ($window == Games::Rezrov::ZConst::UPPER_WIN) {
      $start = 0;
      $end = $upper_lines;
    } elsif ($window == Games::Rezrov::ZConst::LOWER_WIN) {
      $start = $upper_lines;
      $end = $rows;
      reset_write_count();
    } else {
      die "clear window $window!";
    }
    for (my $i = $start; $i < $end; $i++) {
#      $zio->erase_line($i);
      $zio->absolute_move(0, $i);
      $zio->clear_to_eol();
    }
    &$restore();
    # restore cursor position
  }
}

sub jump {
  # unconditional jump; modifies PC
  # see zmach06e.txt, section 8.4.
  # argument: new offset
  $Games::Rezrov::StoryFile::PC += SIGNED_WORD($_[0] - 2);
}

sub print_num {
  # print the given signed number.
  write_text(SIGNED_WORD($_[0]));
}

sub inc_jg {
  my ($variable, $value) = @_;
  # increment a variable, and branch if it is now greater than value.
  # **indirect?**
  $value = SIGNED_WORD($value);

  my $before = SIGNED_WORD(get_variable($variable));
  my $new_val = SIGNED_WORD($before + 1);
  set_variable($variable, $new_val);
  conditional_jump($new_val > $value);
}

sub increment {
  # increment a variable (16 bits, signed).  arg: variable #
  # **indirect?**
  my $value = SIGNED_WORD(get_variable($_[0])) + 1;
  set_variable($_[0], UNSIGNED_WORD($value));
}

sub decrement {
  # decrement a variable (16 bits, signed)
  # **indirect?**
  my $value = SIGNED_WORD(get_variable($_[0])) - 1;
  set_variable($_[0], UNSIGNED_WORD($value));
}

sub dec_jl {
  my ($variable, $value) = @_;
  # decrement a signed 16-bit variable, and branch if it is now less than value.
  # **indirect?**
  $value = SIGNED_WORD($value);

  my $before = SIGNED_WORD(get_variable($variable));
  my $new_val = SIGNED_WORD($before - 1);
  set_variable($variable, UNSIGNED_WORD($new_val));
  conditional_jump($new_val < $value);
}

sub mod {
  # store remainder after signed 16-bit division
  if (1) {
    use integer;
    # without "use integer", "%" operator flunks etude.z5 tests
    # (on all systems? linux anyway).
    # For example: perl normally says (13 % -5) == -2;
    #              it "should" be 3, or (13 - (-5 * -2))
    #
    # "use integer" computes math ops in integer, thus always
    # rounding towards zero and getting around the problem.
    #
    # Unfortunately, "use integer" must be scoped here lest it play
    # havoc in other places which require floating point division:
    # e.g. pixel-based text wrapping.
    store_result(SIGNED_WORD($_[0]) % SIGNED_WORD($_[1]));
  } else {
    # an alternative workaround?:
    my $x = SIGNED_WORD($_[0]);
    my $y = SIGNED_WORD($_[1]);
    my $times = int($x / $y);
    # how many times does $y fit into $x; always round towards zero!
    store_result($x - ($y * $times));
  }
}

sub z_store {
  # opcode to set variable
  # **indirect**
  set_variable($_[0], $_[1], 1);
  # when called as an opcode, set indirect stack reference flag
}

sub set_variable {
  # args: 
  #   $_[0] = $variable
  #   $_[1] = $value
  #   $_[2] = if nonzero, "indirect stack reference" mode (see draft spec 1.1)
#  printf STDERR "set_variable %s = %s\n", $_[1], $_[2];
  # see spec 4.2.2
  if ($_[0] == 0) {
    # "top of routine stack": do we push, or just set?
    # draft spec 1.1 says under certain circumstances we should just
    # manipulate the first stack variable, and not push/pop.
    # 
    # - for the 7 opcodes mentioned, frotz 2.43 only seems to follow
    #   the 1.1 spec for 3 of them: 
    # 
    #   z_store, z_load, z_pull: set top of stack
    #   z_inc, z_inc_chk: push onto stack
    #   z_dec, z_dec_chk: pop from stack

    if ($_[2]) {
      # indirect stack reference mode
      $current_frame->[$#$current_frame] = UNSIGNED_WORD($_[1]);
      # just set top variable, don\'t push
    } else {
      routine_push($_[1]);
    }
  } elsif ($_[0] <= 15) {
    # local variable
    $current_frame->[FRAME_LOCAL + $_[0] - 1] = UNSIGNED_WORD($_[1]);
#    printf "set local var %d to %d\n", $_[0], $current_frame->[FRAME_LOCAL + $_[0] - 1];
    # numbered starting at 1, not 0
  } else {
    # global
    $_[0] -= 16;
    # indexed starting at 0

    set_global_var($_[0], UNSIGNED_WORD($_[1]));
  }
}

sub art_shift {
  # sect15.html#art_shift; ARiThmetic shift
  my $number = SIGNED_WORD($_[0]);
  my $places = SIGNED_WORD($_[1]);
  store_result($places > 0 ? $number << $places : $number >> abs($places));
  # sign bit persists after right shift
}

sub log_shift {	
  # sect15.html#log_shift; LOGical shift
  my $number = UNSIGNED_WORD($_[0]);
  my $places = SIGNED_WORD($_[1]);
  store_result($places > 0 ? $number << $places : abs($number) >> abs($places));
  # sign bit cleared during right shift
}

sub get_property_length {
  # given the literal address of a property data block,
  # find and store size of the property data (number of bytes).
  # example usage: "inventory" cmd.
  # arg: address
  my $address = $_[0];

#  die "get_property_length";
  # given the literal address of a property data block,
  # find and store size of the property data (number of bytes).
  # example usage: "inventory" cmd
  my $addr = SIGNED_WORD($address - 1);
  # subtract one because we are given data start location, not 
  # the index location (yuck).  Also account for possible rollover;
  # one example: (1) start sorcerer.  (2) "ne" (3) "frotz me".
  # int rollover crash: 0 becomes -1 instead of 65535.
  my $size_byte = get_byte_at($addr & 0xffff);
  my $result;
  if ($version <= 3) {
    # 12.4.1
    $result = ($size_byte >> 5) + 1;
  } else {
    if (($size_byte & 0x80) > 0) {
      # spec 12.4.2.1: this is the second size byte, length
      # is in bottom 6 bits
      $result = $size_byte & 0x3f;
      if ($result == 0) {
	# 12.4.2.1.1
#	print STDERR "wacky inform compiler size; check this\n";
	$result = 64;
      }
    } else {
      # 12.4.2.2
      $result = (($size_byte & 0x40) > 0) ? 2 : 1;
    }
  }
  store_result($result);
}

sub z_not {
    # sect15.html#not
    store_result(~$_[0]);
}

sub zo_verify {
  # verify game image.
  # in most Infocom games this seems to be either "$ve" or "$verif".
  # sect15.html#verify
  my $stat = $header->static_memory_address();
  my $flen = $header->file_length();
  my $sum = 0;
  for (my $i = 0x40; $i < $flen; $i++) {
    $sum += ($i < $stat) ? save_area_byte($i) : GET_BYTE_AT($i);
  }
  $sum = $sum % 0x10000;
  conditional_jump($sum == $header->file_checksum());
}

sub copy_table {
  # sect15.html#copy_table
  my ($first, $second, $size) = @_;

  $size = SIGNED_WORD($size);

#  printf STDERR "table copy from %d=>%d; %s\n", $first, $second, get_string_at($first, $size);

  my $len = abs($size);
  my $i;
  if ($second == 0) {
    # zero out all bytes in first table
    for ($i = 0; $i < $len; $i++) {
      set_byte_at($first + $i, 0);
    }
  } elsif ($size < 0) {
    # we *must* copy forwards, even if this corrupts first table
#    untested();
    for ($i = 0; $i < $len; $i++) {
      set_byte_at($second + $i, get_byte_at($first + $i));
    }    
  } else {
    # copy first into second; since they might overlap, save off first
    my @buf;
    for ($i = 0; $i < $len; $i++) {
      $buf[$i] = get_byte_at($first + $i);
    }
    for ($i = 0; $i < $len; $i++) {
      set_byte_at($second + $i, $buf[$i]);
    }
  }

#  printf STDERR "after table copy: %s\n", get_string_at($second, $size);
}

sub set_global_var {
  # set a global variable
  set_word_at($global_variable_address + ($_[0] * 2), $_[1]);
#  printf STDERR "set gv %d to %d\n", @_;

  if ($_[0] == GV_SCORE and
      Games::Rezrov::ZOptions::EMULATE_NOTIFY() and
      !$header->is_time_game()) {
    # 8.2.3.1: "2nd" global variable holds score 
    # ("2nd" variable is index #1)
    my $score = SIGNED_WORD($_[1]);
    my $diff = $score - $last_score;
    if ($diff and Games::Rezrov::ZOptions::notifying()) {
      write_text(sprintf "[Your score just went %s by %d points, for a total of %d.]",
		 ($diff > 0 ? "up" : "down"),
		 abs($diff), $score);
      newline();
      if ($last_score == 0) {
	write_text("[NOTE: you can toggle score notification on or off at any time with the NOTIFY command.]");
	newline();
      }
    }
    $last_score = $score;
  }
}

sub random {
  my $value = SIGNED_WORD($_[0]);
  # return a random number between 1 and specified number.
  # With arg 0, seed random number generator, return 0
  # With arg < 0, seed with that value, return 0
  my $result = 0;
  if ($value == 0) {
    # seed the random number generator
    srand();
  } elsif ($value < 0) {
    # use specified value as a seed
    srand($value);
  } else {
    $result = int(rand($value)) + 1;
  }
  store_result($result);
}

sub get_variable_GV2 {
  # $_[0]: variable
  # $_[1]: indirect stack reference mode
  # global variables version: hideous, but faster? (no "my" variable create/destroy)
  #
  # Testing reveals heaviest data access seems to be in the order
  # local variables, global variables, routine variables.
  # Re-order to reflect this.
  #
  
  if ($_[0] > 0 and $_[0] <= 15) {
    # a local variable
#    print STDERR "get_variable: local\n";
    return $current_frame->[FRAME_LOCAL + $_[0] - 1];
    # numbered starting from 1, not 0
  } elsif ($_[0] != 0) {
    # a global variable
#    print STDERR "get_variable: global\n";

    #  disgusting, but possibly faster?
    #  use a global, avoiding declaration/destruction of $tmp:
    $GLOBAL_TEMP_OFFSET = $global_variable_address + (($_[0] - 16) * 2);
    return GET_WORD_AT($GLOBAL_TEMP_OFFSET);
  } else {
    # a routine stack variable
    # section 4.2.2:
    # pop from top of routine stack
#    print STDERR "get_variable: routine\n";
    if ($_[1]) {
      # indirect stack reference
      return $current_frame->[$#$current_frame];
    } else {
      return routine_pop();
    }
  }
}

sub get_variable_GV3 {
  # EXPERIMENTAL:
  # halfway-to-inlinable, except for $_[1]  :/
  # - also assumes global variable table is on a word boundary,
  #   which sadly will not work

  # $_[0]: variable
  # $_[1]: indirect stack reference mode
  # global variables version: hideous, but faster? (no "my" variable create/destroy)
  #
  # Testing reveals heaviest data access seems to be in the order
  # local variables, global variables, routine variables.
  # Re-order to reflect this.
  #
  
  return ($_[0] > 0 and $_[0] <= 15) ?
    $current_frame->[FRAME_LOCAL + $_[0] - 1]
      # a local variable
     
      : (

	 $_[0] != 0 ? 
	 # a global variable
#	 vec($Games::Rezrov::StoryFile::STORY_BYTES, ($global_variable_word_addr + $_[0] - 16), 16)
	 die("this will not work")
	 :
	 (
	  # a routine stack variable
	  # section 4.2.2:
	  # pop from top of routine stack
	  $_[1] ? $current_frame->[$#$current_frame] : routine_pop()
	 )

	);
}

sub get_variable_GV4 {
  # EXPERIMENTAL:
  # halfway-to-inlinable, except for $_[1]  :/

  # $_[0]: variable
  # $_[1]: indirect stack reference mode
  # global variables version: hideous, but faster? (no "my" variable create/destroy)
  #
  # Testing reveals heaviest data access seems to be in the order
  # local variables, global variables, routine variables.
  # Re-order to reflect this.
  #
  
  return ($_[0] > 0 and $_[0] <= 15) ?
    $current_frame->[FRAME_LOCAL + $_[0] - 1]
      # a local variable
     
      : (

	 $_[0] != 0 ? 
	 # a global variable
#	 vec($Games::Rezrov::StoryFile::STORY_BYTES, ($global_variable_word_addr + $_[0] - 16), 16)
	 die("this will not work")
	 :
	 (
	  # a routine stack variable
	  # section 4.2.2:
	  # pop from top of routine stack
	  $_[1] ? $current_frame->[$#$current_frame] : routine_pop()
	 )

	);
}


';

Games::Rezrov::Inliner::inline(\$INLINE_CODE);
eval $INLINE_CODE;
undef $INLINE_CODE;

if (1) {
  *Games::Rezrov::StoryFile::conditional_jump = \&Games::Rezrov::StoryFile::conditional_jump_GV;
  *Games::Rezrov::StoryFile::get_variable = \&Games::Rezrov::StoryFile::get_variable_GV2;
  *Games::Rezrov::StoryFile::store_result = \&Games::Rezrov::StoryFile::store_result_GV;
} else {
  *Games::Rezrov::StoryFile::conditional_jump = \&Games::Rezrov::StoryFile::conditional_jump_MV;
  *Games::Rezrov::StoryFile::get_variable = \&Games::Rezrov::StoryFile::get_variable_MV;
  *Games::Rezrov::StoryFile::store_result = \&Games::Rezrov::StoryFile::store_result_MV;
}

1;

sub new {
  my ($type, $filename, $zio) = @_;
  my $self = [];
  bless $self, $type;
  $zio->set_window(Games::Rezrov::ZConst::LOWER_WIN);
  $game_filename = $filename;
  $zios = [];
  $zios->[Games::Rezrov::ZConst::STREAM_SCREEN] = $zio;
  $zios->[Games::Rezrov::ZConst::STREAM_REDIRECT] = [];
  # this stream redirects to memory and can be a stack
  $selected_streams = [];

  $version = 0;
  # don't even ask :P

  return $self;
}

sub compare_jz {
  # branch if the value is zero
  conditional_jump($_[0] == 0);
}

sub setup {
  my $zio = screen_zio();

  die "zio did not set up geometry" unless $rows and $columns;

  # 
  #  Set up "loading" message:
  #
  if ($zio->can_split()) {
    my $message = "The story is loading...";
    clear_screen();
    if ($zio->fixed_font_default()) {
      my $start_x = int(($columns / 2) - length($message) / 2);
      my $start_y = int($rows / 2);
      $zio->write_string($message, $start_x, $start_y);
    } else {
      my $width = $zio->string_width($message);
      my ($max_x, $max_y) = $zio->get_pixel_geometry();
      my $pixel_center = ($max_x / 2) - ($width / 2);
      my $column = ($pixel_center / $max_x) * $columns;
      $zio->absolute_move(int($column), int($rows / 2));
      $zio->write_string($message);
    }
    $zio->update();
  }
  
  load();

   my @no_title_games = (
			 [ Games::Rezrov::ZDict::SAMPLER1 ],
			 [ Games::Rezrov::ZDict::BEYOND_ZORK ]
			);

      foreach my $game (@no_title_games) {
	my @v = @{$game};
	shift @v;
	if (is_this_game(@v)) {
	  Games::Rezrov::ZOptions::GUESS_TITLE(0);
	}
      }

  $current_input_stream = Games::Rezrov::ZConst::INPUT_KEYBOARD;
  $undo_slots = [];
  $window_cursors = [];
  # cursor positions for individual windows
  reset_write_count();
  $object_cache = new Games::Rezrov::ZObjectCache();
  $quetzal = new Games::Rezrov::Quetzal();
  
  # story _must_ be loaded beyond this point...
  Games::Rezrov::ZOptions::EMULATE_NOTIFY(0) if ($version > 3);
  # our notification trick only works for v3 games
  
  $ztext = new Games::Rezrov::ZText();
  $zstatus = new Games::Rezrov::ZStatus();
  $zdict = new Games::Rezrov::ZDict();
  if (Games::Rezrov::ZOptions::EMULATE_UNDO() and
      $zdict->get_dictionary_address("undo")) {
    # disable undo emulation for games that supply the word "undo"
    Games::Rezrov::ZOptions::EMULATE_UNDO(0);
  }
  
  output_stream(Games::Rezrov::ZConst::STREAM_SCREEN());
  
  $current_window = Games::Rezrov::ZConst::LOWER_WIN;
  # HACKS, FIX ME
#  $zio->set_version($self);
  erase_window(-1);
  # collapses the upper window

  if ($version <= 3 and
      $zio->can_split() and
      !$zio->manual_status_line()) {
    # Centralized management of the status line.
    # Perform a split_window(), we'll use the "upper window" 
    # for the status line.
    # This is BROKEN: Seastalker is a v3 game that uses the upper window!
    split_window(1);
  }
  
  set_window(Games::Rezrov::ZConst::LOWER_WIN);

  if (0) {
    # debugging
    set_cursor(1,1);
    my $message = "line 1, column 1";
    write_zchunk(\$message);
    screen_zio()->update();
    sleep 10;
  }
}

sub AUTOLOAD {
  # probably an unimplemented opcode.
  # Send output to the ZIO to print it, as STDERR might not be "visible"
  # for some ZIO implementations
  fatal_error(sprintf 'unknown sub "%s": unimplemented opcode?', $Games::Rezrov::StoryFile::AUTOLOAD);
}

sub load {
  # completely (re-) load game data.  Resets all state info.
  my ($just_version) = @_;
  my $size = -s $game_filename;
  open(GAME, $game_filename) || die "can't open $game_filename: $!\n";
  binmode GAME;
  if ($just_version) {
    #
    # hack: just get the version of the game (first byte).
    #
    # We do this so we can initialize the I/O layer and put up
    # a "loading" message while we wait.  We need the version
    # to figure out whether to create a status line in the ZIO;
    # important for Tk version (visually annoying to create status
    # line later on)
    #
    my $buf;
    if (read(GAME, $buf, 1) == 1) {
      return unpack "C", $buf;
    } else {
      die "huh?";
    }
  } else {
    my $read = read(GAME, $Games::Rezrov::StoryFile::STORY_BYTES, $size);
    close GAME;
    die "read error" unless $read == $size;

    my $zio = screen_zio();
    $header = new Games::Rezrov::ZHeader($zio);
    $global_variable_address = $header->global_variable_address();

    $global_variable_word_addr = int($global_variable_address / 2);
    # is this always aligned on a word boundary???
    # NO!  Many games do not.  This won't work, but it would
    # have been nice to get words via a single vec() of size 16 rather than
    # two vecs() of size 8 and a shift!

    my $static = $header->static_memory_address();
    $dynamic_area = substr($Games::Rezrov::StoryFile::STORY_BYTES, 0, $static);
    #  vec($dynamic_area, 0x50, 8) = 12;
    
#    $self->header($header);
    
    $version = $header->version();
    $groks_f3 = $zio->groks_font_3();

#    $last_score = 0;
    # for "NOTIFY" emulation
    reset_cheats();
  }
}

sub get_byte_at {
  # return an 8-bit byte at specified storyfile offset.
#  die unless @_ == 2;
#  print STDERR "get_byte_at $_[1]\n" if $_[1] < 0x38;
#  print STDERR "gba\n";
  return vec($Games::Rezrov::StoryFile::STORY_BYTES, $_[0], 8);
}

sub save_area_byte {
  # return byte in "pristine" game image
  return vec($dynamic_area, $_[0], 8);
}

sub get_save_area {
  # return ref to "pristine" game image
  # Don't use this :)
  return \$dynamic_area;
}

sub get_story {
  # return ref to game data
  # Don't use this :)
  return \$Games::Rezrov::StoryFile::STORY_BYTES;
}

sub set_byte_at {
  # set an 8-bit byte at the specified storyfile offset to the
  # specified value.
#  print STDERR "sba\n";
  vec($Games::Rezrov::StoryFile::STORY_BYTES, $_[0], 8) = $_[1];
#  printf STDERR "  set_byte_at %s = %s\n", $_[1], $_[2];
}

sub get_word_at {
  # return unsigned 16-bit word at specified offset
#  die unless @_ == 2;
  
#  print STDERR "gwa\n";

#  return ((vec($Games::Rezrov::StoryFile::STORY_BYTES, $_[1], 8) << 8) + vec($Games::Rezrov::StoryFile::STORY_BYTES, $_[1] + 1, 8));
#  return unpack "n", substr($Games::Rezrov::StoryFile::STORY_BYTES, $_[1], 2);

  # using vec() and doing our bit-twiddling manually seems faster
  # than using unpack(), either with a substr...
  #
  #     $x = unpack "n", substr($Games::Rezrov::StoryFile::STORY_BYTES, $where, 2);
  #
  # or with using null bytes in the unpack...
  #
  #     $x = unpack "x$where n", $Games::Rezrov::StoryFile::STORY_BYTES
  #
  # Oh well...
  
#  print STDERR "get_word_at $_[1]\n" if $_[1] < 0x38;

  return ((vec($Games::Rezrov::StoryFile::STORY_BYTES, $_[0], 8) << 8) +
	  vec($Games::Rezrov::StoryFile::STORY_BYTES, $_[0] + 1, 8));
}

sub set_word_at {
  # set 16-bit word at specified index to specified value
#  die unless @_ == 3;
#  croak if ($_[1] == 30823);
#  print STDERR "swa\n";
  vec($Games::Rezrov::StoryFile::STORY_BYTES, $_[0], 8) = ($_[1] >> 8) & UNSIGNED_BYTE;
  vec($Games::Rezrov::StoryFile::STORY_BYTES, $_[0] + 1, 8) = $_[1] & UNSIGNED_BYTE;
  if ($_[0] == Games::Rezrov::ZHeader::FLAGS_2) {
    # activity in flags controlling printer transcripting.
    # Transcripting is set by the game and not by its own opcode.
    # see 7.3, 7.4
    my $str = $_[1] & Games::Rezrov::ZHeader::TRANSCRIPT_ON ? Games::Rezrov::ZConst::STREAM_TRANSCRIPT : - Games::Rezrov::ZConst::STREAM_TRANSCRIPT;
    # temp variable to prevent "modification of read-only value"
    # error when output_stream() tries to cast @_ to signed short

    output_stream($str);
    # use stream-style notification to tell the game about transcripting
  }
}

sub get_string_at {
  # return string of bytes at given offset
  return substr($Games::Rezrov::StoryFile::STORY_BYTES, $_[0], $_[1]);
}

sub reset_cheats {
  $zdict->bp_cheat_data(0) if $zdict;
  # reset "angiotensin" cheat (Bureaucracy)

  $last_score = get_global_var(GV_SCORE);
#  print STDERR "last_score: $last_score\n";
  # for NOTIFY emulation not to get confused after restore
  # FIX ME: block off to use only if cheat active and correct game version.
}

sub reset_game {
  # init/reset game state
  $Games::Rezrov::StoryFile::PC = 0;
  $call_stack = [];
  $lines_read = 0;

  reset_cheats();

  if ($header->version() == 6) {
    # 5.4: "main" routine
    call_proc($header->first_instruction_address());
  } else {
    # 5.5
    push_frame(FRAME_DUMMY);
    # create toplevel "dummy" frame: no parent, but can still
    # create local and stack variables.  Also consistent with
    # Quetzal savefile model
    $Games::Rezrov::StoryFile::PC = $header->first_instruction_address();
  }
  # FIX ME: we could pack the address and then do a standard call()...
    
  set_buffering(1);
  # 7.2.1: buffering is always on for v1-3, on by default for v4+.
  # We call this here so each implementation of ZIO doesn't have
  # to set the default.

  reset_write_count();
  clear_screen();
  set_window(Games::Rezrov::ZConst::LOWER_WIN());

  # FIX ME: reset zios() array here!
  # centralize all this with setup() stuff...
}

sub reset_storyfile {
  # FIX ME: everything in the header should be wiped but the
  # "printer transcript bit," etc.
  load();
  # hack
}

sub push_frame {
  # push a call frame onto stack
  my ($type) = @_;

  $current_frame = [];
  frame_call_type($type);
  frame_return_pc($Games::Rezrov::StoryFile::PC);
  $#$current_frame = FRAME_ROUTINE - 1;
  # expand frame so routine variables will start to be added at correct index
  push @{$call_stack}, $current_frame;
}

sub load_variable {
  # get the value of a variable and store it.
  # **indirect**
  store_result(get_variable($_[0], 1));
}

sub convert_packed_address {
  # unpack a packed address.  See spec 1.2.3
  if ($version >= 1 and $version <= 3) {
    return $_[0] * 2;
  } elsif ($version == 4 or $version == 5) {
    return $_[0] * 4;
  } elsif ($version == 6 or $version == 7) {
    my $offset = $_[1] == CALL ? $header->routines_offset() : $header->strings_offset();
    return ($_[0] * 4) + (8 * $offset);
    # 4P + 8R_O    Versions 6 and 7, for routine calls
    # 4P + 8S_O    Versions 6 and 7, for print_paddr
    # R_O and S_O are the routine and strings offsets (specified in the header as words at $28 and $2a, respectively). 
  } elsif ($version == 8) {
    return $_[0] * 8;
  } else {
    die "don't know how to unpack addr for version $version";
  }
}

sub ret {
  my ($value) = @_;
  # return from a subroutine
  my $call_type = pop_frame();

  if ($call_type == FRAME_FUNCTION) {
    store_result($value);
  } elsif ($call_type != FRAME_PROCEDURE) {
    die("unknown frame call type!");
  }
  return $value;
  # might be needed for an interrupt call (not yet implemented)
}


sub get_variable_MV {
  # $_[0]: variable
  # $_[1]: indirect stack reference mode
  # "my" vars version: prettier, but slower
  if ($_[0] == 0) {
    # section 4.2.2:
    # pop from top of routine stack
#    print STDERR "rp\n";
    if ($_[1]) {
      # indirect stack reference
      return $current_frame->[$#$current_frame];
    } else {
      return routine_pop();
    }
  } elsif ($_[0] <= 15) {
    # a local variable
#    print STDERR "lv\n";
    return $current_frame->[FRAME_LOCAL + $_[0] - 1];
    # numbered starting from 1, not 0
  } else {
    # a global variable
#    print STDERR "gv\n";
#    return get_global_var($_[1] - 16);
    # most readable, but slowest
#    return get_word_at($_[0]->global_variable_address() + (($_[1] - 16) * 2));
    # faster, less readable

    my $tmp = $global_variable_address + (($_[0] - 16) * 2);
    # - 16 = convert to index starting at 0
#    print STDERR "get gv $_[0]\n";
    return ((vec($Games::Rezrov::StoryFile::STORY_BYTES, $tmp, 8) << 8) +
	    vec($Games::Rezrov::StoryFile::STORY_BYTES, $tmp + 1, 8));
    # fastest, almost unreadable :(

    #
    # alternate approach:
    #   disgusting, but possibly faster?
    #   use a global, avoiding declaration/destruction of $tmp, above
    #

#    $GLOBAL_TMP = $global_variable_address + (($_[0] - 16) * 2);
#    return ((vec($Games::Rezrov::StoryFile::STORY_BYTES, $GLOBAL_TMP, 8) << 8) +
#	    vec($Games::Rezrov::StoryFile::STORY_BYTES, $GLOBAL_TMP + 1, 8));

  }
}

sub get_variable_GV {
  # $_[0]: variable
  # $_[1]: indirect stack reference mode
  # global variables version: hideous, but faster? (no "my" variable create/destroy)
  if ($_[0] == 0) {
    # section 4.2.2:
    # pop from top of routine stack
#    print STDERR "get_variable: routine\n";
    if ($_[1]) {
      # indirect stack reference
      return $current_frame->[$#$current_frame];
    } else {
      return routine_pop();
    }
  } elsif ($_[0] <= 15) {
    # a local variable
#    print STDERR "get_variable: local\n";
    return $current_frame->[FRAME_LOCAL + $_[0] - 1];
    # numbered starting from 1, not 0
  } else {
    # a global variable
#    print STDERR "get_variable: global\n";

    #
    #   disgusting, but possibly faster?
    #   use a global, avoiding declaration/destruction of $tmp:
    #

    $GLOBAL_TEMP_OFFSET = $global_variable_address + (($_[0] - 16) * 2);
    return ((vec($Games::Rezrov::StoryFile::STORY_BYTES, $GLOBAL_TEMP_OFFSET, 8) << 8) +
	    vec($Games::Rezrov::StoryFile::STORY_BYTES, $GLOBAL_TEMP_OFFSET + 1, 8));

  }
}

sub unsigned_word {
  # pack a signed value into an unsigned value.
  # Necessary to ensure the sign bit is placed at 0x8000.
  return unpack "S", pack "s", $_[0];
}

sub compare_je {
  # branch if first operand is equal to any of the others
  my $first = shift;
#  print STDERR "je\n";
  foreach (@_) {
    conditional_jump(1), return if $_ == $first;
  }
  conditional_jump(0);
}

sub store_word {
  my ($array_address, $word_index, $value) = @_;
  # set a word at a specified offset in a specified array offset.
  $array_address += (2 * $word_index);
  set_word_at($array_address, $value);
}

sub store_byte {
  my ($array_address, $byte_index, $value) = @_;
  set_byte_at($array_address + $byte_index, $value);
}

sub pop_frame {
  my $last_frame = pop @{$call_stack};
  my $call_type = $last_frame->[FRAME_CALL_TYPE];
#  print "pop: $call_type\n";
  $Games::Rezrov::StoryFile::PC = $last_frame->[FRAME_RPC];
  $current_frame = $call_stack->[$#$call_stack];
  # set frame to calling frame
  return $call_type;
}

sub get_word_index {
  # get a word from the specified index of the specified array
  my ($address, $index) = @_;
  store_result(get_word_at($address + (2 * $index)));
}

sub put_property {
  my ($object, $property, $value) = @_;
  my $zobj = get_zobject($object);
  my $zprop = $zobj->get_property($property);
  $zprop->set_value($value);
}

sub test_attr {
  # jump if some object has an attribute set
  my ($object, $attribute) = @_;
  my $zobj = get_zobject($object);
  conditional_jump($zobj and $zobj->test_attr($attribute));
  # watch out for object 0
}

sub set_attr {
  # turn on given attribute of given object
  my ($object, $attribute) = @_;
  if (my $zobj = get_zobject($object)) {
    # unless object 0
    $zobj->set_attr($attribute);
  }
}

sub clear_attr {
  # clear given attribute of given object
  my ($object, $attribute) = @_;
  if (my $zobj = get_zobject($object)) {
    # unless object 0
    $zobj->clear_attr($attribute);
  }
}

sub print_text {
  # decode a string at the PC and move PC past it
  my $blob;
  ($blob, $Games::Rezrov::StoryFile::PC) = $ztext->decode_text($Games::Rezrov::StoryFile::PC);
  write_zchunk($blob);
}


sub write_zchunk {
  my $chunk = $_[0];

#  print STDERR "Chunk: $$chunk\n";
  if ($selected_streams->[Games::Rezrov::ZConst::STREAM_REDIRECT]) {
    # 7.1.2.2: when active, no other streams get output
    my $stack = $zios->[Games::Rezrov::ZConst::STREAM_REDIRECT];
#    printf STDERR "redirected chunk: %s\n", $$chunk;
    $stack->[$#$stack]->buffer_zchunk($chunk);
  } else {
    #
    #  other streams
    #
    if ($selected_streams->[Games::Rezrov::ZConst::STREAM_SCREEN]) {
      #
      #  screen
      #
      if ($selected_streams->[Games::Rezrov::ZConst::STREAM_STEAL] and
	  $current_window == Games::Rezrov::ZConst::LOWER_WIN) {
	# temporarily steal lower window output
	$zios->[Games::Rezrov::ZConst::STREAM_STEAL]->buffer_zchunk($chunk);
      } else {
	my $zio = $zios->[Games::Rezrov::ZConst::STREAM_SCREEN];
	
	if ($buffering and $current_window != Games::Rezrov::ZConst::UPPER_WIN) {
	  $zio->buffer_zchunk($chunk);
	} else {
	  foreach (unpack("c*", $$chunk)) {
	    if ($_ == Games::Rezrov::ZConst::Z_NEWLINE) {
	      $prompt_buffer = "";
	      $zio->newline();
	    } else {
	      $zio->write_zchar($_);
	    }
	  }
	}
      }
    }

    if ($selected_streams->[Games::Rezrov::ZConst::STREAM_TRANSCRIPT] and
	$current_window == Games::Rezrov::ZConst::LOWER_WIN) {
      # 
      #  Game transcript
      #
      if (my $fh = $zios->[Games::Rezrov::ZConst::STREAM_TRANSCRIPT]) {
	my $c = $$chunk;
	my $nl = chr(Games::Rezrov::ZConst::Z_NEWLINE);
	$c =~ s/$nl/\n/g;
	print $fh $c;
      }
    }
  }
}
  
sub print_ret {
  # print string at PC, move past it, then return true
  print_text();
  newline();
  rtrue();
}

sub newline {
  write_zchar(Games::Rezrov::ZConst::Z_NEWLINE());
}

sub loadb {
  # get the byte at index "index" of array "array"
  my ($array, $index) = @_;
  store_result(get_byte_at($array + $index));
}

sub bitwise_and {
  # story bitwise "and" of the arguments.
  # FIX ME: signed???
  store_result($_[0] & $_[1]);
}

sub bitwise_or {
  # story bitwise "or" of the arguments.
  # FIX ME: signed???
  store_result($_[0] | $_[1]);
}

sub rtrue {
  # return TRUE from this subroutine.
  ret(1);
}

sub rfalse {
  # return FALSE from this subroutine.
  ret(0);
}

sub write_text {
  # write a given string to ZIO.
  write_zchunk(\$_[0]);
  newline() if $_[1];
#  foreach (unpack "C*", $_[1]) {
#    $_[0]->write_zchar($_);
#  }
}

sub insert_obj {
  my ($object, $destination_obj) = @_;
  # move object to become the first child of the destination
  # object. 
  #
  # object = O, destination_obj = D
  #
  # reorganize me: move to ZObject?
  
#  my $o = new Games::Rezrov::ZObject($object, $self);
  return unless $object;
  # if object being moved is ID 0, do nothing (bogus object)

  my $o = get_zobject($object);
#  my $d = new Games::Rezrov::ZObject($destination_obj, $self);
  my $d = get_zobject($destination_obj);

  if ($player_object) {
    # already know the object ID for the player
    $current_room = $destination_obj if $player_object == $object;
    if ($tailing) {
      # we're tailing an object...
      if ($tailing == $object) {
	newline();
	write_text(sprintf "Tailing %s: you are now in %s...", ${$o->print}, ${$d->print});
	newline();
	insert_obj($player_object, $destination_obj);
#        $self->suppress_hack();
#        $self->push_command("look");
      }
    }
  }

  unless ($player_confirmed) {
#  unless ($player_confirmed or $push_command) {
    # record object movements to determine which is the "player"
    # object, aka "cretin"  :)
    if ($object_cache->is_room($destination_obj)) {
      $candidate_po{$lines_read}{$object} = $destination_obj;
    }
  }

  if (Games::Rezrov::ZOptions::SNOOP_OBJECTS()) {
    my $o1 = $o->print($ztext);
    my $o2 = $d ? $d->print($ztext) : "(null)";
    write_text(sprintf '[Move "%s" to "%s"]', $$o1, $$o2);
    newline();
  }
  
  $o->remove();
  # unlink o from its parent and siblings
  
  $o->set_parent_id($destination_obj);
  # set new o's parent to d
  
  if ($d) {
    # look out for destination of object 0
    my $old_child_id = $d->get_child_id();
  
    $d->set_child_id($object);
    # set d's child ID to o
  
    if ($old_child_id > 0) {
      # d had children; make them the new siblings of o,
      # which is now d's child.
      $o->set_sibling_id($old_child_id);
    }
  }
  
}

sub pull {
  # pop a value from a stack and store in specified variable.
  # **indirect**
  if ($version == 6) {
    if ($_[0]) {
      fatal_error("v6: pull from user stack");
    } else {
      store_result(routine_pop());
      # broken? (indirect var?)
    }
  } else {
    set_variable($_[0], routine_pop(), 1);
    # set indirect stack reference mode
  }
}

sub jin {
  # jump if parent of obj1 is obj2
  # or if obj2 is 0 (null) and obj1 has no parent.
  my ($obj1, $obj2) = @_;
#  my $x = new Games::Rezrov::ZObject($obj1, $self);
  if ($obj1 == 0) {
    # no such object; consider its parent zero as well
    conditional_jump($obj2 == 0 ? 1 : 0);
  } else {
    my $x = get_zobject($obj1);
    my $jump = 0;
    if ($obj2 == 0) {
      $jump = ($x->get_parent_id() == 0 ? 1 : 0);
      write_text("[ jin(): untested! ]");
      newline();
    } else {
      $jump = $x->get_parent_id() == $obj2  ? 1 : 0;
    }
    conditional_jump($jump);
  }
}

sub print_object {
  # print short name of object (Z-encoded string in object property header)
  my $zobj = get_zobject($_[0]);
  my $highlight = Games::Rezrov::ZOptions::HIGHLIGHT_OBJECTS();
#  set_text_style(Games::Rezrov::ZConst::STYLE_BOLD) if $highlight;
  my $old;
  $old = swap_text_style(Games::Rezrov::ZConst::STYLE_BOLD) if $highlight;
  write_zchunk($zobj->print($ztext));
#  set_text_style(Games::Rezrov::ZConst::STYLE_ROMAN) if $highlight;
  toggle_text_style($old) if $highlight;

}

sub get_parent {
  # get parent object of this object and store result.
  # arg: object
  my $zobj = get_zobject($_[0]);
  store_result($zobj ? $zobj->get_parent_id() : 0);
  # if object ID 0, will be undef
}

sub get_child {
  # get child object ID for this object ID and store result, then
  # jump if it exists.
  #
  # arg: object
  my $zobj = get_zobject($_[0]);
  my $id = $zobj ? $zobj->get_child_id() : 0;
  # if object ID 0, will be undef
  store_result($id);
  conditional_jump($id != 0);
}

sub get_sibling {
  # get sibling object ID for this object ID and store result, then
  # jump if it exists.
  #
  # arg: object
  my $zobj = get_zobject($_[0]);
  my $id = $zobj ? $zobj->get_sibling_id() : 0;
  # if object ID 0, will be undef
  store_result($id);
  conditional_jump($id != 0);
}

sub get_property {
  # retrieve the specified property of the specified object.
  # args: $object, $property
  if (my $zobj = get_zobject($_[0])) {
    store_result($zobj->get_property($_[1])->get_value());
  } else {
    # object 0
    store_result(0);
  }
}

sub ret_popped {
  # return with a variable popped from the routine stack.
  ret(routine_pop());
}

sub stack_pop {
  # pop and discard topmost variable from the stack
  if ($version >= 5) {
    fatal_error("catch() unimplemented");
  } else {
    routine_pop();
  }
}

sub read_line {
  my ($argv, $interpreter, $start_pc) = @_;
  # Read and tokenize a command.
  # multi-arg approach taken from zip; this call has many
  # possible arguments.

  my $text_address = $argv->[0];
  my $token_address = $argv->[1] || 0;
  my $time = 0;
  my $routine = 0;
  $lines_read++;

  if (%candidate_po) {
    # we have possible candidates for the player object.
    # 
    # ZTUU: 1st move, 2 items moved to player, player moved to room
    # LGOP: "stool" and "it" (player) both moved to same room
    # SeaStalker: don't even get me started [FIX ME]...
    #
    # - checking for a toplevel child works
    my %seen;
    my %dest;
    my @turns = (sort {$a <=> $b} keys %candidate_po);
    # move through turns sequentially

    foreach my $turn (@turns) {
      while (my ($pid, $dest) = each %{$candidate_po{$turn}}) {
#	printf STDERR "Turn %d; %s => %s\n", $turn, $pid, $dest;
#	my $zs = new Games::Rezrov::ZObjectStatus($pid, $object_cache);
	#	printf "yow -- %s: \"%s\"\n", $pid, $zs->is_toplevel_child();
#	next unless $zs->is_toplevel_child();
	# this disambiguates the player in ZTUU, but doesn't work for
	# seastalker [toplevel child detection broken because of
	# wacky case in location names]
	$seen{$pid}++;
	$dest{$pid} = $dest;
	# the most recent destination
      }
    }

    if ($version <= 3) {
      my $current_room = get_global_var(0);
      # 8.2.2.1
      my @candidates = grep {$dest{$_} == $current_room} keys %dest;
      if (@candidates == 1) {
	# in version 3 games, the current room is stored in global
	# variable 0.  If only one object moved to that target, that's it.
	$player_object = $candidates[0];
	$player_confirmed = 1;
#	print STDERR "v3 confirmed: player is $player_object\n";
      }
    }

    unless ($player_confirmed) {
      my @ok = grep {$seen{$_} > 1} keys %seen;
      if (@ok == 1) {
	# exactly one object was observed moving multiple turns
	$player_object = $ok[0];
#	print STDERR "confirmed: player is $player_object \n";
	$player_confirmed = 1;
      } elsif (keys %seen == 1) {
	# in many games, the first object moved is the player.
	# Temporarily consider this the player until confirmation;
	# allows us to teleport even as the first move of the game.
	#
	# not true in: LGOP, ZTUU, etc...
	$player_object = (keys %seen)[0];
#	print STDERR "candidate po: $player_object \n";
      } else {
	#      printf STDERR "failed: %d (%s) %d (%s)\n", scalar keys %seen, (join ",", keys %seen), scalar @ok, join(",", @ok);
      }
    }

    %candidate_po = () if $player_confirmed;
      
    delete $candidate_po{shift @turns} if @turns > 3;
    # remove tracking for oldest turns

    $current_room = $dest{$player_object} if $player_object;
  }
  
  my $max_text_length = get_byte_at($text_address);
  $max_text_length++ if ($version <= 4);
  # sect15.html#sread
  
  if (@{$argv} > 2) {
    # timeout / routine specified
    $time = $argv->[2];
    $routine = $argv->[3];
  }

  $zdict->blood_pressure_cheat_hook();
  # hack
  
  flush();
  # flush any buffered output before the prompt.
  # Also very important before hijacking/restoring ZIO when guessing
  # the title.

  reset_write_count();

  my $bef_pc = $Games::Rezrov::StoryFile::PC;
  my $s = "";

  my $guess_title = Games::Rezrov::ZOptions::GUESS_TITLE();
  
  if (is_stream_selected(Games::Rezrov::ZConst::STREAM_STEAL)) {
    # suppressing parser output up until the next prompt
    my $old = $zios->[Games::Rezrov::ZConst::STREAM_STEAL];
    output_stream(- Games::Rezrov::ZConst::STREAM_STEAL);
    my $suppressed = $old->buffer();
#    print STDERR "steal active: $suppressed\n";
    if ($push_command) {
      $s = $push_command;
#      print STDERR "pushing: $s\n";
      $push_command = "";
    } else {
      if ($guessing_title) {
	$full_version_output = $suppressed;
	if ($suppressed =~ /\s*(.*?)[\x0a\x0d]/) {
	  $game_title = $1;
	  screen_zio()->set_game_title("rezrov: " . $1);
	}
      }
      my $regexp = '.*' . chr(Games::Rezrov::ZConst::Z_NEWLINE);
      # delete everything before the prompt (everything up to last newline)
      $suppressed =~ s/$regexp//o;
      $last_prompt = $suppressed;
      $prompt_buffer = $suppressed;
      # because flush() never sees the output this came from
      
      if ($guessing_title) {
	# prompt was printed "last time", don't print again
	$guessing_title = 0;
      } else {
	# print the prompt
	screen_zio()->write_string($suppressed);
      }
    }
  } elsif ($guess_title) {
    #
    # The axe crashes against the rock, throwing sparks!
    #
    if (!$game_title and $player_object) {
      # delay submitting the "version" command until an object has been
      # moved; this necessary for games that read a line before the real
      # parser starts.  Example: Leather Goddesses of Phobos.
      # Doesn't work: AMFV
      if ($zdict->get_dictionary_address("version")) {
	$guessing_title = 1;
	$s = "version";
	# submit a surreptitious "version" command to the interpreter
	suppress_hack();
	# temporarily hijack output
      } else {
	# game doesn't understand "version"; forget it.
	# example: Advent.z5
	$game_title = "not gonna happen";
	screen_zio()->set_game_title("rezrov");
      }
    }
  }

  my $undo_data;
  if (Games::Rezrov::ZOptions::EMULATE_UNDO()) {
    # save undo information
    my $tmp_pc = $Games::Rezrov::StoryFile::PC;
    $Games::Rezrov::StoryFile::PC = $start_pc;
    # fix me: move to quetzal itself
    $undo_data = $quetzal->save("", "-undo" => 1);
    $Games::Rezrov::StoryFile::PC = $tmp_pc;
  }

  unless (length $s) {
    if ($current_input_stream == Games::Rezrov::ZConst::INPUT_FILE) {
      #
      #  we're fetching commands from a script file.
      #
      $s = <$input_filehandle>;
      if (defined($s)) {
	# got a command; display it
	chomp $s;
	write_text($s || "");
	newline();
      } else {
	# end of file
	input_stream(Games::Rezrov::ZConst::INPUT_KEYBOARD);
	die "quitting!\n" if Games::Rezrov::ZOptions::PLAYBACK_DIE();
	$s = "";
      }
    }

    unless (length $s) {
      # 
      #  Get commands from the user
      #
      my $initial_buf;
      if ($version <= 3) {
	display_status_line();
      } elsif ($version >= 5) {
	# sect15.html#read
	# there may be some text already displayed as if we had typed it
	my $initial = get_byte_at($text_address + 1);
	$initial_buf = get_string_at($text_address + 2, $initial) if $initial;
      }

      my $sz = screen_zio();
      
      $s = $sz->get_input($max_text_length, 0,
			  "-time" => $time,
			  "-routine" => $routine,
			  "-zi" => $interpreter,
			  "-preloaded" => $initial_buf,
			 );

      if ($s and $sz->speaking and $s !~ /^\#speak/) {
	  $sz->speak($s, "-gender" => 2);
	  # say command unless we intend to turn off speech
      }
    }
  }
#  printf STDERR "cmd: $s\n";

  if (Games::Rezrov::ZOptions::CORRECT_TYPOS()) {
    my $msg;
    ($s, $msg) = $zdict->correct_typos($s);
    if ($msg) {
      write_text($msg);
      newline();
      unless ($TYPO_NOTIFY) {
	write_text("[NOTE: you can toggle typo correction on or off at any time with the #TYPO command.]");
	newline();
	$TYPO_NOTIFY=1;
      }
    }
  }

  if (Games::Rezrov::ZOptions::EMULATE_UNDO()) {
    if ($s eq "undo") {
      # want to undo; restore the old data
      if (@{$undo_slots}) {
	$quetzal->restore("", pop @{$undo_slots});
	write_text("Undone");
	if (@{$undo_slots}) {
	  write_text(sprintf " (%d more turn%s may be undone)", scalar @{$undo_slots}, (scalar @{$undo_slots} == 1 ? "" : "s"));
	}
	write_text(".");
	newline();
	newline();
	write_text($last_prompt || ">");
	# hack! 

	if ($player_object) {
	  # after we "undo" we might be in a different room; find
	  # the current one.  Important if we try to pilfer something:
	  # without this, it will go to the room before the undo!
	  $object_cache->load_names();
	  my $zstat = new Games::Rezrov::ZObjectStatus($player_object,
						       $object_cache);
	  if (my $parent = $zstat->parent_room()) {
	    $current_room = $parent->object_id();
	  }
	}

	return;
      } else {
	write_text("Can't undo now, sorry.");
	newline();
	newline();
	suppress_hack();
      }
    } else {
      # save this undo slot
      push @{$undo_slots}, $undo_data;
      while (@{$undo_slots} > Games::Rezrov::ZOptions::UNDO_SLOTS()) {
	# pop old ones
	shift @{$undo_slots};
      }
    }
  }

  die("PC corrupt after get_input; was:$bef_pc now:" . $Games::Rezrov::StoryFile::PC)
    if ($Games::Rezrov::StoryFile::PC != $bef_pc);
  # interrupt routine sanity check


  stream_dup(Games::Rezrov::ZConst::STREAM_TRANSCRIPT, $s);
  stream_dup(Games::Rezrov::ZConst::STREAM_COMMANDS, $s);

#  printf STDERR "input: %s\n", $s;
  $s = substr($s, 0, $max_text_length);
  # truncate input if necessary

  $zdict->save_buffer($s, $text_address);
  
  if ($version >= 5 && $token_address == 0) {
#    print STDERR "Skipping tokenization; test this!\n";
  } else {
    $zdict->tokenize_line($text_address,
			  $token_address,
			  "-len" => length($s),
			  );
  }

#  $zdict->last_buffer($s);
#  last_input = s;
  store_result(10) if ($version >= 5);
  # sect15.html#sread; store terminating char ("newline")

  $last_input = $s;
  # save last user input; used in "oops" emulation
}

sub read_char {
  my ($argv, $zi) = @_;
  # read a single character
  reset_write_count();
  flush();
#  die("read_char: 1st arg must be 1") if ($argv->[0] != 1);
  my $time = 0;
  my $routine = 0;
  if (@{$argv} > 1) {
    $time = $argv->[1];
    $routine = $argv->[2];
  }
  my $result = screen_zio()->get_input(1, 1,
					    "-time" => $time,
					    "-routine" => $routine,
					    "-zi" => $zi);
  my $code = ord(substr($result,0,1));
  $code = Games::Rezrov::ZConst::Z_NEWLINE if ($code == LINEFEED);
  # remap keyboard "linefeed" to what the Z-machine
  # will recognize as a "carriage return".  This is required
  # for the startup form in "Bureaucracy", and probably other
  # places.
  #
  # - does keyboard ever return 13 (non-IBM-clones)?
  # 
  # In spec terms:
  # - 10.7: only return characters defined in input stream
  # - 3.8: character "10" (linefeed) only defined for output.
  store_result($code);
  #  store ascii value
}


sub display_status_line {
  # only called if needed; see spec 8.2
  my $zio = screen_zio();
  return unless $zio->can_split();
  $zstatus->update();
  my $right_chunk;
  if ($zstatus->time_game()) {
    my $hours = $zstatus->hours();
    if (Games::Rezrov::ZOptions::TIME_24()) {
      $right_chunk = sprintf("Time: %d:%02d%s", $hours,
			     $zstatus->minutes());
    } else {
      $right_chunk = sprintf("Time: %d:%02d%s",
			     ($hours > 12 ? $hours - 12 : $hours),
			     $zstatus->minutes(),
			     ($hours < 12 ? "am" : "pm"));
    }
  } else {
    $right_chunk = sprintf "Score:%d  Moves:%d", $zstatus->score(), $zstatus->moves();
  }
  
  if ($zio->manual_status_line()) {
    # the ZIO wants to handle it
    $zio->status_hook($zstatus->location(), $right_chunk);
  } else {
    # "generic" status line handling; broken for screen-splitting v3 games
    my $restore = $zio->get_position(1);
    $zio->status_hook(0);
    $zio->write_string((" " x $columns), 0, 0);
    # erase
    $zio->write_string($zstatus->location(), 0, 0);
    
    $zio->write_string($right_chunk, $columns - length($right_chunk), 0);
    $zio->status_hook(1);
    &$restore();
  }
}

sub print_paddr {
  # print the string at the packed address given.
  # arg: address
  write_zchunk(scalar $ztext->decode_text(convert_packed_address($_[0], PRINT_PADDR)));
}

sub print_addr {
  # print the string at the address given; address is not packed
  # example: hollywood hijinx: "n", "knock"
  write_zchunk($ztext->decode_text($_[0]));
}

sub remove_object {
  # remove an object from its parent
  my ($object) = @_;
  if (my $zobj = get_zobject($object)) {
    # beware object 0
    $zobj->remove();
    if ($tailing) {
      if ($tailing == $zobj->object_id()) {
	write_text(sprintf "You can no longer tail %s.", ${$zobj->print});
      newline();
      $tailing = 0;
      }
    }
  }
}

sub get_property_addr {
  my ($object, $property) = @_;
  # store data address for given property of given object.
  # If property doesn't exist, store zero.
  if (my $zobj = get_zobject($object)) {
    my $zprop = $zobj->get_property($property);
    if ($zprop->property_exists()) {
      my $addr = $zprop->get_data_address();
#      printf STDERR "get_prop_addr for %s/%s=%s\n", $object, $property, $addr;
      store_result($addr);
    } else {
      store_result(0);
    }
  } else {
    # object 0
    store_result(0);
  }
}

sub test_flags {
  # jump if all flags in bitmap are set
  my ($bitmap, $flags) = @_;
  conditional_jump(($bitmap & $flags) == $flags);
}

sub get_next_property {
  my ($object, $property) = @_;
  # return property number of the next property provided by
  # the given object's given property.  With argument 0,
  # load property number of first property provided by that object.
  # example: zork 2 start, "get all"

  my $zobj = get_zobject($object);

  my $result = 0;
  if ($zobj) {
    # look out for object 0
    if ($property == 0) {
      # sect15.html#get_next_prop: 
      # if called with zero, it gives the first property number present.
      my $zp = $zobj->get_property(Games::Rezrov::ZProperty::FIRST_PROPERTY);
      $result = $zp->property_number();
    } else {
      my $zp = $zobj->get_property($property);
      if ($zp->property_exists()) {
	$result = $zp->get_next()->property_number();
      } else {
	die("attempt to get next after bogus property");
      }
    }
  }
  store_result($result);
}


sub scan_table {
  # args: search, table, len [form]
  # Is "search" one of the entries in "table", which is "num_entries" entries
  # long?  So return the address where it first occurs and branch.  If not,
  # return 0 and don't.  May be byte/word entries.
  my ($search, $table, $num_entries, $form) = @_;
  my ($entry_len, $check_len);
  if (defined $form) {
#    write_text("[custom form, check me!]");
#    newline();
    
    $entry_len = $form & 0x7f;
    # length of each entry in the table
    $check_len = ($form & 0x80) > 0 ? 2 : 1;
    # how many of the first bytes in each entry to check
  } else {
    $check_len = $entry_len = 2;
  }
  my ($addr, $value, $entry_count);
  my $found = 0;
  for ($addr = $table, $entry_count = 0;
       $entry_count < $num_entries;
       $entry_count++, $addr += $entry_len) {
    $value = ($check_len == 1) ?
      get_byte_at($addr) : get_word_at($addr);
    # yeah, yeah, it'd be more efficient to have a separate
    # loop, one for byte and one for word...
    $found = 1, last if ($value == $search);
  }
  
  store_result($found ? $addr : 0);
  conditional_jump($found);
}

sub set_window {
  my ($window) = @_;
#  print STDERR "set_window $window\n";
  flush();
  my $zio = screen_zio();

  $window_cursors->[$current_window] = $zio->get_position(1);
  # save callback to restore cursor position when we return to
  # this window
  
  $current_window = $window;
  # set current window

  if ($version >= 4) {
    if ($current_window == Games::Rezrov::ZConst::UPPER_WIN) {
      # 8.7.2: whenever upper window selected, cursor goes to top left
      set_cursor(1,1);
    } else {
      # restore old cursor position
      my $restore;
      if (defined $window_cursors->[$current_window]) {
	# restore former cursor position
	&{$window_cursors->[$current_window]};
      } else {
	# first switch to window
	$zio->absolute_move(0, $rows - 1);
	# 8.7.2.2: in v4 lower window cursor is always on last line.
      }
    }
  } else {
    # in v3, cursor always in lower left
    $zio->absolute_move(0, $rows - 1);
  }
  $zio->set_window($window);
  # for any local housekeeping
  $zio->set_text_style(font_mask());
  # since we always print in fixed font in the upper window,
  # make sure the zio gets a chance to turn this on/off as we enter/leave;
  # example: photopia.
}

sub set_cursor {
  my ($line, $column, $win) = @_;
  my $zio = screen_zio();
  $zio->fatal_error("set_cursor on window $win not supported") if $win;

  $line--;
  $column--;
  # given starting at 1, not 0
  
#  print STDERR "set_cursor\n";
  if ($current_window == Games::Rezrov::ZConst::UPPER_WIN) {
    # upper window: use offsets as specified
    $zio->absolute_move($column, $line);
  } else {
    # lower window: map coordinates given upper window size
    $zio->absolute_move($column, $line + $upper_lines);
  }
}


sub write_zchar {
  #
  # write a decoded z-char to selected output streams.
  #
  return if $_[0] == 0;
  # 3.8.2.1: "null" has no effect on any output stream

  if (($_[0] >= 179 and $_[0] <= 218) or
      ($_[0] >= 0x18 and $_[0] <= 0x1b)) {
    # sect16.html; convert IBM PC graphics codes
    my $trans = $Z_TRANSLATIONS{$_[0]} || "*";
#    print STDERR "trans for $_[0] => $trans\n";
    if (length $trans == 1) {
      $_[0] = ord($trans);
    } else {
      write_zchunk(\$trans);
      return;
    }
  }
  
  if ($selected_streams->[Games::Rezrov::ZConst::STREAM_REDIRECT]) {
    #
    # 7.1.2.2: when active, no other streams get output
    #
    my $stack = $zios->[Games::Rezrov::ZConst::STREAM_REDIRECT];
#    printf STDERR "redirected: %s (%d)\n", chr($_[0]), $_[0];
    $stack->[$#$stack]->write_zchar($_[0]);
  } else {
    #
    #  all the other streams
    #
    if ($selected_streams->[Games::Rezrov::ZConst::STREAM_SCREEN]) {
      #
      #  screen
      #
      if ($selected_streams->[Games::Rezrov::ZConst::STREAM_SCREEN]) {
	if ($selected_streams->[Games::Rezrov::ZConst::STREAM_STEAL] and
	    $current_window == Games::Rezrov::ZConst::LOWER_WIN) {
	  # temporarily steal lower window output
	  $zios->[Games::Rezrov::ZConst::STREAM_STEAL]->buffer_zchar($_[0]);
	} else {
	  my $zio = $zios->[Games::Rezrov::ZConst::STREAM_SCREEN];
	  
	  if ($buffering and $current_window != Games::Rezrov::ZConst::UPPER_WIN) {
	    # 8.7.2.5: buffering never active in upper window (v. 3-5)
	    if ($_[0] == Games::Rezrov::ZConst::Z_NEWLINE) {
	      flush();
	      $prompt_buffer = "";
	      $zio->newline();
	    } else {
	      $zio->buffer_zchar($_[0]);
	    }
	  } else {
	    # buffering off, or upper window
	    if ($_[0] == Games::Rezrov::ZConst::Z_NEWLINE) {
	      $prompt_buffer = "";
	      $zio->newline();
	    } else {
	      $zio->write_zchar($_[0]);
	    }
	  }
	}
      }
    }

    if ($selected_streams->[Games::Rezrov::ZConst::STREAM_TRANSCRIPT] and
	$current_window == Games::Rezrov::ZConst::LOWER_WIN) {
      # 
      #  Game transcript
      #
      my $fh = $zios->[Games::Rezrov::ZConst::STREAM_TRANSCRIPT];	
      print $fh (($_[0] || 0) == Games::Rezrov::ZConst::Z_NEWLINE) ? ($\ || "\n") : chr($_[0]);
    }
  }
}

sub screen_zio {
  # get the ZIO for the screen
  return $zios->[Games::Rezrov::ZConst::STREAM_SCREEN];
}

sub restore {
  # restore game
  my $filename = filename_prompt("-default" => $last_savefile || "",
				 "-ext" => "sav",
				);
  my $success = 0;
  if ($filename) {
    $last_savefile = $filename;
    $success = $quetzal->restore($filename);
    if (!$success and $quetzal->error_message()) {
      write_text($quetzal->error_message());
      newline();
    }
  }

  reset_cheats();

#  $last_score = get_global_var(GV_SCORE);
  # for NOTIFY emulation not to get confused after restore

  if ($version <= 3) {
    conditional_jump($success);
  } elsif ($version == 4) {
    # sect15.html#save
    store_result($success ? 2 : 0);
  } else {
    store_result($success);
  }
}

sub filename_prompt {
#  my ($self, $prompt, $exist_check, $snide) = @_;
  my (%options) = @_;
  
  my $ext = $options{"-ext"} || die;
  my $default;
  unless ($default = $options{"-default"}) {
    ($default = $game_filename) =~ s/\..*//;
    $default .= ".$ext";
  }

  my $zio = screen_zio();
  my $prompt = sprintf "Filename [%s]: ", $default;
  $zio->write_string(sprintf "Filename [%s]: ", $default);
  $prompt_buffer = $prompt;
#  write_text(sprintf "Filename [%s]: ", $default);
  my $filename = $zio->get_input(50, 0) || $default;
  if ($filename) {
    if ($options{"-check"} and -f $filename) {
      $zio->write_string($filename . " exists, overwrite? [y/n]: ");
      $zio->update();
      my $proceed = $zio->get_input(1, 1);
      if ($proceed =~ /y/i) {
	write_text("Yes.");
	unlink($filename);
      } else {
	write_text("No.");
	$filename = "";
      }
      newline();
    }
  }
  
  return $filename;
}

sub save {
  # save game
  my $filename = filename_prompt("-ext" => "sav",
				 "-check" => 1);
  my $success = 0;
  if ($filename) {
    $last_savefile = $filename;
#    $success = $q->save($filename, "-umem" => 1);
    $success = $quetzal->save($filename);
    if (!$success and $quetzal->error_message()) {
      write_text($quetzal->error_message());
      newline();
    }
  }

  if ($version <= 3) {
    conditional_jump($success);
  } else {
    # v4 +
    store_result($success);
  }
}

sub set_game_state {
  # called from Quetzal restore routines
  my ($stack, $pc) = @_;
  $call_stack = $stack;
  $current_frame = $stack->[$#$stack];
  $Games::Rezrov::StoryFile::PC = $pc;
}

sub snide_message {
  my @messages = ("Fine, be that way.",
		  "Eh? Speak up!",
		  "What?",
		 );
  return $messages[int(rand(scalar @messages))];
}

sub save_undo {
  # v5+, save to RAM
  # BROKEN
  if (0) {
    my $undo_data = $quetzal->save("", "-undo" => 1);
#    print "saved $undo_data\n";
    $undo_slots = [ $undo_data ];
    store_result(1);
  } else {
    # not supported
    store_result(-1);
  }
}

sub restore_undo {
  # v5+, restore from RAM
  # BROKEN
  if (0) {
#    print "restoring " . $undo_slots->[0] . "\n";
    my $status = @{$undo_slots} ? $quetzal->restore("", pop @{$undo_slots}) : 0;
    store_result($status);
  } else {
    store_result(0);
  }
}

sub check_arg_count {
  # sect15.html#check_arg_count
  # branch if the given argument number has been provided by the routine
  # call to the current routine
  conditional_jump(frame_argc() >= $_[0]);
}

sub DESTROY {
  # must be defined so our AUTOLOAD won't catch destructor and complain
  1;
}

sub suppress_hack {
  # used when we're pulling a fast one with the parser,
  # intercepting user input.  Suppress the game's output (usually
  # complaints about unknown vocabulary), restoring i/o and
  # printing the prompt (which is everything after the last
  # Games::Rezrov::ZConst::Z_NEWLINE) during the read_line() opcode.
#  cluck "suppress_hack\n";
  output_stream(Games::Rezrov::ZConst::STREAM_STEAL);
}

sub print_table {
  # print a "window" of text onscreen.  Given text and width,
  # decode characters, moving down a line every "width" characters
  # to the same column (x position) where the table started.
  #
  # example: "sherlock", start game and enter "knock"
  my ($text, $width, $height, $skip) = @_;
  $height = 1 unless defined $height;
  $skip = 0 unless defined $skip;
  my $zio = screen_zio();
  my ($i, $j);
  my ($x, $y) = $zio->get_position();

#  printf STDERR "print_table: %s w:%d h:%d sk:%d\n", get_string_at($text, $width * $height), $width, $height, $skip;

  flush();

  my $char;
  for (my $i=0; $i < $height; $i++) {
    for(my $j=0; $j < $width; $j++) {
#      printf STDERR "pt: %d (%s)\n", get_byte_at($text), chr(get_byte_at($text));
      $char = get_byte_at($text++);
#      if ($char == Games::Rezrov::ZConst::Z_NEWLINE) {
#	die "hey now";
#      }
      write_zchar($char);
    }
    flush();
    # flush buffered text before moving to next line
    if ($skip) {
      # optionally skip specified number of chars between lines
      untested();
      $text += $skip;
    }
    if ($height > 1) {
      $zio->absolute_move($x, ++$y);
      # fix me: what if this goes out of bounds of the current window?
    }
  }
}

sub set_font {
  flush();
  if ($_[0] == 3 and $font_3_disabled) {
    # game wants font 3 but user has disabled it.
    # Don't even inform the ZIO.
    store_result(0);
  } else {
    store_result(screen_zio()->set_font($_[0]));
  }
}

sub set_color {
  my ($fg, $bg, $win) = @_;
  die sprintf("v6; fix me! %s", join ",", @_) if defined $win;
  my $zio = screen_zio();
  flush();
  if ($zio->can_use_color()) {
    foreach ([ $fg, 'fg' ],
	     [ $bg, 'bg' ]) {
      my ($color_code, $method) = @{$_};
      if ($color_code == Games::Rezrov::ZConst::COLOR_CURRENT) {
	# nop?
	print STDERR "set color to current; huh?\n";
      } elsif ($color_code == Games::Rezrov::ZConst::COLOR_DEFAULT) {
	my $m2 = 'default_' . $method;
	$zio->$method($zio->$m2());
      } elsif (my $name = Games::Rezrov::ZConst::color_code_to_name($color_code)) {
	$zio->$method($name);
	#      printf STDERR "set %s to %s\n", $method, $name;
      } else {
	die "set_color(): eek, " . $color_code;
      }
    }
    $zio->color_change_notify();
  }
}
  
sub fatal_error {
  my $zio = screen_zio();
  $zio->newline();
  $zio->fatal_error($_[0]);
}

sub split_window {
  my ($lines) = @_;
  my $zio = screen_zio();

  $upper_lines = $lines;
  $lower_lines = $rows - $lines;
#  print STDERR "split_window to $lines, ll=$lower_lines ul=$upper_lines\n";

  my ($x, $y) = $zio->get_position();
  if ($y < $upper_lines) {
    # 8.7.2.2
    $zio->absolute_move($x, $upper_lines);
  }
  screen_zio()->split_window($lines);
  # any local housekeeping
}

sub play_sound_effect {
  # hmm, should we pass this through?
  screen_zio()->play_sound_effect(@_);
}

sub input_stream {
  my ($stream, $filename) = @_;
  # $filename is an extension (only used internally)
  $current_input_stream = $stream;
  if ($stream == Games::Rezrov::ZConst::INPUT_FILE) {
    my $fn = $filename || filename_prompt("-ext" => "cmd");
    # filename provided if playing back from command line
    my $ok = 0;
    if ($fn) {
      if ($fn =~ /^\*main:/) {
	# hack for test.pl
	$ok = 1;
	$input_filehandle = $fn;
      } elsif (open(TRANS_IN, $fn)) {
	$ok = 1;
	$input_filehandle = \*TRANS_IN;
	write_text("Playing back commands from $fn...") unless defined $filename;
	# if name provided, don't print this message
      } else {
	write_text("Can't open \"$fn\" for playback: $!");
      }
      newline();
    }
    $current_input_stream = Games::Rezrov::ZConst::INPUT_KEYBOARD unless $ok;
  } elsif ($stream eq Games::Rezrov::ZConst::INPUT_KEYBOARD) {
    close TRANS_IN;
  } else {
    die;
  }
}

sub set_buffering {
  # whether text buffering is active
#  printf STDERR "set_buffering: $_[0]\n";
  $buffering = $_[0] == 1;
}

# font_mask() or font_mask(newmask)
#   specifying newmask replaces the current font mask
# In either case, the returned mask is fudged a bit (for example, STYLE_FIXED is coerced if we're the upper window).

sub font_mask {
  $fm = $_[0] if defined $_[0];
  my $fm2 = $fm || 0;
  $fm2 |= Games::Rezrov::ZConst::STYLE_FIXED
    if $current_window == Games::Rezrov::ZConst::UPPER_WIN;
  # 8.7.2.4:
  # An interpreter should use a fixed-pitch font when printing on the
  # upper window.

  if (0 and $header and $header->fixed_font_forced()) {
    # 8.1: game forcing use of fixed-width font
    # DISABLED: something seems to be wrong here...
    # photopia (all v5 games?) turn on this bit after 1 move?
    $fm2 |= Games::Rezrov::ZConst::STYLE_FIXED;
  }

  return $fm2;
}

sub set_text_style {
  # sets the specified style bits on the font, *unless* the value
  # STYLE_ROMAN is specified in which case all style bits are cleared.
  my $text_style = $_[0];
  flush();
  my $mask = font_mask();
  if ($text_style == Games::Rezrov::ZConst::STYLE_ROMAN) {
    # turn off all
    $mask = 0;
  } else {
    $mask |= $text_style;
  }
  $mask = font_mask($mask);
  # might be modified for upper window
  
  screen_zio()->set_text_style($mask);
  return $mask;
}

sub toggle_text_style {
  # toggle the specified style bits on the font. Rather pointless for
  # STYLE_ROMAN.  Little more than XOR.
  my $text_style = $_[0];
  flush();
  set_text_style( font_mask( font_mask() ^ $text_style ) );
}

# 'swap' in the specified style bits.
# Returns the bits that were actually changed.
#
# The idea is to be able to do this:
# $tmp = swap_text_style( STYLE_FIXED );
# print_fixed_width_text();
# toggle_text_style($tmp);
#
# and not worry about whether or not the relevant style bit was already set
# (if it was, the bit will be 0 in the return and so the toggle won't undo it)
sub swap_text_style {
  my $old = font_mask();
  return $old ^ set_text_style(@_);  
}

sub register_newline {
  # called by the ZIO whenever a newline is printed.
  return unless ($wrote_something and
		 # don't count newlines that occur before any text; 
		 # example: start of "plundered hearts", after initial RETURN
		 defined($current_window) and
		 $lower_lines and
		 $current_window == Games::Rezrov::ZConst::LOWER_WIN);
  my $wrote = $lines_wrote + 1;

#  printf STDERR "rn: %d/%d\n", $wrote, $lower_lines;
  
  if ($wrote >= ($lower_lines - 1)) {
    # need to pause; show prompt.
#    print STDERR "pausing...\n";
    my $zio = screen_zio();
    my $restore = $zio->get_position(1);
    
    set_cursor($lower_lines, 1);
    my $more_prompt = "[MORE]";
#    my $old = font_mask();
#    set_text_style(Games::Rezrov::ZConst::STYLE_REVERSE);
    my $old = swap_text_style(Games::Rezrov::ZConst::STYLE_REVERSE);
    $zio->write_string($more_prompt);
#    set_text_style(Games::Rezrov::ZConst::STYLE_ROMAN);
#    font_mask($old);
    toggle_text_style($old);
    $zio->update();
    $zio->get_input(1,1);
    set_cursor($lower_lines, 1);
    $zio->clear_to_eol();

#    $zio->erase_line($lower_lines);
#    $zio->erase_line($lower_lines - 1);
    $wrote = 0;
    &$restore();
    # restore old position
  }
  $lines_wrote = $wrote;
}

sub flush {
  # flush and format the characters buffered by the ZIO
  return if $flushing;
  # can happen w/combinations of attributes and pausing
#  cluck "flush";
  my $len;
  my $zio = screen_zio();
  my $buffer = $zio->get_buffer();
#  printf STDERR "flush: buffer= ->%s<-\n", $buffer;
  $zio->reset_buffer();
  return unless length $buffer;
#  print "fs\n";
  $flushing = 1;
  $wrote_something = 1;

  my $speech_buffer = $buffer;
  # save unmodified version for speech interface

  if (Games::Rezrov::ZOptions::BEAUTIFY_LOCATIONS() and
      $version < 4 and
      likely_location(\$buffer)) {
    #    set_text_style(Games::Rezrov::ZConst::STYLE_BOLD);
    my $old = swap_text_style(Games::Rezrov::ZConst::STYLE_BOLD); 
    $zio->write_string($buffer);
    # FIX ME: this might wrap; eg Tk, "Zork III: The Dungeon Master"
    # set_text_style(Games::Rezrov::ZConst::STYLE_ROMAN);
    toggle_text_style($old);
  } elsif (length $buffer) {
    $wrote_something = 1;
    my ($i, $have_left);
    if ($current_window != Games::Rezrov::ZConst::LOWER_WIN) {
      # buffering in upper window: nonstandard hack in effect.
      # assume we know what we're doing :)
#      print STDERR "hack! \"$buffer\"\n";
      $zio->write_string($buffer);
    } elsif (!$zio->fixed_font_default()) {
      #
      #  Variable font; graphical wrapping
      #
      my ($x, $y) = $zio->get_pixel_position();
      my $total_width = ($zio->get_pixel_geometry())[0];
      my $pixels_left = $total_width - $x;
      my $plen;
      while ($len = length($buffer)) {
	$plen = $zio->string_width($buffer);
	if ($plen < $pixels_left) {
	  # it'll fit; we're done
#	  print STDERR "fits: $buffer\n";
	  $zio->write_string($buffer);
	  last;
	} else {
	  my $wrapped = 0;
	  my $i = int(length($buffer) * ($pixels_left / $plen));
#	  print STDERR "pl=$pixels_left, plen=$plen i=$i\n";
	  while (substr($buffer,$i,1) ne " ") {
	    # move ahead to a word boundary
#	    print STDERR "boundarizing\n";
	    last if ++$i >= $len;
	  }

	  while (1) {
	    $plen = $zio->string_width(substr($buffer,0,$i));
#	    printf STDERR "%s = %s\n", substr($buffer,0,$i), $plen;
	    if ($plen < $pixels_left) {
	      # it'll fit
	      $zio->write_string(substr($buffer,0,$i));
	      $zio->newline();
	      $buffer = substr($buffer, $i + 1);
	      $wrapped = 1;
	      last;
	    } else {
	      # retreat back a word
	      while (--$i >= 0 and substr($buffer,$i,1) ne " ") { }
	      last if ($i < 0);
	    }
	  }

	  $zio->newline() unless ($wrapped);
	  # if couldn't wrap at all on this line
	  $pixels_left = $total_width;
	}
      }
    } else {
      #
      # Fixed font; do line/column wrapping
      # 
      my ($x, $y) = $zio->get_position();
      $have_left = ($columns - $x);
      # Get start column position; we can't be sure we're starting at
      # column 0.  This is an issue when flush() is called when changing
      # attributes.  Example: "bureaucracy" intro paragraphs ("But
      # Happitec is going to be _much_ more fun...")
      while ($len = length($buffer)) {
	if ($len < $have_left) {
	  $zio->write_string($buffer);
	  last;
	} else {
#	  printf STDERR "wrapping: %d, %d, %s x:$x y:$y col:$columns\n", length $buffer, $have_left, $buffer;
	  my $wrapped = 0;
	  for ($i = $have_left - 1; $i > 0; $i--) {
	    if (substr($buffer, $i, 1) eq " ") {
	      $zio->write_string(substr($buffer, 0, $i));
	      $zio->newline();
	      $wrapped = 1;
	      $buffer = substr($buffer, $i + 1);
	      last;
	    }
	  }
	  $zio->newline() unless $wrapped;
	  # if couldn't wrap at all
	  $have_left = $columns;
	}
      }
    }
    $prompt_buffer = $buffer;
    # FIX ME
  }

  $zio->speak($speech_buffer) if $zio->speaking;
  
  $flushing = 0;
}
  
sub likely_location {
  #
  # STATIC: is the given string likely the name of a location?
  #
  # An earlier approach saved the buffer position before and after
  # StoryFile::object_print() opcode, and considered a string a
  # location if and only if the buffer was flushed with only an object
  # string in the buffer.  Unfortunately this doesn't always work:
  #
  #  Suspect: "Ballroom, Near Fireplace", where "Near Fireplace"
  #           is an object, but Ballroom is not.
  #
  #  It's not enough to check for all capitalized words:
  #    Zork 1: "West of House"
  #
  # This approach "uglier" but works more often :)
  my $ref = shift;
  my $len = length $$ref;
  if ($len and $len < 50) {
    # length?
    my $buffer = $$ref;

    return 0 unless $buffer =~ /^[A-Z]/;
    # must start uppercased

    return 0 if $buffer =~ /\W$/;
    # can't end with a non-alphanum:
    # minizork.z3:
    #   >i
    #   You have:   <---------
    #   A leaflet

    return 0 if $buffer =~ /^\w - /;
    # sampler1_r55.z3:
    # T - The Tutorial

    unless ($buffer =~ /[a-z]/) {
      # if all uppercase...
      return 0 if $buffer =~ /[^\w ]/;
      # ...be extra strict about non-alphanumeric characters
      #
      # allowed: ENCHANTER
      #          HOLLYWOOD HIJINX
      # but not:
      #          ROBOT, GO NORTH (sampler, Planetfall)
    }

    if ($buffer =~ /\s[a-z]+$/) {
      # Can't end with a lowercase word;
      # Enchanter: "Flathead portrait"
      return 0;
    }

    return 0 if $buffer =~ /\s[a-z]\S{2,}\s+[a-z]\S{2,}/;
    # don't allow more than one "significant" lowercase-starting
    # word in a row.
    #
    # example: graffiti in Planetfall's brig:
    #
    #  There once was a krip, name of Blather  <--
    #  Who told a young ensign named Smather   <-- this is not caught here!
    #  "I'll make you inherit
    #  A trotting demerit                      <--
    #  And ship you off to those stinking fawg-infested tar-pools of Krather".
    #
    # However, we must allow:
    #
    #  Land of the Dead  [Zork I]
    #  Room in a Puzzle  [Zork III]

    if ($buffer =~ /\s([a-z]\S*\s+){3,}/) {
      # in any case, don't allow 3 lowercase-starting words in a row.
      # back to the brig example:
      #
      #  Who told a young ensign named Smather   <-- we get this here
      #      ^^^^^^^^^^^^^^^^^^^^^^^^^
      return 0;
    }
    # ( blech... )

    return $buffer =~ /[^\w\s,:\'\-]/ ? 0 : 1;
    # - commas allowed: Cutthroats, "Your Room, on the bed"
    # - dashes allowed: Zork I, "North-South Passage"
    # - apostrophes allowed: Zork II, "Dragon's Lair"
    # - colons allowed (for game titles): "Zork III: ..."
    # - otherwise, everything except whitespace and alphanums verboten.
  } else {
    return 0;
  }
}

sub tokenize {
  my ($text, $parse, $dict, $flag) = @_;

  my $std_dictionary_addr = $header->dictionary_address();
  my $zd;
  if ($dict and $dict != $std_dictionary_addr) {
    # v5+; example: "beyond zork"
    unless ($zd = $alternate_dictionaries{$dict}) {
      $zd = $alternate_dictionaries{$dict} = new Games::Rezrov::ZDict($dict);
    }
  } else {
    # use default/standard dictionary
    $zd = $zdict;
  }

  $zd->tokenize_line($text,
		     $parse,
		     "-flag" => $flag,
		     );
#  die join ",", @_;
}

sub get_zobject {
  # cache object requests; games seem to run about 5-10% faster,
  # the most gain seen in earlier games
  return $object_cache->get($_[0]);

  # create every time; slow overhead
#  return new Games::Rezrov::ZObject($_[0]);
}

sub get_zobject_cache {
    # you don't see this
    return $object_cache;
}

sub rows {
  if (defined $_[0]) {
    $rows = $_[0];
    $header->set_rows($rows) if $header;
    reset_write_count();
    $lower_lines = $rows - $upper_lines if defined $upper_lines;
  }
  return $rows;
}

sub columns {
  if (defined $_[0]) {
    # ZIO notifies us of its columns
    $columns = $_[0];
    $header->set_columns($_[0]) if $header;
    display_status_line() if $version <= 3 and $zstatus;
  }
  return $columns;
}

sub reset_write_count {
  $lines_wrote = 0;
  $wrote_something = 0;
}

sub get_pc {
  return $Games::Rezrov::StoryFile::PC;
}

sub clear_screen {
  my $zio = screen_zio();
  
  if ($zio->can_use_color()) {
    my $fg = $zio->fg() || "";
    my $bg = $zio->bg() || "";
    my $dbg = $zio->default_bg() || "";
    # FIX ME!
    
    #  printf STDERR "fg=%s/%s bg=%s/%s\n",$fg,$zio->default_fg, $bg, $zio->default_bg;
    if ($bg ne $dbg) {
      # the background color has changed; change the cursor color
      # to the current foreground color so we don't run the risk of it 
      # "disappearing".
      $zio->cc($fg);
    }
    $zio->default_bg($bg);
    $zio->default_fg($fg);
    $zio->set_background_color();
  }

  $zio->clear_screen();
}

sub is_stream_selected {
  return $selected_streams->[$_[0]];
}

sub stream_dup {
  my ($stream, $string) = @_;
  if (is_stream_selected($stream)) {
    my $fh = $zios->[$stream];
    print $fh $string . $/;
  }
}

sub is_this_game {
  # do the given release number, serial number, and checksum
  # match those of this game?
  my ($release, $serial, $checksum) = @_;
#  printf "%s\n%s\n", join(",", @_), join ",", $header->release_number, $header->serial_code, $header->file_checksum;
  return ($header->release_number() eq $release and
	  $header->serial_code() == $serial and
	  $header->file_checksum() == $checksum);
}

sub get_global_var {
  # get the specified global variable
#  printf STDERR "get gv %d: %d\n", $_[0], get_word_at($global_variable_address + ($_[0] * 2));
  return get_word_at($global_variable_address + ($_[0] * 2));
}

sub routine_pop {
  # pop a variable from the routine stack.
  if ($#$current_frame < FRAME_ROUTINE) {
    die "yikes: attempt to pop when no routine stack!\n";
  } else {
    return pop @{$current_frame};
  }
}

sub routine_push {
  # push a variable onto the routine stack
  push @{$current_frame}, $_[0];
}

sub frame_argc {
  $current_frame->[FRAME_ARGC] = $_[0] if defined $_[0];
  return $current_frame->[FRAME_ARGC];
}

sub frame_call_type {
  $current_frame->[FRAME_CALL_TYPE] = $_[0] if defined $_[0];
  return $current_frame->[FRAME_CALL_TYPE];
}

sub frame_return_pc {
  $current_frame->[FRAME_RPC] = $_[0] if defined $_[0];
  return $current_frame->[FRAME_RPC];
}

sub header {
  return $header;
}

sub version {
  return $version;
}

sub game_title {
  return $game_title;
}

sub ztext {
  return $ztext;
}

sub prompt_buffer {
  $prompt_buffer = $_[0] if defined $_[0];
  return $prompt_buffer;
}

sub call_stack {
  # used by Quetzal
  return $call_stack;
}

sub player_object {
  $player_object = $_[0] if defined $_[0];
  return $player_object;
}

sub current_room {
  $current_room = $_[0] if defined $_[0];
  return $current_room;
}

sub push_command {
  # steal a turn from the player
  $push_command = shift;
}

sub last_input {
  # for "oops" emulation
  return $last_input;
}

sub full_version_output {
  # used by "help"
  return $full_version_output;
}

sub tail {
  $tailing = $_[0];
}

sub call_func {
  # call, "function" style (store result)
  call(\@_, FRAME_FUNCTION);
}

sub call_proc {
  # call, "procedure" style (discard result)
  call(\@_, FRAME_PROCEDURE);
}

sub throw {
  unimplemented();
}

sub erase_line {
  untested();
  if ($_[0] == 1) {
    # if value not 1, do nothing
    screen_zio()->clear_to_eol();
  }
}

sub get_cursor {
  # put cursor coordinates at given offset
  untested();
  my ($x, $y) = screen_zio()->get_position();
  set_word_at($_[0], $y);
  set_word_at($_[1], $x);
}

sub untested {
  (my $subname = (caller(1))[3]) =~ s/.*://;
  printf STDERR "Untested opcode %s(); please email me if you see this!\n", $subname;
}

sub unimplemented {
  (my $subname = (caller(1))[3]) =~ s/.*://;
  fatal_error(sprintf 'opcode %s() unimplemented!  Please email me.', $subname);
}


sub encode_text {
  # blech
  unimplemented();
}

sub nop {
  untested();
}

sub piracy {
    # sect15.html#piracy
    conditional_jump(1);
}

sub not_or_possibly_call {
  # :)
  # sect15.html#not
  if ($version < 5) {
    z_not(@_);
  } else {
    call_proc(@_);
  }
}

sub font_3_disabled {
  $font_3_disabled = $_[0] if defined($_[0]);
  return $font_3_disabled;
}

sub get_zdict {
    return $zdict;
}

1;
