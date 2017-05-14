package Games::Rezrov::Quetzal;
# Quetzal save file format, from the spec "savefile_14.txt" at:
# http://www.geocities.com/SiliconValley/Vista/6631/

use strict;

use Games::Rezrov::QChunk;
#use Games::Rezrov::StoryFile;

use constant IFHD => "IFhd";
use constant CMEM => "CMem";
use constant UMEM => "UMem";
use constant STKS => "Stks";

use constant DEBUG => 0;

use SelfLoader;

1;
__DATA__

sub new {
  my ($type) = @_;
  my $self = {};
  bless $self, $type;
  return $self;
}

sub restore {
  # public
  my ($self, $filename, $undo) = @_;

  #
  #  Open file, verify type, get length
  #
  my @chunks;
  if ($undo) {
    @chunks = @{$undo};
  } else {
    unless (open(RESTORE, $filename)) {
      $self->error_message("Can't open $filename: $!");
      return 0;
    }
    Games::Rezrov::StoryFile::current_room(0);
    binmode RESTORE;
    my $id = read_chunk_id(\*RESTORE);
    my $master_length;
    if ($id eq "FORM") {
      $master_length = read_int_4(\*RESTORE);
      unless (read_chunk_id(\*RESTORE) eq "IFZS") {
	$self->error_message("Bad subtype, expected IFZS");
	return 0;
      }
    } else {
      $self->error_message("$filename is not a Quetzal-format save file.");
      return 0;
    }
    
    #
    #  Load all chunks from file
    #
    while (tell(RESTORE) < $master_length) {
      my $qc = new Games::Rezrov::QChunk();
      my $len = $qc->load(\*RESTORE);
      if ($len < 0) {
	# error
	$self->error_message("Chunk read error");
	return 0;
      } elsif (($len % 2) == 1) {
	# spec 8.4.1: if odd number of data bytes, there's an extra
	# pad byte after, not counted in the length.
	read_byte(\*RESTORE);
      }
      push @chunks, $qc;
    }
  }
  
  my %have = map {$_->id() => $_} @chunks;
  foreach (keys %have) {
    # warn about unknown chunks
    next if $_ eq IFHD or $_ eq CMEM or $_ eq UMEM or $_ eq STKS;
    print STDERR "Unhandled chunk type: $_\n";
  }
  
  my $status = 0;
  if ($have{IFHD()} and
      ($have{CMEM()} or $have{UMEM()}) and
      $have{STKS()}) {
    #
    # we have all chunks required to restore: proceed
    #
    if (my $return_pc = $self->compare_ifhd($have{IFHD()})) {
      $self->return_pc($return_pc);
      if ($have{CMEM()}) {
	$self->decode_cmem($have{CMEM()});
      } else {
	$self->decode_umem($have{UMEM()});
      }
      $self->decode_stks($have{STKS()});
      $status = 1;
    } else {
      $self->error_message("This save file appears to be from a different game.");
    }
  } else {
    $self->error_message("Some required data is missing from the file.");
  }
  
  return $status;
}

sub save {
  # save game
  my ($self, $filename, %options) = @_;
  
  my $undo = $options{"-undo"};
  my @chunks;
  push @chunks, $self->create_ifhd();
  if ($undo or $options{"-umem"}) {
    # uncompressed memory; big but quick to create
    push @chunks, $self->create_umem();
  } else {
    # compressed memory; much smaller but slower to create
    push @chunks, $self->create_cmem();
  }
  push @chunks, $self->create_stks();

  if ($undo) {
    return \@chunks;
  } else {
    unless (open(SAVE, ">$filename")) {
      $self->error_message("Can't write to $filename: $!");
      return 0;
    }
    binmode SAVE;
    print SAVE 'FORM';
    my $len = 4;
    foreach (@chunks) {
      $len += $_->get_chunk_length();
    }
    print SAVE pack 'N', $len;
    print SAVE 'IFZS';
    foreach (@chunks) {
      $_->write(\*SAVE);
    }
    close SAVE;
  }
  
  return 1;
}

sub return_pc {
  return (defined $_[1] ? $_[0]->{"return_pc"} = $_[1] : $_[0]->{"return_pc"});
}

sub error_message {
  return (defined $_[1] ? $_[0]->{"error_message"} = $_[1] : $_[0]->{"error_message"});
}

sub read_chunk_id {
  my ($fh) = @_;
  my $buf;
  read($fh, $buf, 4);
  return $buf;
}

sub read_int_4 {
  # read a signed 4-byte int
  my ($fh) = @_;
  my $buf;
  read($fh, $buf, 4);
  return unpack 'N', $buf;
}

sub read_byte {
  my ($fh) = @_;
  my $buf;
  read($fh, $buf, 1);
  return unpack 'C', $buf;
}

sub compare_ifhd {
  # compare version info from save file to the game we're running.
  # see spec 5.4
  my ($self, $ifhd) = @_;

  my $release_number = $ifhd->get_word();
  my $serial_number = $ifhd->get_string(6);
  my $checksum = $ifhd->get_word();
  my $return_pc = $ifhd->get_word_3();

  return Games::Rezrov::StoryFile::is_this_game($release_number, $serial_number, $checksum) ? $return_pc : 0;
}

sub decode_umem {
  my ($self, $chunk) = @_;
  my $story_b = Games::Rezrov::StoryFile::get_story();
  my $data = $chunk->get_data();
  substr($$story_b, 0, length $$data) = $$data;
}

sub decode_cmem {
  # XOR-RL compressed diff of dynamic memory vs original memory.
  # see spec 3.7
  my ($self, $chunk) = @_;
  my ($i, $b, $orig);
  # unsigned
  my $zlen;
  my $story_pointer = 0;
  my $static_start = Games::Rezrov::StoryFile::header()->static_memory_address();
  $chunk->reset_read_pointer();
  # might be from RAM

  while ($chunk->eof() == 0) {
    $b = $chunk->get_byte();
    if ($b == 0) {
      # zero means a run of "zero" bytes (no difference from original story)
      $zlen = $chunk->get_byte() + 1;
      while ($zlen) {
	Games::Rezrov::StoryFile::set_byte_at($story_pointer, Games::Rezrov::StoryFile::save_area_byte($story_pointer));
	$zlen--;
	$story_pointer++;
      }
    } else {
      # a literal byte, XOR'ed
      $orig = Games::Rezrov::StoryFile::save_area_byte($story_pointer);
      Games::Rezrov::StoryFile::set_byte_at($story_pointer++, $b ^ $orig);
    }
  }
  while ($story_pointer < $static_start) {
    Games::Rezrov::StoryFile::set_byte_at($story_pointer, Games::Rezrov::StoryFile::save_area_byte($story_pointer));
    $story_pointer++;
  }
}

sub decode_stks {
  my ($self, $chunk) = @_;
  # decode story stacks
  # see spec section 4
  # FIX ME: return status!
  my @calls;
  
  while ($chunk->eof() == 0) {
    print STDERR "---- Frame: " if DEBUG;
    #      ZFrame zf = new ZFrame();
    #      zf.return_pc = $chunk->get_word_3();
    my $rpc = $chunk->get_word_3();
    # 4.3.1
    my $flags = $chunk->get_byte();
    # 4.3.2
    my $var_count = $flags & 0xf;
    # spec 4.3.2, 4.3.6: last 4 bits hold number of local vars
    my $result_var = $chunk->get_byte();
    # 4.3.3: variable number to store result.  Ignored for v3?
    my $zf = [];
    if (($flags & 0x10) > 0) {
      $zf->[Games::Rezrov::StoryFile::FRAME_RPC] = $rpc;
      $zf->[Games::Rezrov::StoryFile::FRAME_CALL_TYPE] =
	Games::Rezrov::StoryFile::FRAME_PROCEDURE;
#      print STDERR ("proc type frame: TEST ME\n");
    } else {
      $zf->[Games::Rezrov::StoryFile::FRAME_RPC] = --$rpc;
      $zf->[Games::Rezrov::StoryFile::FRAME_CALL_TYPE] = 
	Games::Rezrov::StoryFile::FRAME_FUNCTION;
      # Q: Why are save file stack PCs incremented by one?
      # A: Because save file contains PC after reading variable # for
      #    result, reading it in increments PC.
      # Q2: Why do we record this, when returning back up the
      #     stack will read it anyway???
      if ($rpc > 0) {
	# FIX ME
	# aside from dummy frame, check if the result variable sent
	# with this frame matches the result variable in the story file
	printf STDERR "function, %d\n", $rpc if DEBUG;
	my $r2 = Games::Rezrov::StoryFile::get_byte_at($rpc);
	die "Result variable mismatch; $r2 vs $result_var, wtf?!" if ($r2 != $result_var);
      } else {
	# dummy frame:
	printf STDERR "dummy\n" if DEBUG;
	$zf->[Games::Rezrov::StoryFile::FRAME_CALL_TYPE] =
	  Games::Rezrov::StoryFile::FRAME_DUMMY;
      }
    }
    # FIX ME: sanity check
    my $args = $chunk->get_byte();
    # 4.3.4; where is this used ???  FIX ME
    my $eval_stack_count = $chunk->get_word();
    # 4.3.5
    my $i;
    for ($i=0; $i < $var_count; $i++) {
      # local variables; 4.3.6
      my $local_var = $chunk->get_word();
      printf STDERR "Restore local var %d = %d\n", $i + 1, $local_var if DEBUG;
      $zf->[Games::Rezrov::StoryFile::FRAME_LOCAL + $i] = $local_var;
    }
    $#$zf = Games::Rezrov::StoryFile::FRAME_ROUTINE - 1;
    # expand frame so routine variables will start to be added at correct index
    for ($i=0; $i < $eval_stack_count; $i++) {
      # stack variables; 4.3.7
      my $stack_var = $chunk->get_word();
      printf STDERR "Restore routine: %d\n", $stack_var if DEBUG;
      push @{$zf}, $stack_var;
    }
    push @calls, $zf;
  }
  Games::Rezrov::StoryFile::set_game_state(\@calls, $self->return_pc());
}

sub create_ifhd {
  # create IFHD header chunk
  my $self = shift;
  my $ifhd = new Games::Rezrov::QChunk(IFHD);
  my $zh = Games::Rezrov::StoryFile::header();
  $ifhd->add_word($zh->release_number());
  $ifhd->add_string($zh->serial_code(), 6);
  $ifhd->add_word($zh->file_checksum());
  $ifhd->add_word_3(Games::Rezrov::StoryFile::get_pc());
  $ifhd->reset_read_pointer();
  return $ifhd;
}

sub create_umem {
  # save dynamic memory data: simple dump, see 3.8
  my $self = shift;
  my $story_b = Games::Rezrov::StoryFile::get_story();
  my $umem = new Games::Rezrov::QChunk(UMEM);
  $umem->add_data(substr($$story_b,0,
			 Games::Rezrov::StoryFile::header()->static_memory_address()));
  $umem->reset_read_pointer();
  return $umem;
}

sub create_cmem {
  # save dynamic memory data:
  # create XOR-RLL memory diff; see spec 3.7
  my $self = shift;
  my $cmem = new Games::Rezrov::QChunk(CMEM);
  my $save_bytes = Games::Rezrov::StoryFile::header()->static_memory_address();
  my $save_area = Games::Rezrov::StoryFile::get_save_area();
  my $story_b = Games::Rezrov::StoryFile::get_story();
  my $diff = substr($$story_b,0,$save_bytes) ^ $$save_area;
  # XOR the game state with the original game state
  
  my $zcount = 0;
  my $d;
  for (my $i=0; $i < $save_bytes; $i++) {
    $d = vec($diff, $i, 8);
    # each XOR'd byte
    if ($d > 0) {
      # a difference: save literally
      if ($zcount > 0) {
	# save last run of zeros
	$cmem->add_byte(0);
	$cmem->add_byte($zcount - 1);
	$zcount = 0;
      }
      $cmem->add_byte($d);
    } else {
      # zero byte (no diff), save as a run
      if (++$zcount == 256) {
	# maximum run, save
	$cmem->add_byte(0);
	$cmem->add_byte($zcount - 1);
	$zcount = 0;
      }
    }
  }
  # no need to save last zlen block, rest assumed to be identical
  
  $cmem->reset_read_pointer();
  return $cmem;
}

sub create_stks {
  # save stack data: see spec 4.3
  my ($self) = @_;
  my $stks = new Games::Rezrov::QChunk(STKS);
  my @call_stack = @{Games::Rezrov::StoryFile::call_stack()};
  # a copy!
  
  foreach my $zf (@call_stack) {
    # Save frames, oldest first.
    my $result_var = 0;
    my $rpc = $zf->[Games::Rezrov::StoryFile::FRAME_RPC];
    print STDERR "---- Frame: " if DEBUG;
    my $ftype = $zf->[Games::Rezrov::StoryFile::FRAME_CALL_TYPE];
    my $local_var_count = 0;
    if ($ftype == Games::Rezrov::StoryFile::FRAME_DUMMY) {
      # first frame is "dummy" frame, should have all fields set to zero.
      print STDERR "dummy\n" if DEBUG;
      $stks->add_word_3(0);
      $local_var_count = 0;
      $stks->add_byte(0);
      $stks->add_byte(0);
      $stks->add_byte(0);
      # 4.11.1: dummy frame has all fields set to 0 except eval stack used
    } else {
      if ($ftype == Games::Rezrov::StoryFile::FRAME_FUNCTION) {
	# called as a function
	printf STDERR "function, %d\n", $rpc if DEBUG;
	$result_var = Games::Rezrov::StoryFile::get_byte_at($rpc);
	# get the variable number used to store the result of 
	# this function call.  Save the PC as it would appear
	# after having read the variable number.
	$stks->add_word_3($rpc + 1);
      } else {
	# called as a procedure
	printf STDERR "procedure, %d\n", $rpc if DEBUG;
	$stks->add_word_3($rpc);
      }
      # 4.3.1
      $local_var_count = Games::Rezrov::StoryFile::FRAME_MAX_LOCAL_VARIABLES;
      # constant: always 15 local variables/frame
      my $flag = $local_var_count;
      if ($ftype == Games::Rezrov::StoryFile::FRAME_PROCEDURE) {
	$flag |= 0x10;
	$result_var = 0;
	# 4.6
      }
      $stks->add_byte($flag);
      # 4.3.2
      $stks->add_byte($result_var);
      # 4.3.3: var # for result
      $stks->add_byte(0);
      # 4.3.4: arguments supplied
      # not used in v3?
    }

    $stks->add_word($#$zf - Games::Rezrov::StoryFile::FRAME_ROUTINE + 1);
    # 4.3.5: how many routine variables?
    
    my $value;
    for (my $i=0; $i < $local_var_count; $i++) {
      # 4.3.6: save local variables
      $value = $zf->[Games::Rezrov::StoryFile::FRAME_LOCAL + $i] || 0;
      printf STDERR "Save local var %d = %d\n", $i + 1, $value if DEBUG;
      $stks->add_word($value);
    }
    
    for (my $i = Games::Rezrov::StoryFile::FRAME_ROUTINE;
	 $i <= $#$zf; $i++) {
      # 4.3.7, 4.7: save routine variables, oldest first
      $value = $zf->[$i];
      printf STDERR "Save routine: $value\n" if DEBUG;
      $stks->add_word($value);
    }
  }

  $stks->reset_read_pointer();
  return $stks;
}

1;

