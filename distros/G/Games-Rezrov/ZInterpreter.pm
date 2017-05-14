package Games::Rezrov::ZInterpreter;
# interpret z-code

use strict;
no strict "refs";
# maybe a little faster here than during opcode call?

use Games::Rezrov::Inliner;

use constant OP_UNKNOWN => -1;
use constant OP_0OP => 0;
use constant OP_1OP => 1;
use constant OP_2OP => 2;
use constant OP_VAR => 3;
use constant OP_EXT => 4;

use constant CALL_VN2 => 0x1a;
use constant CALL_VS2 => 0x0c;
# var opcodes

my $INTERPRETER_GENERATED = 0;

sub new {
  my ($type, $zio) = @_;
  my $self = {};
  bless $self, $type;

  generate_interpreter_code();
  # delay code generation until now so we can add optional code
  # (or not include it) based on runtime options

  $self->zio($zio);

  if (my $where = Games::Rezrov::ZOptions::WRITE_OPCODES()) {
    if ($where eq "STDERR") {
      *Games::Rezrov::ZInterpreter::LOG = \*main::STDERR;
    } else {
      die "Can't write to $where: $!\n"
	unless open(LOG, ">$where");
    }
    my $old = select();
    select LOG;
    $|=1;
    select $old;
  }

  $self->restart(1);
  $self->interpret();
  return $self;
}

sub generate_interpreter_code {
  unless ($INTERPRETER_GENERATED) {
    # Generate code for main interpreter routine.
    # add optional chunks of code only if they're being used, to
    # make the loops as tight as possible.  Good for a small
    # speed improvement.

    local $/ = undef;    
    my $inline_code = <DATA>;

    my $CODE;

    if (Games::Rezrov::ZOptions::WRITE_OPCODES()) {
      $CODE = '
      printf LOG "count:%d style:%d pc:%d type:%s opcode:%d(0x%02x;raw=%d) (%s) operands:%s\n",
      $opcode_count,
      $op_style,
      $start_pc,
      $TYPE_LABELS[$op_style],
      $opcode,
      $opcode,
      $orig_opcode,
      ($generic_opcodes[$op_style]->[$opcode] ||
       $manual_descs[$op_style]->[$opcode] || "???"),
      join(",", @operands);
';

     $inline_code =~ s/#WRITE_OPCODES_STUB/$CODE/ || die;
    }

    if (Games::Rezrov::ZOptions::COUNT_OPCODES()) {
      $CODE='
$op_counts[$op_style]++;
';
     $inline_code =~ s/#COUNT_OPCODES_STUB/$CODE/ || die;
    }

    Games::Rezrov::Inliner::inline(\$inline_code);

#    print $inline_code;die;

    eval $inline_code;

    $INTERPRETER_GENERATED = 1;
  }
}

sub zio {
  return (defined $_[1] ? $_[0]->{"zio"} = $_[1] : $_[0]->{"zio"});
}

sub restart {
  my ($self, $first_time) = @_;
  Games::Rezrov::StoryFile::reset_storyfile() unless $first_time;
  Games::Rezrov::StoryFile::reset_game();
}

1;

#
#  code to be inlined starts here:
#
__DATA__

my @TYPE_LABELS;
$TYPE_LABELS[OP_0OP] = "0OP";
$TYPE_LABELS[OP_1OP] = "1OP";
$TYPE_LABELS[OP_2OP] = "2OP";
$TYPE_LABELS[OP_VAR] = "VAR";
$TYPE_LABELS[OP_EXT] = "EXT";

#
# lists of opcodes that can be handled generically.  Rather than
# writing a massive & repetitive if/elsif/else, we store the
# straightforward opcodes here, indexed by opcode number; "use data
# instead of code".  There seems to be virtually no difference
# difference in speed using this approach vs if/elsif/else
# (according to DProf).
#
# Still, my kingdom for a switch statement  :P
#
# Of course, if we were *really* interested in speed we'd take the
# "obfuscated opcode" approach that zip 2.0 uses...
#

my (@ext_ops, @generic_opcodes, @manual_descs);

my @zero_ops;
$zero_ops[0x00] = "rtrue";
$zero_ops[0x01] = "rfalse";
$zero_ops[0x02] = "print_text";
$zero_ops[0x03] = "print_ret";
$zero_ops[0x04] = "nop";
$zero_ops[0x05] = "save";
$zero_ops[0x06] = "restore";
# 0x07 handled manually (restart)
$zero_ops[0x08] = "ret_popped";
$zero_ops[0x09] = "stack_pop";
# 0x0a handled manually (quit)
$zero_ops[0x0b] = "newline";
$zero_ops[0x0c] = "display_status_line";
$zero_ops[0x0d] = "zo_verify";
# 0x0e = first byte of extended opcode
$zero_ops[0x0f] = "piracy";

my @one_ops;
$one_ops[0x00] = "compare_jz";
$one_ops[0x01] = "get_sibling";
$one_ops[0x02] = "get_child";
$one_ops[0x03] = "get_parent";
$one_ops[0x04] = "get_property_length";
$one_ops[0x05] = "increment";
$one_ops[0x06] = "decrement";
$one_ops[0x07] = "print_addr";
$one_ops[0x08] = "call_func";
$one_ops[0x09] = "remove_object";
$one_ops[0x0a] = "print_object";
# 0x0b handled manually; ret(), possibly async
$manual_descs[OP_1OP]->[0x0b] = "ret";
$one_ops[0x0c] = "jump";
$one_ops[0x0d] = "print_paddr";
$one_ops[0x0e] = "load_variable";
$one_ops[0x0f] = "not_or_possibly_call";

my @two_ops;
$two_ops[0x01] = "compare_je";
$two_ops[0x02] = "compare_jl";
$two_ops[0x03] = "compare_jg";
$two_ops[0x04] = "dec_jl";
$two_ops[0x05] = "inc_jg";
$two_ops[0x06] = "jin";
$two_ops[0x07] = "test_flags";
$two_ops[0x08] = "bitwise_or";
$two_ops[0x09] = "bitwise_and";
$two_ops[0x0a] = "test_attr";
$two_ops[0x0b] = "set_attr";
$two_ops[0x0c] = "clear_attr";
#$two_ops[0x0d] = "set_variable";
$two_ops[0x0d] = "z_store";
$two_ops[0x0e] = "insert_obj";
$two_ops[0x0f] = "get_word_index";
$two_ops[0x10] = "loadb";
$two_ops[0x11] = "get_property";
$two_ops[0x12] = "get_property_addr";
$two_ops[0x13] = "get_next_property";
$two_ops[0x14] = "add";
$two_ops[0x15] = "subtract";
$two_ops[0x16] = "multiply";
$two_ops[0x17] = "divide";
$two_ops[0x18] = "mod";
$two_ops[0x19] = "call_func";
$two_ops[0x1a] = "call_proc";
$two_ops[0x1b] = "set_color";
$two_ops[0x1c] = "throw";

my @var_ops;
$var_ops[0x00] = "call_func";
$var_ops[0x01] = "store_word";
$var_ops[0x02] = "store_byte";
$var_ops[0x03] = "put_property";
# 0x04 handled manually (read_line)
$manual_descs[OP_VAR]->[0x04] = "read_line";
$var_ops[0x05] = "write_zchar";
$var_ops[0x06] = "print_num";
$var_ops[0x07] = "random";
$var_ops[0x08] = "routine_push";
$var_ops[0x09] = "pull";
$var_ops[0x0a] = "split_window";
$var_ops[0x0b] = "set_window";
$var_ops[CALL_VS2] = "call_func";  # 0x0c
$var_ops[0x0d] = "erase_window";
$var_ops[0x0e] = "erase_line";
$var_ops[0x0f] = "set_cursor";
$var_ops[0x10] = "get_cursor";
$var_ops[0x11] = "set_text_style";
$var_ops[0x12] = "set_buffering";
$var_ops[0x13] = "output_stream";
$var_ops[0x14] = "input_stream";  # example: minizork.z3, "#comm"
$var_ops[0x15] = "play_sound_effect";
# 0x16 handled manually (read_char)
$manual_descs[OP_VAR]->[0x16] = "read_char";
$var_ops[0x17] = "scan_table";
$var_ops[0x18] = "z_not";
$var_ops[0x19] = "call_proc";
$var_ops[CALL_VN2] = "call_proc";  # 0x1a
$var_ops[0x1b] = "tokenize";
$var_ops[0x1c] = "encode_text";
$var_ops[0x1d] = "copy_table";
$var_ops[0x1e] = "print_table";
$var_ops[0x1f] = "check_arg_count";

$ext_ops[0x00] = "save";
$ext_ops[0x01] = "restore";
$ext_ops[0x02] = "log_shift";
$ext_ops[0x03] = "art_shift";
$ext_ops[0x04] = "set_font";
$ext_ops[0x09] = "save_undo";
$ext_ops[0x0a] = "restore_undo";

$generic_opcodes[OP_0OP] = \@zero_ops;
$generic_opcodes[OP_1OP] = \@one_ops;
$generic_opcodes[OP_2OP] = \@two_ops;
$generic_opcodes[OP_VAR] = \@var_ops;
$generic_opcodes[OP_EXT] = \@ext_ops;

*Games::Rezrov::ZInterpreter::interpret = sub {
  #
  # Your sword is glowing with a faint blue glow.
  #
  # >
  #
  my $self = shift;
  my $zio = $self->zio();
  my $z_version = Games::Rezrov::StoryFile::version();
  my ($start_pc, $opcode, $opcode_count);
  my ($op_style, $operand_types, $optype, $i);
  my @operands;
  my @op_counts;
  my $oc;
  my $input_counts = 0;
  my $count_opcodes = Games::Rezrov::ZOptions::COUNT_OPCODES();
  my $thing;

  my $var_ops = 0;
  my $orig_opcode;
  while (1) {
    $start_pc = $Games::Rezrov::StoryFile::PC;
    # for "undo" emulation: the PC before any processing has occurred
    $orig_opcode = $opcode = GET_BYTE();
    $op_style = OP_UNKNOWN;
    $opcode_count++;
    @operands = ();
    if (($opcode & 0x80) == 0) {
      #
      #
      # top bit is zero: opcode is "long" or "2OP" format.
      # Handle these first as they seem to be the most common.
      #
      #
      # spec 4.4.2:
      # most readable but slowest:
#      @operands = ($story->load_operand(($opcode & 0x40) == 0 ? 1 : 2),
#		   $story->load_operand(($opcode & 0x20) == 0 ? 1 : 2));
      
      # faster:
#      @operands = (($opcode & 0x40) == 0 ?
#		   GET_BYTE() : Games::Rezrov::StoryFile::get_variable(GET_BYTE()),
#		   ($opcode & 0x20) == 0 ?
#		   GET_BYTE() : Games::Rezrov::StoryFile::get_variable(GET_BYTE()));
      # faster yet:
      @operands = ();
      $thing = GET_BYTE();
      $operands[0] = ($opcode & 0x40) == 0 ?
	$thing : Games::Rezrov::StoryFile::get_variable($thing);

      $thing = GET_BYTE();
      $operands[1] = ($opcode & 0x20) == 0 ?
	$thing : Games::Rezrov::StoryFile::get_variable($thing);
      
      $opcode &= 0x1f; # last 5 bits
      $op_style = OP_2OP;
    } elsif ($opcode & 0x40) {
      # top 2 bits are both 1: "variable" format opcode.
      # This may actually be a 2OP opcode...
      $op_style = ($opcode & 0x20) == 0 ? OP_2OP : OP_VAR;
      # spec 4.3.3
      $opcode &= 0x1f;
      # Spec section 4.3.3 says operand is in bottom five bits.
      # However, "zip" code uses bottom six bits (0x3f).  This folding
      # together of the 2OP (bit 6 = 0) and VAR (bit 6 = 1) opcode
      # types makes for a more efficient single "switch" statement,
      # but makes it more difficult to match up the code with
      # The Specification.
      $var_ops = 1;
      # load operands later
    } else {
      #
      # highest bit is one, 2nd-highest is zero...
      #
      if ($opcode == 0xbe && $z_version >= 5) {
	# "extended" opcode
	$opcode = GET_BYTE();
	$op_style = OP_EXT;
	$var_ops = 1;
	# load operands below
      } elsif (($opcode & 0x30) == 0x30) {
	# "short" format opcode:
	# bits 4 and 5 are set; "0OP" opcode.
	$op_style = OP_0OP;
	$opcode &= 0x0f;
      } else {
	# "short" format opcode:
	# bits 4 and 5 are NOT set; "1OP" opcode.
	$op_style = OP_1OP;
	# push @operands, $story->load_operand((($opcode & 0x30) >> 4));
	$optype = ($opcode & 0x30) >> 4;
	# 4.2:
	if ($optype > 0) {
	  $thing = GET_BYTE();
	  push @operands, $optype == 1 ? $thing :
	    Games::Rezrov::StoryFile::get_variable($thing);
	} else {
	  push @operands, GET_WORD();
	}
	$opcode &= 0x0f;
      }
    }

    if ($var_ops) {
      # a VAR or EXT opcode with variable argument count.
      # Load the arguments.
      if ($op_style == OP_VAR &&
	  ($opcode == CALL_VS2 || $opcode == CALL_VN2)) {
	# 4.4.3.1: there may be two bytes of operand types, allowing
	# for up to 8 arguments.  This byte will always be present,
	# though it does NOT have to be used...
	$i = 14;
	# start shift mask: target "leftmost" 2 bits
	$operand_types = GET_WORD();
      } else {
	# 4.4.3: one byte of operand types, up to 4 args.
	$i = 6;
	$operand_types = GET_BYTE();
      }
#      printf STDERR "%s: ", $operand_types;
      for (; $i >=0; $i -= 2) {
	# sadly, it's slower to pack() the optypes and extract the
	# elements with vec($operand_types, $x, 2) than to bit-twiddle.
	$optype = ($operand_types >> $i) & 0x03;
#	print STDERR "$optype\n";
#	push @operands, $story->load_operand($optype);
	last if $optype == 0x03;
	if ($optype > 0) {
	  # 1 = literal byte
	  # 2 = variable of that byte
	  $thing = GET_BYTE();
	  push @operands, $optype == 1 ? $thing :
	    Games::Rezrov::StoryFile::get_variable($thing);
	} else {
	  # 0 = word
	  push @operands, GET_WORD();
	}
      }
#      print STDERR "\n";
      $var_ops = 0;
    }

    #
    #  Finally, interpret the opcodes based on type.
    #  This is a separate if/then/else from above code because the
    #  VAR opcode type can actually become a 2OP type (spec 4.3.3).
    #  This allows us to share the operand calls without duplicating
    #  code or (further) convoluting the structure of this routine.
    #

#WRITE_OPCODES_STUB

#COUNT_OPCODES_STUB

    #
    # Opcode types in order of frequency based on a completely 
    # unscientific test of Zorks 1-3 seem to be:
    #    2OP, 1OP, VAR, 0OP
    #
    if ($oc = $generic_opcodes[$op_style]->[$opcode]) {
      #
      #  Process opcodes 0/1/2/var/ext (old version):  5.43 secs
      #  Add processing opcodes by likely frequency:   4.51 secs
      #  Add intercepting generic opcodes first:       3.75 secs
      #
      #  (about 30% faster)
      #
#      die unless @operands == $op_style;
#      $story->$oc(@operands);
#      no strict "refs";
      &{"Games::Rezrov::StoryFile::$oc"}(@operands);
      # @operands contains the correct number of operands; just pass them

      # This is hideous.
      # Might it run faster if subs were exported?
    } elsif ($op_style == OP_1OP) {
      #
      # one operand opcodes
      #
      if ($opcode == 0x0b) {
	my $result = Games::Rezrov::StoryFile::ret($operands[0]);
#	if ($story->is_interrupt_top()) {
#	  # end of interrupt routine
#	  $story->set_interrupt_top(0);
#	  return $result;
#	}
	# async interpreter call (v4+), not implemented
      } else {
	$self->zi_die($op_style, $opcode, $opcode_count);
      }
    } elsif ($op_style == OP_VAR) {
      #
      #  variable-format opcodes
      #
      if ($opcode == 0x04) {
	Games::Rezrov::StoryFile::read_line(\@operands, $self, $start_pc);
	if ($count_opcodes and
	    (++$input_counts > (Games::Rezrov::ZOptions::GUESS_TITLE() ? 1 : 0))) {
	  my $count = 0;
	  my $desc = "";
	  foreach my $key (OP_0OP, OP_1OP, OP_2OP, OP_VAR, OP_EXT) {
	    my $oc = $op_counts[$key] || 0;
	    $count += $oc;
	    $desc .= sprintf " %s:%d", $TYPE_LABELS[$key], $oc;
	  }
	  Games::Rezrov::StoryFile::write_text(sprintf "[%d opcodes:%s]\n", $count, $desc);
	  @op_counts = ();
	}
      } elsif ($opcode == 0x16) {
	Games::Rezrov::StoryFile::read_char(\@operands, $self);
       } else {
	$self->zi_die($op_style, $opcode, $opcode_count);
      }
    } elsif ($op_style == OP_0OP) {
      #
      #  zero-operand opcodes
      #
      if ($opcode == 0x07) {
	# restart game
	$self->restart(0);
      } elsif ($opcode == 0x0a) {
	# quit
	last;
      } else {
	$self->zi_die($op_style, $opcode, $opcode_count);
      }
    } else {
      $self->zi_die($op_style, $opcode, $opcode_count);
    }
  }

  $zio->newline();
  if (Games::Rezrov::ZOptions::END_OF_SESSION_MESSAGE) {
    $zio->write_string("*** End of session ***");
    $zio->newline();
    $zio->update();
    $zio->get_input(1,1);
    # this emulates the behavior of the old Infocom MS-DOS interpreter.
    # IMO a message and a pause is nice for GUIs which would be destroyed
    # (e.g. Tk), first giving the user a chance to see any final text.
  }

  $zio->set_game_title(" ") if Games::Rezrov::StoryFile::game_title();
  $zio->cleanup();
  printf "Opcode counts: %s\n", join " ", @op_counts if $count_opcodes;
};

sub zi_die {
  my ($self, $style, $opcode, $count) = @_;
  my $desc = $TYPE_LABELS[$style] || "mystery";
  $self->zio()->fatal_error(sprintf "Unknown/unimplemented %s opcode %d (0x%02x), \#%d", $desc, $opcode, $opcode, $count);

}
