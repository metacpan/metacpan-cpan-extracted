# For Emacs: -*- mode:cperl; eval: (folding-mode 1); coding:utf-8 -*-

package Lingua::THA::Num2Word;
# ABSTRACT: Number to word conversion in Thai

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
our $VERSION = '0.2603270';

# }}}

# {{{ num2tha_cardinal                 convert number to text

sub num2tha_cardinal :Export {
    my $positive = shift;

    croak 'You should specify a number from interval [0, 999_999_999]'
        if    !defined $positive
           || $positive !~ m{\A\d+\z}xms
           || $positive < 0
           || $positive > 999_999_999;

    my @units = qw(ศูนย์ หนึ่ง สอง สาม สี่ ห้า หก เจ็ด แปด เก้า);

    return $units[$positive] if ($positive >= 0 && $positive <= 9);
    return 'สิบ'            if ($positive == 10);

    my $out = '';
    my $remain;

    # Helper: append remainder, substituting เอ็ด for bare หนึ่ง in compounds.
    # In Thai, the digit 1 in the units position of any compound number
    # is always เอ็ด (et), never หนึ่ง (nueng).
    my $append_remain = sub {
        my ($so_far, $r) = @_;
        if ($r == 1) {
            return $so_far . 'เอ็ด';
        }
        return $so_far . num2tha_cardinal($r);
    };

    if ($positive > 10 && $positive < 20) {                     # 11 .. 19
        $remain = $positive % 10;
        $out    = 'สิบ';
        $out   .= $remain == 1 ? 'เอ็ด' : $units[$remain];
    }
    elsif ($positive >= 20 && $positive < 100) {                # 20 .. 99
        my $tens = int($positive / 10);
        $remain  = $positive % 10;

        $out  = $tens == 2 ? 'ยี่' : $units[$tens];
        $out .= 'สิบ';
        if ($remain) {
            $out .= $remain == 1 ? 'เอ็ด' : $units[$remain];
        }
    }
    elsif ($positive >= 100 && $positive < 1000) {              # 100 .. 999
        my $hundreds = int($positive / 100);
        $remain      = $positive % 100;

        $out  = $units[$hundreds] . 'ร้อย';
        $out  = $append_remain->($out, $remain) if $remain;
    }
    elsif ($positive >= 1000 && $positive < 10_000) {           # 1_000 .. 9_999
        my $thousands = int($positive / 1000);
        $remain       = $positive % 1000;

        $out  = $units[$thousands] . 'พัน';
        $out  = $append_remain->($out, $remain) if $remain;
    }
    elsif ($positive >= 10_000 && $positive < 100_000) {        # 10_000 .. 99_999
        my $ten_thousands = int($positive / 10000);
        $remain           = $positive % 10000;

        $out  = $units[$ten_thousands] . 'หมื่น';
        $out  = $append_remain->($out, $remain) if $remain;
    }
    elsif ($positive >= 100_000 && $positive < 1_000_000) {     # 100_000 .. 999_999
        my $hundred_thousands = int($positive / 100000);
        $remain               = $positive % 100000;

        $out  = $units[$hundred_thousands] . 'แสน';
        $out  = $append_remain->($out, $remain) if $remain;
    }
    elsif ($positive >= 1_000_000 && $positive < 1_000_000_000) { # 1_000_000 .. 999_999_999
        my $millions = int($positive / 1_000_000);
        $remain      = $positive % 1_000_000;

        $out  = num2tha_cardinal($millions) . 'ล้าน';
        $out  = $append_remain->($out, $remain) if $remain;
    }

    return $out;
}

# }}}


# {{{ capabilities              declare supported features

sub capabilities {
    return {
        cardinal => 1,
        ordinal  => 0,
    };
}

# }}}
1;

__END__

# {{{ POD HEAD

=pod

=encoding utf-8

=head1 NAME

Lingua::THA::Num2Word - Number to word conversion in Thai


=head1 VERSION

version 0.2603270

Lingua::THA::Num2Word is module for converting numbers into their written
representation in Thai. Converts whole numbers from 0 up to 999 999 999.

Text is encoded in UTF-8.

=cut

# }}}
# {{{ SYNOPSIS

=pod

=head1 SYNOPSIS

 use Lingua::THA::Num2Word;

 my $text = Lingua::THA::Num2Word::num2tha_cardinal( 223 );

 print $text || "sorry, can't convert this number into Thai.";

=cut

# }}}
# {{{ Functions Reference

=pod

=head1 Functions Reference

=over 2

=item B<num2tha_cardinal> (positional)

  1   num    number to convert
  =>  str    converted string
      undef  if input number is not known

Convert number to text representation in Thai.
Only numbers from interval [0, 999_999_999] will be converted.

Thai has two special substitution rules:

=over 4

=item *

B<เอ็ด> (et) replaces B<หนึ่ง> (nueng) for the digit 1 in the units position
of any compound number (11, 21, 101, etc.).

=item *

B<ยี่> (yi) replaces B<สอง> (song) for the digit 2 in the tens position
(20-29 only).

=back

=back

=cut

# }}}
# {{{ EXPORTED FUNCTIONS

=pod

=head1 EXPORT_OK

=over 2

=item num2tha_cardinal

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
