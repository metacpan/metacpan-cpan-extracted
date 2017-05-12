# For Emacs: -*- mode:cperl; mode:folding coding:iso-8859-1 -*-
#
# Started by Vitor Serra Mori at 2004-05-19
#
# PPCG: 0.7

package Lingua::SV::Num2Word;

use strict;

BEGIN {
  use Exporter ();
  use vars qw($VERSION @ISA @EXPORT_OK);
  $VERSION   = '0.05';
  @ISA       = qw(Exporter);
  @EXPORT_OK = qw(&num2sv_cardinal);
}

# {{{ num2sv_cardinal                 convert number to text
#
sub num2sv_cardinal {
  my $positive = ($_[0]>=0) ? shift : return;
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

# {{{ module documentation

=head1 NAME

Lingua::SV::Num2Word - positive number to text convertor for swedish. Output
text is in iso-8859-1 encoding.

=head1 SYNOPSIS

 use Lingua::SV::Num2Word;

 my $text = Lingua::SV::Num2Word::num2sv_cardinal( 123 );

 print $text || "sorry, can't convert this number into swedish language.";

=head1 DESCRIPTION

Lingua::SV::Num2Word is module for converting numbers into their representation
in swedish. Converts whole numbers from 0 up to 999 999 999.

=head2 Functions

=over

=item * num2sv_cardinal(number)

Convert number to text representation.

=back

=head1 EXPORT_OK

num2sv_cardinal

=head1 KNOWN BUGS

None.

=head1 AUTHOR

Vitor Serra Mori E<lt>info@petamem.com.E<gt>

=head1 COPYRIGHT

Copyright (c) 2004 PetaMem s.r.o.

This package is free software. Tou can redistribute and/or modify it under
the same terms as Perl itself.

=cut

# }}}


