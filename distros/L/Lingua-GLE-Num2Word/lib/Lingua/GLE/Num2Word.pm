# For Emacs: -*- mode:cperl; eval: (folding-mode 1); coding:utf-8; -*-

package Lingua::GLE::Num2Word;
# ABSTRACT: This module converts numbers (cardinals) into their Irish (Gaeilge) equivalents using the modern decimal counting system. It accepts positive integers up to, but not including, 1 billion.

use 5.16.0;
use utf8;
use warnings;

# {{{ use block

use Carp;
use Export::Attrs;

# }}}
# {{{ variable declarations

our $VERSION = '0.2603270';

# Irish (Gaeilge) uses a decimal counting system in modern usage.
# The counting form uses the "a" prefix before unit digits.
# Going up to 999_999_999.

my @units = qw(náid a_haon a_dó a_trí a_ceathair a_cúig a_sé a_seacht a_hocht a_naoi);
my @tens  = (undef, 'a_deich', 'fiche', 'tríocha', 'daichead', 'caoga',
             'seasca', 'seachtó', 'ochtó', 'nócha');

# }}}

# {{{ num2gle_cardinal                 convert number to text

sub num2gle_cardinal :Export {
    my $num = shift;

    croak 'You should specify a number from interval [0, 999_999_999]'
        if    !defined $num
           || $num !~ m{\A\d+\z}xms
           || $num < 0
           || $num > 999_999_999;

    # Zero
    return 'náid' if $num == 0;

    my @parts;

    # Millions
    if ($num >= 1_000_000) {
        my $millions = int($num / 1_000_000);
        push @parts, _cardinal_below_1000($millions) if $millions > 1;
        push @parts, 'milliún';
        $num %= 1_000_000;
    }

    # Thousands
    if ($num >= 1000) {
        my $thousands = int($num / 1000);
        push @parts, _cardinal_below_1000($thousands) if $thousands > 1;
        push @parts, 'míle';
        $num %= 1000;
    }

    # Remainder below 1000
    if ($num > 0) {
        push @parts, _cardinal_below_1000($num);
    }

    my $result = join(' ', @parts);
    $result =~ s/_/ /g;
    return $result;
}

# }}}
# {{{ _cardinal_below_1000             internal: handle 1-999

sub _cardinal_below_1000 {
    my $num = shift;

    return if $num == 0;

    my @parts;

    # Hundreds
    if ($num >= 100) {
        my $h = int($num / 100);
        if ($h == 1) {
            push @parts, 'céad';
        }
        else {
            push @parts, $units[$h], 'céad';
        }
        $num %= 100;
    }

    # Tens and units
    if ($num > 0) {
        push @parts, _cardinal_below_100($num);
    }

    return @parts;
}

# }}}
# {{{ _cardinal_below_100              internal: handle 1-99

sub _cardinal_below_100 {
    my $num = shift;

    return if $num == 0;

    # 1-9: counting form
    if ($num < 10) {
        return $units[$num];
    }

    # 10: a deich
    if ($num == 10) {
        return 'a_deich';
    }

    # 11-19: unit + déag (12 uses dhéag)
    if ($num < 20) {
        my $u = $num - 10;
        my $deag = ($u == 2) ? 'dhéag' : 'déag';
        return $units[$u] . ' ' . $deag;
    }

    # 20-99
    my $t = int($num / 10);
    my $u = $num % 10;

    if ($u == 0) {
        return $tens[$t];
    }

    # tens + a + unit
    return $tens[$t] . ' ' . $units[$u];
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

# {{{ module documentation

=pod

=head1 NAME

Lingua::GLE::Num2Word - Number to word conversion in Irish (Gaeilge)

=head1 VERSION

version 0.2603270

Lingua::GLE::Num2Word is a module for converting numbers into their written
representation in Irish (Gaeilge). Converts whole numbers from 0 up to
999 999 999.

Text output is encoded in UTF-8.

=cut

# }}}
# {{{ SYNOPSIS

=pod

=head1 SYNOPSIS

 use Lingua::GLE::Num2Word;

 my $text = Lingua::GLE::Num2Word::num2gle_cardinal( 123 );
 print $text || "sorry, can't convert this number into Irish.";

=cut

# }}}
# {{{ Functions Reference

=pod

=head1 Functions Reference

=over 2

=item B<num2gle_cardinal> (positional)

  1   num    number to convert
  =>  str    converted string
      undef  if input number is not known

Convert number to Irish text representation.
Only numbers from interval [0, 999_999_999] will be converted.

=back

=cut

# }}}
# {{{ EXPORTED FUNCTIONS

=pod

=head1 EXPORT_OK

=over 2

=item num2gle_cardinal

=back

=cut

# }}}
# {{{ POD FOOTER

=pod

=head1 DESCRIPTION

This module converts numbers (cardinals) into their Irish (Gaeilge)
equivalents using the modern decimal counting system. It accepts positive
integers up to, but not including, 1 billion.

Irish uses the counting form with the "a" prefix before digits (e.g.,
"a haon" for 1, "a dó" for 2). Compound numbers are formed as
tens + unit (e.g., "tríocha a trí" for 33).

The module uses the standard modern counting forms without initial
consonant mutations (lenition/eclipsis).

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
