package Games::Rezrov::ZText;
# text decoder

use Carp qw(cluck);
use strict;

use Games::Rezrov::StoryFile;
use Games::Rezrov::Inliner;

use constant SPACE => 32;

my @alpha_table = (
		   [ 'a','b','c','d','e','f','g','h','i','j','k','l','m','n','o','p','q','r','s','t','u','v','w','x','y','z' ],
		   [ 'A','B','C','D','E','F','G','H','I','J','K','L','M','N','O','P','Q','R','S','T','U','V','W','X','Y','Z' ],
		   [ '_','^','0','1','2','3','4','5','6','7','8','9','.',',','!','?','_','#','\'','"','/','\\','-',':','(',')' ]
);

my $INLINE_CODE = '
sub decode_text {
  my ($self, $address, $buf_ref) = @_;
  # decode and return text at this address; see spec section 3
  # in array context, returns address after decoding.
  my $buffer = "";
  $buf_ref = \$buffer unless ($buf_ref);
  # $buf_ref supplied if called recursively

  my ($word, $zshift, $zchar);
  my $alphabet = 0;
  my $abbreviation = 0;
  my $two_bit_code = 0;
  my $two_bit_flag = 0;
  # spec 3.4
  my $zh = Games::Rezrov::StoryFile::header();
  my $flen = $zh->file_length();
      
  while (1) {
    last if $address >= $flen;
    $word = GET_WORD_AT($address);
    $address += 2;
    # spec 3.2
    for ($zshift = 10; $zshift >= 0; $zshift -= 5) {
      # break word into 3 zcharacters of 5 bytes each
      $zchar = ($word >> $zshift) & 0x1f;
      if ($two_bit_flag > 0) {
	# spec 3.4
	if ($two_bit_flag++ == 1) {
	  $two_bit_code = $zchar << 5; # first 5 bits
	} else {
	  $two_bit_code |= $zchar; # last 5
#	  $receiver->write_zchar($two_bit_code);
	  $$buf_ref .= chr($two_bit_code);
	  $two_bit_code = $two_bit_flag = 0;
	  # done
	}
      } elsif ($abbreviation) {
	# synonym/abbreviation; spec 3.3
	my $entry = (32 * ($abbreviation - 1)) + $zchar;
#	print STDERR "abbrev $abbreviation\n";
	my $addr = $zh->get_abbreviation_addr($entry);
	$self->decode_text($addr, $buf_ref);
	$abbreviation = 0;
      } elsif ($zchar < 6) {
	if ($zchar == 0) {
	  #	$receiver->write_zchar(SPACE);
	  $$buf_ref .= " ";
	} elsif ($zchar == 4) {
	  # spec 3.2.3: shift character; alphabet 1
	  $alphabet = 1;
	} elsif ($zchar == 5) {
	  # spec 3.2.3: shift character; alphabet 2
	  $alphabet = 2;
	} elsif ($zchar >= 1 && $zchar <= 3) {
	  # spec 3.3: next zchar is an abbreviation code
	  $abbreviation = $zchar;
	}
      } else {
	# spec 3.5: convert remaining chars from alpha table
	$zchar -= 6;
	# convert to string index
	if ($alphabet < 2) {
	  $$buf_ref .= $alpha_table[$alphabet]->[$zchar];
	} else {
	  # alphabet 2; some special cases (3.5.3)
	  if ($zchar == 0) {
	    $two_bit_flag = 1;
	  } elsif ($zchar == 1) {
	    $$buf_ref .= chr(Games::Rezrov::ZConst::Z_NEWLINE());
	  } else {
	    $$buf_ref .= $alpha_table[$alphabet]->[$zchar];
	  }
	}
	$alphabet = 0;
	# applies to this character only (3.2.3)
      }
      # unset temp flags!
    }
    last if (($word & 0x8000) > 0);
  }
  
#  print STDERR "dc at $address = \"$buffer\"\n";
  return wantarray ? (\$buffer, $address) : \$buffer;
}
';

Games::Rezrov::Inliner::inline(\$INLINE_CODE);
eval $INLINE_CODE;
undef $INLINE_CODE;

sub new {
  my $self = [];
  bless $self, shift;
  return $self;
}

1;
