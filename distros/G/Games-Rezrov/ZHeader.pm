# ZHeader: version-specific information and settings
# for each game

package Games::Rezrov::ZHeader;

use Games::Rezrov::ZConst;
use Games::Rezrov::Inliner;

use strict;

use constant FLAGS_1 => 0x01;  # one byte
use constant FLAGS_2 => 0x10;  # TWO BYTES
# location of various flags in the header

# see spec section 11:
use constant RELEASE_NUMBER => 0x02;
use constant PAGED_MEMORY_ADDRESS => 0x04;
use constant FIRST_INSTRUCTION_ADDRESS => 0x06;
use constant DICTIONARY_ADDRESS => 0x08;
use constant OBJECT_TABLE_ADDRESS => 0x0a;
use constant GLOBAL_VARIABLE_ADDRESS => 0x0c;
use constant STATIC_MEMORY_ADDRESS => 0x0e;
use constant SERIAL_CODE => 0x12;
use constant ABBREV_TABLE_ADDRESS => 0x18;
use constant FILE_LENGTH => 0x1a;
use constant CHECKSUM => 0x1c;

use constant STATUS_NOT_AVAILABLE => 0x10;  # bit 4 (#5)
use constant SCREEN_SPLITTING_AVAILABLE => 0x20; # bit 5 (#6)

# Flags 1
use constant TANDY => 0x08;

# Flags 2
use constant TRANSCRIPT_ON => 0x01;            # bit 0
use constant FORCE_FIXED => 0x02;              # bit 1
use constant REQUEST_STATUS_REDRAW => 0x04;    # bit 2

# Flags 2, v5+:
use constant WANTS_PICTURES => 0x08;
use constant WANTS_UNDO => 0x10;
use constant WANTS_MOUSE => 0x20;
use constant WANTS_COLOR => 0x40;
use constant WANTS_SOUND => 0x80;
# Flags 2, v6+:
use constant WANTS_MENUS => 0x0100;  # ??

use constant BACKGROUND_COLOR => 0x2c;
use constant FOREGROUND_COLOR => 0x2d;
# 8.3.2, 8.3.3

use constant SCREEN_HEIGHT_LINES => 0x20;
use constant SCREEN_WIDTH_CHARS => 0x21;
use constant SCREEN_WIDTH_UNITS => 0x22;
use constant SCREEN_HEIGHT_UNITS => 0x24;

use constant FONT_WIDTH_UNITS_V5 => 0x26;
use constant FONT_WIDTH_UNITS_V6 => 0x27;

use constant FONT_HEIGHT_UNITS_V5 => 0x27;
use constant FONT_HEIGHT_UNITS_V6 => 0x26;

use constant ROUTINES_OFFSET => 0x28;
use constant STRINGS_OFFSET => 0x2a;

use Games::Rezrov::MethodMaker ([],
			 qw(
			    abbrev_table_address
			    file_checksum
			    release_number
			    paged_memory_address
			    object_table_address
			    global_variable_address
			    static_memory_address
			    first_instruction_address
			    dictionary_address
			    serial_code
			    file_length
			    story
			    version
			    object_bytes
			    attribute_bytes
			    pointer_size
			    max_properties
			    max_objects
			    attribute_starter
			    object_count
			    encoded_word_length
			    is_time_game
			    strings_offset
			    routines_offset
			   ));

#use SelfLoader;

1;

my $INLINE_CODE = '
sub new {
  my ($type, $zio) = @_;
  my $self = [];
  bless $self, $type;
  
  my $version = GET_BYTE_AT(0);
  if ($version < 1 or $version > 8) {
    die "\nThis does not appear to be a valid game file.\n";
  } elsif (($version < 3 or $version > 5) and $version != 8) {
#  } elsif ($version < 3 or $version > 8) {
#    die "Sorry, only z-code versions 3-8 are supported at present...\nAnd even those need work!  :)\n"
    die "Sorry, only z-code versions 3,4,5 and 8 are supported at present...\nAnd even those need work!  :)\n"
  } else {
    $self->version($version);
  }

  my $f1 = GET_BYTE_AT(FLAGS_1);
  $self->is_time_game($f1 & 0x02 ? 1 : 0);
  # a "time" game: 8.2.3.2

  my $start_rows = Games::Rezrov::StoryFile::rows();
  my $start_columns = Games::Rezrov::StoryFile::columns();

  $f1 |= TANDY if Games::Rezrov::ZOptions::TANDY_BIT();
  # turn on the "tandy bit"
  
  if ($version <= 3) {
    $self->encoded_word_length(6);
    # 13.3, 13.4

    # set bits 4 (status line) and 5 (screen splitting) appropriately
    # depending on the ability of the ZIO implementation
    if ($zio->can_split()) {
      # yes
      $f1 |= SCREEN_SPLITTING_AVAILABLE;
      $f1 &= ~ STATUS_NOT_AVAILABLE;
    } else {
      # no
      $f1 &= ~ SCREEN_SPLITTING_AVAILABLE;
      $f1 |= STATUS_NOT_AVAILABLE;
    }

    # "bit 6" (#7): variable-pitch font is default?
    if ($zio->fixed_font_default()) {
      $f1 |= 0x40;
    } else {
      $f1 &= ~0x40;
    }
  } else {
    #
    # versions 4+
    #
    $self->encoded_word_length(9);
    # 13.3, 13.4

    if ($version >= 4) {
      $f1 |= 0x04;
      # "bit 2" (#3): boldface available
      $f1 |= 0x08;
      # "bit 3" (#4): italic available
      $f1 |= 0x10;
      # "bit 4" (#5): fixed-font available

#      $f1 |= 0x80;
      $f1 &= ~0x80;
      # "bit 7" (#8): timed input NOT available

      Games::Rezrov::StoryFile::set_byte_at(30, Games::Rezrov::ZOptions::INTERPRETER_ID());
      # interpreter number
      Games::Rezrov::StoryFile::set_byte_at(31, ord "R");
      # interpreter version; "R" for rezrov
      
      $self->set_columns($start_columns);
      $self->set_rows($start_rows);
    }
    if ($version >= 5) {
      if ($zio->can_use_color()) {
	# "bit 0" (#1): colors available
	$f1 |= 0x01;
      }

      Games::Rezrov::StoryFile::set_byte_at(BACKGROUND_COLOR, Games::Rezrov::ZConst::COLOR_BLACK);
      Games::Rezrov::StoryFile::set_byte_at(FOREGROUND_COLOR, Games::Rezrov::ZConst::COLOR_WHITE);
      # 8.3.3: default foreground and background
      # FIX ME!

      my $f2 = Games::Rezrov::StoryFile::get_word_at(FLAGS_2);
      if ($zio->groks_font_3() and
	  !Games::Rezrov::StoryFile::font_3_disabled()) {
	# ZIO can decode font 3 characters
	$f2 |= WANTS_PICTURES;
      } else {
	# nope
	$f2 &= ~ WANTS_PICTURES;
      }
      
#      $f2 |= WANTS_UNDO;
      $f2 &= ~ WANTS_UNDO;
      # FIX ME: should we never use this???

      if ($f2 & WANTS_COLOR) {
	# 8.3.4: the game wants to use colors
#	print "wants color!\n";
      }
      Games::Rezrov::StoryFile::set_word_at(FLAGS_2, $f2);
    }
    if ($version >= 6) {
      # more unimplemented: see 8.3.2, etc
      $self->routines_offset(Games::Rezrov::StoryFile::get_word_at(ROUTINES_OFFSET));
      $self->strings_offset(Games::Rezrov::StoryFile::get_word_at(STRINGS_OFFSET));
    }
  }

  Games::Rezrov::StoryFile::set_byte_at(FLAGS_1, $f1);
  # write back the header flags

  $self->release_number(Games::Rezrov::StoryFile::get_word_at(RELEASE_NUMBER));
  $self->paged_memory_address(Games::Rezrov::StoryFile::get_word_at(PAGED_MEMORY_ADDRESS));
  $self->first_instruction_address(Games::Rezrov::StoryFile::get_word_at(FIRST_INSTRUCTION_ADDRESS));
  $self->dictionary_address(Games::Rezrov::StoryFile::get_word_at(DICTIONARY_ADDRESS));
  $self->object_table_address(Games::Rezrov::StoryFile::get_word_at(OBJECT_TABLE_ADDRESS));
  $self->global_variable_address(Games::Rezrov::StoryFile::get_word_at(GLOBAL_VARIABLE_ADDRESS));
  $self->static_memory_address(Games::Rezrov::StoryFile::get_word_at(STATIC_MEMORY_ADDRESS));
  $self->serial_code(Games::Rezrov::StoryFile::get_string_at(SERIAL_CODE, 6));
  # see zmach06e.txt
  $self->abbrev_table_address(Games::Rezrov::StoryFile::get_word_at(ABBREV_TABLE_ADDRESS));
  $self->file_checksum(Games::Rezrov::StoryFile::get_word_at(CHECKSUM));

  my $flen = Games::Rezrov::StoryFile::get_word_at(FILE_LENGTH);
  if ($version <= 3) {
    # see 11.1.6
    $flen *= 2;
  } elsif ($version == 4 || $version == 5) {
    $flen *= 4;
  } else {
    $flen *= 8;
  }
  $self->file_length($flen);
  
  #
  #  set object "constants" for this version...
  #
  if ($version <= 3) {
    # 12.3.1
    $self->object_bytes(9);
    $self->attribute_bytes(4);
    $self->pointer_size(1);
    $self->max_properties(31);	# 12.2
    $self->max_objects(255);		# 12.3.1
  } else {
    # 12.3.2
    $self->object_bytes(14);
    $self->attribute_bytes(6);
    $self->pointer_size(2);
    $self->max_properties(63);	# 12.2
    $self->max_objects(65535);	# 12.3.2
  }
  die("check your math!")
    if (($self->attribute_bytes() + ($self->pointer_size() * 3) + 2)
	!= $self->object_bytes());
  
  $self->attribute_starter($self->object_table_address() +
			   ($self->max_properties() * 2));
  
  my $obj_space = $self->global_variable_address() - $self->attribute_starter();
  # how many bytes exist between the start of the object area and
  # the beginning of the global variable block?
  my $object_count;
  if ($obj_space > 0) {
    # hack:
    # guess approximate object count; most useful for games later than v3
    # FIX ME: is this _way_ off?  Better to check validity of each object
    # sequentially, stopping w/invalid pointers, etc?
    $object_count = $obj_space / $self->object_bytes();
    $object_count = $self->max_objects()
      if $object_count > $self->max_objects();
  } else {
    # header data not arranged the way we expect; oh well.
    $object_count = $self->max_objects();
  }
  $self->object_count($object_count);
#  die sprintf "objects: %s\n", $object_count;
  
  return $self;
}

sub get_colors {
  return (GET_BYTE_AT(FOREGROUND_COLOR),
	  GET_BYTE_AT(BACKGROUND_COLOR));
}

';

Games::Rezrov::Inliner::inline(\$INLINE_CODE);
eval $INLINE_CODE;
#print $INLINE_CODE;
#die "oof";
undef $INLINE_CODE;

1;

#__DATA__

sub get_abbreviation_addr {
  my ($self, $entry) = @_;
  # Spec 3.3: fetch and convert the "word address" of the given entry
  # in the abbreviations table.
#  print STDERR "gaa\n";
  my $abbrev_addr = $self->abbrev_table_address() + ($entry * 2);
  return Games::Rezrov::StoryFile::get_word_at($abbrev_addr) * 2;
  # "word address"; only used for abbreviations (packed address
  # rules do not apply here)
}

sub set_columns {
  # 8.4: set the dimensions of the screen.
  # only needed in v4+
  # arg: number of columns
  Games::Rezrov::StoryFile::set_byte_at(SCREEN_WIDTH_CHARS, $_[1]);
  if ($_[0]->version >= 5) {
    Games::Rezrov::StoryFile::set_byte_at($_[0]->version >= 6 ?
					  FONT_WIDTH_UNITS_V6 : FONT_WIDTH_UNITS_V5, 1);
    Games::Rezrov::StoryFile::set_word_at(SCREEN_WIDTH_UNITS, $_[1]);
    # ?
  }
}

sub set_rows {
  # arg: number of rows
  Games::Rezrov::StoryFile::set_byte_at(SCREEN_HEIGHT_LINES, $_[1]);
  if ($_[0]->version >= 5) {
    Games::Rezrov::StoryFile::set_byte_at($_[0]->version >= 6 ?
		FONT_HEIGHT_UNITS_V6 : FONT_HEIGHT_UNITS_V5, 1);
    Games::Rezrov::StoryFile::set_word_at(SCREEN_HEIGHT_UNITS, $_[1]);
  }
}

sub wants_color {
  # 8.3.4: does the game want to use colors?
  return Games::Rezrov::StoryFile::get_word_at(FLAGS_2) & WANTS_COLOR ? 1 : 0;
}

sub fixed_font_forced {
  # 8.1: fixed-font printing may be forced by the game
  if ($_[0]->version >= 3) {
    # see section 10
    return Games::Rezrov::StoryFile::get_word_at(FLAGS_2) & FORCE_FIXED;
  } else {
    return 0;
  }
}


1;
