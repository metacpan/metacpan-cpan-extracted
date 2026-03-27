# For Emacs: -*- mode:cperl; eval: (folding-mode 1); -*-

package Lingua::SWE::Num2Word;
# ABSTRACT: Number to word conversion in Swedish

use 5.16.0;
use utf8;
use warnings;

# {{{ use block

use Export::Attrs;

# }}}
# {{{ variables declaration
our $VERSION = '0.2603260';

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

=pod

=head1 NAME

Lingua::SWE::Num2Word - Number to word conversion in Swedish


=head1 VERSION

version 0.2603260

Lingua::SWE::Num2Word is module for converting numbers into their representation
in Swedish. Converts whole numbers from 0 up to 999 999 999.

Output text is encoded in UTF-8 encoding.

=cut

# }}}
# {{{ SYNOPSIS

=pod

=head1 SYNOPSIS

 use Lingua::SWE::Num2Word;

 my $text = Lingua::SWE::Num2Word::num2sv_cardinal( 123 );

 print $text || "sorry, can't convert this number into swedish language.";

=cut

# }}}
# {{{ Functions Reference

=pod

=head1 Functions Reference

=over 2

=item B<num2sv_cardinal> (positional)

  1   num    number to convert
  =>  str    converted string
  =>  undef  if input number is not known

Convert number to text representation.

=back

=cut

# }}}
# {{{ EXPORTED FUNCTIONS

=pod

=head1 EXPORT_OK

=over 2

=item num2sv_cardinal

=back

=cut

# }}}
# {{{ POD FOOTER

=pod

=head1 AUTHORS

 specification, maintenance:
   Richard C. Jelinek E<lt>rj@petamem.comE<gt>
 maintenance, coding (2025-present):
   PetaMem AI Coding Agents

=head1 COPYRIGHT

Copyright (c) PetaMem, s.r.o. 2004-present

=head1 LICENSE

This module is free software; you can redistribute it and/or modify it
under the same terms as the Artistic License 2.0 or the BSD 2-Clause
License. See the LICENSE file in the distribution for details.

=cut

# }}}
