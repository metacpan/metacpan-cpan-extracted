# For Emacs: -*- mode:cperl; mode:folding; -*-

package Lingua::SWE::Num2Word;
# ABSTRACT: Number 2 word conversion in SWE.

# {{{ use block

use 5.10.1;

use strict;
use warnings;

use Perl6::Export::Attrs;
use encoding 'utf8';

# }}}
# {{{ variables declaration

our $VERSION = 0.0682;

# }}}
# {{{ num2sv_cardinal                 convert number to text

sub num2sv_cardinal :Export {
  my $positive = shift // return 'noll';

  return if ($positive < 0);

  my $out;
  my @tokens1  = qw(noll ett två tre fyra fem sex sju åtta nio tio elva
                    tolv tretton fjorton femton sexton sjutton arton nitton);   # 0-19 Cardinals
  my @tokens2  = qw(tjugo trettio fyrtio femtio sextio sjutio åttio nittio);    # 20-90 Cardinals (end with zero)

  return $tokens1[$positive] if($positive < 20);            # interval  0 - 19

  if($positive < 100) {                                     # interval 20 - 99
    my @num = split '',$positive;

    $out  = $tokens2[$num[0]-2];
    $out .= $tokens1[$num[1]] if ($num[1]);
  } elsif($positive < 1000) {                               # interval 100 - 999
    my @num = split '',$positive;

    $out = $tokens1[$num[0]].'hundra';

    if ((int $num[1].$num[2]) < 20 && (int $num[1].$num[2])>0 ) {
      $out .= &num2sv_cardinal(int $num[1].$num[2]);
    } else {
      $out .= $tokens2[$num[1]-2] if($num[1]);
      $out .= $tokens1[$num[2]]   if($num[2]);
    }
  } elsif($positive < 1000_000) {                           # interval 1000 - 999_999
    my @num = split '',$positive;
    my @sub = splice @num,-3;

    $out  = &num2sv_cardinal(int join '',@num);
    $out .= 'tusen';
    $out .= &num2sv_cardinal(int join '',@sub) if (int(join "",@sub) >0);
  } elsif($positive < 1_000_000_000) {                      # interval 1_000_000 - 999_999_999
    my @num = split '',$positive;
    my @sub = splice @num,-6;

    $out  = &num2sv_cardinal(int join '',@num);
    $out .= ' miljoner ';
    $out .= &num2sv_cardinal(int join '',@sub) if (int(join "",@sub) >0);
  }

  return $out;
}

# }}}

1;

__END__

# {{{ POD HEAD

=head1 NAME

Lingua::SWE::Num2Word

=head1 VERSION

version 0.0682

positive number to text convertor for Swedish.
Output text is encoded in utf-8 encoding.

=head2 $Rev: 682 $

ISO 639-3 namespace.

=head1 SYNOPSIS

 use Lingua::SWE::Num2Word;

 my $text = Lingua::SWE::Num2Word::num2sv_cardinal( 123 );

 print $text || "sorry, can't convert this number into swedish language.";

=head1 DESCRIPTION

Number 2 word conversion in SWE.

Lingua::SWE::Num2Word is module for converting numbers into their representation
in Swedish. Converts whole numbers from 0 up to 999 999 999.

=cut

# }}}
# {{{ Functions reference

=pod

=head2 Functions Reference

=over

=item num2sv_cardinal (positional)

  1   number  number to convert
  =>  string  converted string
      undef   if input number is not known

Convert number to text representation.

=back

=cut

# }}}
# {{{ POD FOOTER

=head1 EXPORT_OK

num2sv_cardinal

=head1 AUTHOR

 coding, maintenance, refactoring, extensions, specifications:
   Richard C. Jelinek <info@petamem.com>
 initial coding after specifications by R. Jelinek:
   Vitor Serra Mori <info@petamem.com>

=head1 COPYRIGHT

Copyright (C) PetaMem, s.r.o. 2004-present

=head2 LICENSE

Artistic license or BSD license.

=cut

# }}}
