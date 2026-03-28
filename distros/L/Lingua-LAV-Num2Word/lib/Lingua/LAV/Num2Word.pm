# For Emacs: -*- mode:cperl; mode:folding; coding:utf-8; -*-

package Lingua::LAV::Num2Word;
# ABSTRACT: Number to word conversion in Latvian

use 5.16.0;
use utf8;
use warnings;

# {{{ use block

use Carp;
use Export::Attrs;

# }}}
# {{{ var block
our $VERSION = '0.2603270';
my %token1 = qw( 0 nulle           1 viens          2 divi
                 3 trīs            4 četri          5 pieci
                 6 seši            7 septiņi        8 astoņi
                 9 deviņi          10 desmit         11 vienpadsmit
                 12 divpadsmit     13 trīspadsmit   14 četrpadsmit
                 15 piecpadsmit    16 sešpadsmit     17 septiņpadsmit
                 18 astoņpadsmit   19 deviņpadsmit
               );
my %token2 = qw( 20 divdesmit          30 trīsdesmit
                 40 četrdesmit          50 piecdesmit
                 60 sešdesmit           70 septiņdesmit
                 80 astoņdesmit         90 deviņdesmit
               );

# }}}

# {{{ _decline                      choose singular/plural form

sub _decline {
    my ($count, $singular, $plural) = @_;

    my $last_two = $count % 100;
    my $last_one = $count % 10;

    # teens (11-19) always take plural
    if ($last_two >= 11 && $last_two <= 19) {
        return $plural;
    }

    # last digit 1 => singular
    if ($last_one == 1) {
        return $singular;
    }

    # everything else => plural
    return $plural;
}

# }}}
# {{{ _hundreds                     convert hundreds part

sub _hundreds {
    my ($number) = @_;

    my $h = int($number / 100);

    if ($h == 1) {
        return 'simts';
    }

    return $token1{$h} . ' ' . _decline($h, 'simts', 'simti');
}

# }}}
# {{{ num2lav_cardinal              number to string conversion

sub num2lav_cardinal :Export {
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
            $result .= ' ' . num2lav_cardinal($remainder);
        }
        return $result;
    }

    # 1_000-999_999
    if ($number < 1_000_000) {
        my $remainder = $number % 1_000;
        my $thousands = int($number / 1_000);
        my $suffix    = _decline($thousands, 'tūkstotis', 'tūkstoši');

        if ($thousands == 1) {
            $result = 'viens tūkstotis';
        }
        elsif ($thousands < 20) {
            $result = $token1{$thousands} . ' ' . $suffix;
        }
        else {
            $result = num2lav_cardinal($thousands) . ' ' . $suffix;
        }

        if ($remainder != 0) {
            $result .= ' ' . num2lav_cardinal($remainder);
        }
        return $result;
    }

    # 1_000_000-999_999_999
    if ($number < 1_000_000_000) {
        my $remainder = $number % 1_000_000;
        my $millions  = int($number / 1_000_000);
        my $suffix    = _decline($millions, 'miljons', 'miljoni');

        if ($millions == 1) {
            $result = 'viens miljons';
        }
        elsif ($millions < 20) {
            $result = $token1{$millions} . ' ' . $suffix;
        }
        else {
            $result = num2lav_cardinal($millions) . ' ' . $suffix;
        }

        if ($remainder != 0) {
            $result .= ' ' . num2lav_cardinal($remainder);
        }
        return $result;
    }

    return $result;
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

Lingua::LAV::Num2Word - Number to word conversion in Latvian


=head1 VERSION

version 0.2603270

Lingua::LAV::Num2Word is module for conversion of numbers into their
representation in Latvian. It converts whole numbers from 0 up to
999 999 999.

=cut

# }}}
# {{{ SYNOPSIS

=pod

=head1 SYNOPSIS

 use Lingua::LAV::Num2Word;

 my $text = Lingua::LAV::Num2Word::num2lav_cardinal( 123 );

 print $text || "sorry, can't convert this number into Latvian.";

=cut

# }}}
# {{{ Functions Reference

=pod

=head1 Functions Reference

=over 2

=item B<num2lav_cardinal> (positional)

  1   num    number to convert
  =>  str    lexical representation of the input
      undef  if input number is not known

Convert number to text representation.
Only numbers from interval [0, 999_999_999] will
be converted.

=item B<_decline> (positional)

  1   num    the count to determine declension for
  2   str    singular form (last digit 1, not 11)
  3   str    plural form (all other cases)
  =>  str    correct declension form

Internal helper. Selects the correct Latvian noun declension
based on the number.

=item B<_hundreds> (positional)

  1   num    number in range [100, 999]
  =>  str    hundreds part as text

Internal helper. Converts the hundreds component of a number to text.

=back

=cut

# }}}
# {{{ EXPORTED FUNCTIONS

=pod

=head1 EXPORT_OK

=over 2

=item num2lav_cardinal

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
