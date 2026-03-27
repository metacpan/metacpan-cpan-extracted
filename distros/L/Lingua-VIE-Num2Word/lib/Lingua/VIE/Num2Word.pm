# For Emacs: -*- mode:cperl; eval: (folding-mode 1); coding:utf-8 -*-
package Lingua::VIE::Num2Word;
# ABSTRACT: Number to word conversion in Vietnamese

use 5.16.0;
use utf8;
use warnings;

# {{{ use block

use Carp;
use Export::Attrs;
use Readonly;

# }}}
# {{{ variable declarations

my Readonly::Scalar $COPY = 'Copyright (c) PetaMem, s.r.o. 2002-present';
our $VERSION = '0.2603260';

# }}}

# {{{ num2vie_cardinal                 convert number to text

sub num2vie_cardinal :Export {
    my $positive = shift;

    croak 'You should specify a number from interval [0, 999_999_999]'
        if    !defined $positive
           || $positive !~ m{\A\d+\z}xms
           || $positive < 0
           || $positive > 999_999_999;

    my @units = qw(không một hai ba bốn năm sáu bảy tám chín);

    return $units[$positive] if ($positive >= 0 && $positive < 10);   # 0 .. 9
    return 'mười'            if ($positive == 10);                     # 10

    # 11 .. 19
    if ($positive > 10 && $positive < 20) {
        my $unit = $positive % 10;
        return 'mười'
             . ($unit == 5 ? ' lăm'
              : $unit == 4 ? ' bốn'
              :              ' ' . $units[$unit]);
    }

    my $out;
    my $remain;

    # 20 .. 99
    if ($positive > 19 && $positive < 100) {
        my $tens = int($positive / 10);
        $remain  = $positive % 10;

        $out = $units[$tens] . ' mươi';
        if ($remain == 0) {
            # nothing
        }
        elsif ($remain == 1) {
            $out .= ' mốt';
        }
        elsif ($remain == 5) {
            $out .= ' lăm';
        }
        elsif ($remain == 4) {
            $out .= ' tư';
        }
        else {
            $out .= ' ' . $units[$remain];
        }
    }
    # 100 .. 999
    elsif ($positive > 99 && $positive < 1000) {
        my $hundreds = int($positive / 100);
        $remain      = $positive % 100;

        $out = $units[$hundreds] . ' trăm';
        if ($remain > 0 && $remain < 10) {
            $out .= ' lẻ ' . $units[$remain];
        }
        elsif ($remain >= 10) {
            $out .= ' ' . num2vie_cardinal($remain);
        }
    }
    # 1_000 .. 999_999
    elsif ($positive > 999 && $positive < 1_000_000) {
        my $thousands = int($positive / 1000);
        $remain       = $positive % 1000;

        $out = num2vie_cardinal($thousands) . ' nghìn';
        if ($remain > 0 && $remain < 10) {
            $out .= ' không trăm lẻ ' . $units[$remain];
        }
        elsif ($remain >= 10 && $remain < 100) {
            $out .= ' không trăm ' . num2vie_cardinal($remain);
        }
        elsif ($remain >= 100) {
            $out .= ' ' . num2vie_cardinal($remain);
        }
    }
    # 1_000_000 .. 999_999_999
    elsif ($positive > 999_999 && $positive < 1_000_000_000) {
        my $millions = int($positive / 1_000_000);
        $remain      = $positive % 1_000_000;

        $out = num2vie_cardinal($millions) . ' triệu';
        if ($remain > 0 && $remain < 1000) {
            # e.g. 1_000_005 -> một triệu không nghìn không trăm lẻ năm
            my $sub_hundreds = $remain % 100;
            my $sub_tens     = int($remain / 100);
            $out .= ' không nghìn';
            if ($sub_tens == 0 && $sub_hundreds > 0 && $sub_hundreds < 10) {
                $out .= ' không trăm lẻ ' . $units[$sub_hundreds];
            }
            elsif ($sub_tens == 0 && $sub_hundreds >= 10) {
                $out .= ' không trăm ' . num2vie_cardinal($sub_hundreds);
            }
            elsif ($sub_tens > 0) {
                $out .= ' ' . num2vie_cardinal($remain);
            }
        }
        elsif ($remain >= 1000) {
            $out .= ' ' . num2vie_cardinal($remain);
        }
    }

    return $out;
}

# }}}

1;

__END__

# {{{ POD HEAD

=pod

=encoding utf-8

=head1 NAME

Lingua::VIE::Num2Word - Number to word conversion in Vietnamese


=head1 VERSION

version 0.2603260

Lingua::VIE::Num2Word is module for converting numbers into their written
representation in Vietnamese. Converts whole numbers from 0 up to 999 999 999.

Text output is encoded in UTF-8.

=cut

# }}}
# {{{ SYNOPSIS

=pod

=head1 SYNOPSIS

 use Lingua::VIE::Num2Word;

 my $text = Lingua::VIE::Num2Word::num2vie_cardinal( 123 );

 print $text || "sorry, can't convert this number into Vietnamese.";

=cut

# }}}
# {{{ Functions Reference

=pod

=head1 Functions Reference

=over 2

=item B<num2vie_cardinal> (positional)

  1   num    number to convert
  =>  str    converted string
      undef  if input number is not known

Convert number to text representation.
Only numbers from interval [0, 999_999_999] will be converted.

=back

=cut

# }}}
# {{{ EXPORTED FUNCTIONS

=pod

=head1 EXPORT_OK

=over 2

=item num2vie_cardinal

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

Copyright (c) PetaMem, s.r.o. 2002-present

=head1 LICENSE

This module is free software; you can redistribute it and/or modify it
under the same terms as the Artistic License 2.0 or the BSD 2-Clause
License. See the LICENSE file in the distribution for details.

=cut

# }}}
