# For Emacs: -*- mode:cperl; mode:folding; coding:utf-8; -*-

package Lingua::LIT::Num2Word;
# ABSTRACT: Number to word conversion in Lithuanian

use 5.16.0;
use utf8;
use warnings;

# {{{ use block

use Carp;
use Export::Attrs;

# }}}
# {{{ var block
our $VERSION = '0.2603300';
my %token1 = qw( 0 nulis          1 vienas         2 du
                 3 trys           4 keturi         5 penki
                 6 šeši           7 septyni        8 aštuoni
                 9 devyni         10 dešimt        11 vienuolika
                 12 dvylika       13 trylika       14 keturiolika
                 15 penkiolika    16 šešiolika     17 septyniolika
                 18 aštuoniolika  19 devyniolika
               );
my %token2 = qw( 20 dvidešimt          30 trisdešimt
                 40 keturiasdešimt      50 penkiasdešimt
                 60 šešiasdešimt        70 septyniasdešimt
                 80 aštuoniasdešimt     90 devyniasdešimt
               );

# }}}

# {{{ _decline                      choose singular/plural/genitive form

sub _decline {
    my ($count, $singular, $plural, $genitive) = @_;

    my $last_two = $count % 100;
    my $last_one = $count % 10;

    # teens (11-19) always take genitive plural
    if ($last_two >= 10 && $last_two <= 19) {
        return $genitive;
    }

    # last digit 1 => singular
    if ($last_one == 1) {
        return $singular;
    }

    # last digit 0 => genitive plural
    if ($last_one == 0) {
        return $genitive;
    }

    # last digit 2-9 => plural nominative
    return $plural;
}

# }}}
# {{{ _hundreds                     convert hundreds part

sub _hundreds {
    my ($number) = @_;

    my $h = int($number / 100);

    if ($h == 1) {
        return 'vienas šimtas';
    }

    return $token1{$h} . ' ' . _decline($h, 'šimtas', 'šimtai', 'šimtų');
}

# }}}
# {{{ num2lit_cardinal              number to string conversion

sub num2lit_cardinal :Export {
    my $result = '';
    my $number = shift;

    croak 'You should specify a number from interval [0, 999_999_999]'
        if    !defined $number
           || $number !~ m{\A\d+\z}xms
           || $number < 0
           || $number > 999_999_999;

    # 0-19
    if ($number < 20) {
        return $token1{$number};
    }

    # 20-99
    if ($number < 100) {
        my $remainder = $number % 10;
        $result = $token2{$number - $remainder};
        if ($remainder != 0) {
            $result .= ' ' . $token1{$remainder};
        }
        return $result;
    }

    # 100-999
    if ($number < 1_000) {
        my $remainder = $number % 100;
        $result = _hundreds($number);
        if ($remainder != 0) {
            $result .= ' ' . num2lit_cardinal($remainder);
        }
        return $result;
    }

    # 1_000-999_999
    if ($number < 1_000_000) {
        my $remainder = $number % 1_000;
        my $thousands = int($number / 1_000);
        my $suffix    = _decline($thousands, 'tūkstantis', 'tūkstančiai', 'tūkstančių');

        if ($thousands == 1) {
            $result = 'vienas tūkstantis';
        }
        elsif ($thousands < 20) {
            $result = $token1{$thousands} . ' ' . $suffix;
        }
        else {
            $result = num2lit_cardinal($thousands) . ' ' . $suffix;
        }

        if ($remainder != 0) {
            $result .= ' ' . num2lit_cardinal($remainder);
        }
        return $result;
    }

    # 1_000_000-999_999_999
    if ($number < 1_000_000_000) {
        my $remainder = $number % 1_000_000;
        my $millions  = int($number / 1_000_000);
        my $suffix    = _decline($millions, 'milijonas', 'milijonai', 'milijonų');

        if ($millions == 1) {
            $result = 'vienas milijonas';
        }
        elsif ($millions < 20) {
            $result = $token1{$millions} . ' ' . $suffix;
        }
        else {
            $result = num2lit_cardinal($millions) . ' ' . $suffix;
        }

        if ($remainder != 0) {
            $result .= ' ' . num2lit_cardinal($remainder);
        }
        return $result;
    }

    return $result;
}

# }}}


# {{{ num2lit_ordinal                  convert number to ordinal text

sub num2lit_ordinal :Export {
    my $number = shift;

    croak 'You should specify a number from interval [1, 999_999_999]'
        if    !defined $number
           || $number !~ m{\A\d+\z}xms
           || $number < 1
           || $number > 999_999_999;

    # Unique ordinal forms for 1-19 (masculine nominative singular)
    my %ordinals = (
        1  => 'pirmas',
        2  => 'antras',
        3  => 'trečias',
        4  => 'ketvirtas',
        5  => 'penktas',
        6  => 'šeštas',
        7  => 'septintas',
        8  => 'aštuntas',
        9  => 'devintas',
        10 => 'dešimtas',
        11 => 'vienuoliktas',
        12 => 'dvyliktas',
        13 => 'tryliktas',
        14 => 'keturioliktas',
        15 => 'penkioliktas',
        16 => 'šešioliktas',
        17 => 'septynioliktas',
        18 => 'aštuonioliktas',
        19 => 'devynioliktas',
    );

    return $ordinals{$number} if exists $ordinals{$number};

    # Round tens: ordinal tens forms
    my %ordinal_tens = (
        20 => 'dvidešimtas',
        30 => 'trisdešimtas',
        40 => 'keturiasdešimtas',
        50 => 'penkiasdešimtas',
        60 => 'šešiasdešimtas',
        70 => 'septyniasdešimtas',
        80 => 'aštuoniasdešimtas',
        90 => 'devyniasdešimtas',
    );

    return $ordinal_tens{$number} if exists $ordinal_tens{$number};

    # Compound 21-99: cardinal tens + ordinal unit
    if ($number > 20 && $number < 100) {
        my $remain = $number % 10;
        my $tens   = $number - $remain;
        return $token2{$tens} . ' ' . num2lit_ordinal($remain);
    }

    # Round hundreds
    if ($number >= 100 && $number < 1000 && $number % 100 == 0) {
        my $h = int($number / 100);
        if ($h == 1) {
            return 'šimtasis';
        }
        return $token1{$h} . ' šimtasis';
    }

    # Compound hundreds
    if ($number >= 100 && $number < 1000) {
        my $remain = $number % 100;
        return _hundreds($number) . ' ' . num2lit_ordinal($remain);
    }

    # Round thousands
    if ($number >= 1000 && $number < 1_000_000 && $number % 1000 == 0) {
        my $thousands = int($number / 1000);
        if ($thousands == 1) {
            return 'tūkstantasis';
        }
        return num2lit_cardinal($thousands) . ' tūkstantasis';
    }

    # Compound thousands
    if ($number >= 1000 && $number < 1_000_000) {
        my $thousands = int($number / 1000);
        my $remain    = $number % 1000;
        my $suffix    = _decline($thousands, 'tūkstantis', 'tūkstančiai', 'tūkstančių');

        my $prefix;
        if ($thousands == 1) {
            $prefix = 'vienas tūkstantis';
        }
        elsif ($thousands < 20) {
            $prefix = $token1{$thousands} . ' ' . $suffix;
        }
        else {
            $prefix = num2lit_cardinal($thousands) . ' ' . $suffix;
        }
        return $prefix . ' ' . num2lit_ordinal($remain);
    }

    # Round millions
    if ($number >= 1_000_000 && $number < 1_000_000_000 && $number % 1_000_000 == 0) {
        my $millions = int($number / 1_000_000);
        if ($millions == 1) {
            return 'milijonasis';
        }
        return num2lit_cardinal($millions) . ' milijonasis';
    }

    # Compound millions
    if ($number >= 1_000_000 && $number < 1_000_000_000) {
        my $millions = int($number / 1_000_000);
        my $remain   = $number % 1_000_000;
        my $suffix   = _decline($millions, 'milijonas', 'milijonai', 'milijonų');

        my $prefix;
        if ($millions == 1) {
            $prefix = 'vienas milijonas';
        }
        elsif ($millions < 20) {
            $prefix = $token1{$millions} . ' ' . $suffix;
        }
        else {
            $prefix = num2lit_cardinal($millions) . ' ' . $suffix;
        }
        return $prefix . ' ' . num2lit_ordinal($remain);
    }

    return;
}

# }}}

# {{{ capabilities              declare supported features

sub capabilities {
    return {
        cardinal => 1,
        ordinal  => 1,
    };
}

# }}}
1;

__END__

# {{{ POD HEAD

=pod

=encoding utf-8

=head1 NAME

Lingua::LIT::Num2Word - Number to word conversion in Lithuanian


=head1 VERSION

version 0.2603300

Lingua::LIT::Num2Word is module for conversion of numbers into their
representation in Lithuanian. It converts whole numbers from 0 up to
999 999 999.

=cut

# }}}
# {{{ SYNOPSIS

=pod

=head1 SYNOPSIS

 use Lingua::LIT::Num2Word;

 my $text = Lingua::LIT::Num2Word::num2lit_cardinal( 123 );

 print $text || "sorry, can't convert this number into Lithuanian.";

=cut

# }}}
# {{{ Functions Reference

=pod

=head1 Functions Reference

=over 2

=item B<num2lit_cardinal> (positional)

  1   num    number to convert
  =>  str    lexical representation of the input
      undef  if input number is not known

Convert number to text representation.
Only numbers from interval [0, 999_999_999] will
be converted.

=item B<_decline> (positional)

  1   num    the count to determine declension for
  2   str    singular form (last digit 1, not 11)
  3   str    plural nominative form (last digit 2-9, not 12-19)
  4   str    genitive plural form (last digit 0, or 10-19)
  =>  str    correct declension form

Internal helper. Selects the correct Lithuanian noun declension
based on the number.

=item B<num2lit_ordinal> (positional)

  1   num    number to convert
  =>  str    converted ordinal string (masculine nominative singular)

Convert number to its Lithuanian ordinal text representation.
Only numbers from interval [1, 999_999_999] will be converted.
Handles all unique ordinal forms (pirmas, antras, trečias, etc.).

=item B<_hundreds> (positional)

  1   num    number in range [100, 999]
  =>  str    hundreds part as text

Internal helper. Converts the hundreds component of a number to text.


=item B<capabilities> (void)

  =>  href   hashref indicating supported conversion types

Returns a hashref of capabilities for this language module.

=back

=cut

# }}}
# {{{ EXPORTED FUNCTIONS

=pod

=head1 EXPORT_OK

=over 2

=item num2lit_cardinal

=item num2lit_ordinal

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
