package HTML::HTML5::Parser::Charset::UnicodeChecker;
## skip Test::Tabs
use strict;

our $VERSION = '0.301';

## NOTE: For more information (including rationals of checks performed
## in this module), see
## <http://suika.fam.cx/gate/2005/sw/Unicode%E7%AC%A6%E5%8F%B7%E5%8C%96%E6%96%87%E5%AD%97%E5%88%97%E3%81%AE%E9%81%A9%E5%90%88%E6%80%A7>.

## NOTE: Unicode's definition for character string conformance is 
## very, very vague so that it is difficult to determine what error
## level is appropriate for each error.  The Unicode Standard abuses
## conformance-creteria-like terms such as "deprecated", "discouraged",
## "preferred", "better", "not encouraged", "should", and so on with no
## clear explanation of their difference (if any) or relationship to
## the conformance.  In fact, that specification does not define the
## conformance class for character strings.

sub new_handle ($$;$) {
  my $self = bless {
    queue => [],
    new_queue => [],
    onerror => sub {},
    #onerror_set
    level => {
      unicode_should => 'w',
      unicode_deprecated => 'w', # = unicode_should
      unicode_discouraged => 'w',
      unicode_preferred => 'w',
      ## NOTE: We do some "unification" of levels - for example,
      ## "not encouraged" is unified with "discouraged" and
      ## "better" is unified with "preferred".

      must => 'm',
      warn => 'w',
    },
  }, $_[0];
  $self->{handle} = $_[1]; # char stream
  my $mode = $_[2] || 'default'; # or 'html5'
  $self->{level_map} = {
    ## Unicode errors
    'unicode deprecated' => 'unicode_deprecated',
    'nonchar' => $mode eq 'html5' ? 'must' : 'unicode_should',
        ## NOTE: HTML5 parse error.
    'unicode should' => 'unicode_should',
    'unicode discouraged' => 'unicode_discouraged',
    'unicode not preferred' => 'unicode_preferred',

    ## HTML5 errors (See "text" definition of the spec)
    'control char' => $mode eq 'html5' ? 'must' : 'warn',
        ## NOTE: HTML5 parse error.
    'non unicode' => $mode eq 'html5' ? 'must' : 'warn',
        ## NOTE: In HTML5, replaced by U+FFFD (not a parse error).
  };
  $self->{replace_non_unicode} = ($mode eq 'html5');
  return $self;
} # new_handle

my $etypes = {
              0x0340 => 'unicode deprecated',
              0x0341 => 'unicode deprecated',
              0x17A3 => 'unicode deprecated',
              0x17D3 => 'unicode deprecated',
              0x206A => 'unicode deprecated',
              0x206B => 'unicode deprecated',
              0x206C => 'unicode deprecated',
              0x206D => 'unicode deprecated',
              0x206E => 'unicode deprecated',
              0x206F => 'unicode deprecated',
              0xE0001 => 'unicode deprecated',
              
              0xFFFE => 'nonchar',
              0xFFFF => 'nonchar',
              0x1FFFE => 'nonchar',
              0x1FFFF => 'nonchar',
              0x2FFFE => 'nonchar',
              0x2FFFF => 'nonchar',
              0x3FFFE => 'nonchar',
              0x3FFFF => 'nonchar',
              0x4FFFE => 'nonchar',
              0x4FFFF => 'nonchar',
              0x5FFFE => 'nonchar',
              0x5FFFF => 'nonchar',
              0x6FFFE => 'nonchar',
              0x6FFFF => 'nonchar',
              0x7FFFE => 'nonchar',
              0x7FFFF => 'nonchar',
              0x8FFFE => 'nonchar',
              0x8FFFF => 'nonchar',
              0x9FFFE => 'nonchar',
              0x9FFFF => 'nonchar',
              0xAFFFE => 'nonchar',
              0xAFFFF => 'nonchar',
              0xBFFFE => 'nonchar',
              0xBFFFF => 'nonchar',
              0xCFFFE => 'nonchar',
              0xCFFFF => 'nonchar',
              0xDFFFE => 'nonchar',
              0xDFFFF => 'nonchar',
              0xEFFFE => 'nonchar',
              0xEFFFF => 'nonchar',
              0xFFFFE => 'nonchar',
              0xFFFFF => 'nonchar',
              0x10FFFE => 'nonchar',
              0x10FFFF => 'nonchar',

              0x0344 => 'unicode should', # COMBINING GREEK DIALYTIKA TONOS
              0x03D3 => 'unicode should', # GREEK UPSILON WITH ...
              0x03D4 => 'unicode should', # GREEK UPSILON WITH ...
              0x20A4 => 'unicode should', # LIRA SIGN
              
              0x2126 => 'unicode should', # OHM SIGN # also, discouraged
              0x212A => 'unicode should', # KELVIN SIGN
              0x212B => 'unicode should', # ANGSTROM SIGN
              
              ## Styled overlines/underlines in CJK Compatibility Forms
              0xFE49 => 'unicode discouraged',
              0xFE4A => 'unicode discouraged',
              0xFE4B => 'unicode discouraged',
              0xFE4C => 'unicode discouraged',
              0xFE4D => 'unicode discouraged',
              0xFE4E => 'unicode discouraged',
              0xFE4F => 'unicode discouraged',
              
              0x037E => 'unicode discouraged', # greek punctuations
              0x0387 => 'unicode discouraged', # greek punctuations
              
              #0x17A3 => 'unicode discouraged', # also, deprecated
              0x17A4 => 'unicode discouraged',
              0x17B4 => 'unicode discouraged',
              0x17B5 => 'unicode discouraged',
              0x17D8 => 'unicode discouraged',

              0x2121 => 'unicode discouraged', # tel
              0x213B => 'unicode discouraged', # fax
              #0x2120 => 'unicode discouraged', # SM (superscript)
              #0x2122 => 'unicode discouraged', # TM (superscript)

              ## inline annotations
              0xFFF9 => 'unicode discouraged',
              0xFFFA => 'unicode discouraged',
              0xFFFB => 'unicode discouraged',

              ## greek punctuations
              0x055A => 'unicode not preferred',
              0x0559 => 'unicode not preferred',
            
              ## degree signs
              0x2103 => 'unicode not preferred',
              0x2109 => 'unicode not preferred',
              
              ## strongly preferrs U+2060 WORD JOINTER
              0xFEFE => 'unicode not preferred',
             };

$etypes->{$_} = 'unicode deprecated' for 0xE0020 .. 0xE007F;
$etypes->{$_} = 'nonchar' for 0xFDD0 .. 0xFDEF;
    ## ISSUE: U+FDE0-U+FDEF are not excluded in HTML5.
$etypes->{$_} = 'unicode should' for 0xFA30 .. 0xFA6A, 0xFA70 .. 0xFAD9;
$etypes->{$_} = 'unicode should' for 0x2F800 .. 0x2FA1D, 0x239B .. 0x23B3;
$etypes->{$_} = 'unicode should'
    for 0xFB50 .. 0xFBB1, 0xFBD3 .. 0xFD3D, 0xFD50 .. 0xFD8F,
        0xFD92 .. 0xFDC7, 0xFDF0 .. 0xFDFB, 0xFE70 .. 0xFE74,
        0xFE76 .. 0xFEFC;
    ## NOTE: Arabic Presentation Forms-A/B blocks, w/o code points where
    ## no character is assigned, noncharacter code points, and 
    ## U+FD3E and U+FD3F, which are explicitly allowed.
$etypes->{$_} = 'unicode discouraged' for 0x2153 .. 0x217F;
$etypes->{$_} = 'control char'
    for 0x0001 .. 0x0008, 0x000B, 0x000E .. 0x001F, 0x007F .. 0x009F;
#0x0000
#$etypes->{$_} = 'control char' for 0xD800 .. 0xDFFF;

my $check_char = sub ($$) {
  my ($self, $char_code) = @_;

  ## NOTE: Negative $char_code is not supported.

  if ($char_code == 0x000D) {
    $self->{line_diff}++;
    $self->{column_diff} = 0;
    $self->{set_column} = 1;
    $self->{has_cr} = 1;
    return;
  } elsif ($char_code == 0x000A) {
    if ($self->{has_cr}) {
      delete $self->{has_cr};
    } else {
      $self->{line_diff}++;
      $self->{column_diff} = 0;
      $self->{set_column} = 1;
    }
    return;
  } else {
    $self->{column_diff}++;
    delete $self->{has_cr};
  }

  if ($char_code > 0x10FFFF) {
    $self->{onerror}->(type => 'non unicode',
                       text => (sprintf 'U-%08X', $char_code),
                       layer => 'charset',
                       level => $self->{level}->{$self->{level_map}->{'non unicode'}},
                       line_diff => $self->{line_diff},
                       column_diff => $self->{column_diff},
                       ($self->{set_column} ? (column => 1) : ()));
    if ($self->{replace_non_unicode}) {
      return "\x{FFFD}";
    } else {
      return;
    }
  }
  
  my $etype = $etypes->{$char_code};
  if (defined $etype) {
    $self->{onerror}->(type => $etype,
                       text => (sprintf 'U+%04X', $char_code),
                       layer => 'charset',
                       level => $self->{level}->{$self->{level_map}->{$etype}},
                       line_diff => $self->{line_diff},
                       column_diff => $self->{column_diff},
                       ($self->{set_column} ? (column => 1) : ()));
  }

  ## TODO: "khanda ta" should be represented by U+09CE
  ## rather than <U+09A4, U+09CD, U+200D>.

  ## TODO: IDS syntax

  ## TODO: langtag syntax

  return;
}; # $check_char

sub read ($$$;$) {
  my $self = shift;
  my $offset = $_[2] || 0;
  my $count = $self->{handle}->read (@_);
  $self->{line_diff} = 0;
  $self->{column_diff} = -1;
  delete $self->{set_column};
  delete $self->{has_cr};
  for ($offset .. ($offset + $count - 1)) {
    my $c = $check_char->($self, ord substr $_[0], $_, 1);
    if (defined $c) {
      substr ($_[0], $_, 1) = $c;
    }
  }
  return $count;
} # read

sub manakai_read_until ($$$;$) {
  #my ($self, $scalar, $pattern, $offset) = @_;
  my $self = shift;
  my $offset = $_[2] || 0;
  my $count = $self->{handle}->manakai_read_until (@_);
  $self->{line_diff} = 0;
  $self->{column_diff} = -1;
  delete $self->{set_column};
  delete $self->{has_cr};
  for ($offset .. ($offset + $count - 1)) {
    my $c = $check_char->($self, ord substr $_[0], $_, 1);
    if (defined $c) {
      substr ($_[0], $_, 1) = $c;
    }
  }
  return $count;
} # manakai_read_until

sub ungetc ($$) {
  unshift @{$_[0]->{queue}}, chr int ($_[1] or 0);
} # ungetc

sub close ($) {
  shift->{handle}->close;
} # close

sub charset ($) {
  shift->{handle}->charset;
} # charset

sub has_bom ($) {
  shift->{handle}->has_bom;
} # has_bom

sub input_encoding ($) {
  shift->{handle}->input_encoding;
} # input_encoding

sub onerror ($;$) {
  if (@_ > 1) {
    if (defined $_[1]) {
      $_[0]->{handle}->onerror ($_[0]->{onerror} = $_[1]);
      $_[0]->{onerror_set} = 1;
    } else {
      $_[0]->{handle}->onerror ($_[0]->{onerror} = sub {});
      delete $_[0]->{onerror_set};
    }
  }

  return $_[0]->{onerror_set} ? $_[0]->{onerror} : undef;
} # onerror

1;
