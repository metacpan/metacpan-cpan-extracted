# For Emacs: -*- mode:cperl; mode:folding; coding:utf-8 -*-

package Lingua::BEL::Num2Word;
# ABSTRACT: Number to word conversion in Belarusian

use 5.16.0;
use utf8;
use warnings;

# {{{ use block

use Carp;
use Export::Attrs;

# }}}
# {{{ var block
our $VERSION = '0.2603270';
my %token1 = (
     0 => 'нуль',
     1 => 'адзін',          2 => 'два',
     3 => 'тры',            4 => 'чатыры',
     5 => 'пяць',           6 => 'шэсць',
     7 => 'сем',            8 => 'восем',
     9 => 'дзевяць',       10 => 'дзесяць',
    11 => 'адзінаццаць',   12 => 'дванаццаць',
    13 => 'трынаццаць',    14 => 'чатырнаццаць',
    15 => 'пятнаццаць',    16 => 'шаснаццаць',
    17 => 'сямнаццаць',    18 => 'васямнаццаць',
    19 => 'дзевятнаццаць',
);
my %token2 = (
    20 => 'дваццаць',      30 => 'трыццаць',
    40 => 'сорак',         50 => 'пяцьдзясят',
    60 => 'шасцьдзясят',   70 => 'семдзесят',
    80 => 'васемдзесят',   90 => 'дзевяноста',
);
my %token3 = (
    100 => 'сто',          200 => 'дзвесце',
    300 => 'трыста',       400 => 'чатырыста',
    500 => 'пяцьсот',      600 => 'шасцьсот',
    700 => 'семсот',       800 => 'васемсот',
    900 => 'дзевяцьсот',
);

# }}}

# {{{ num2bel_cardinal           number to string conversion

sub num2bel_cardinal :Export {
    my $result = '';
    my $number = shift;

    croak 'You should specify a number from interval [0, 999_999_999]'
        if    !defined $number
           || $number !~ m{\A\d+\z}xms
           || $number < 0
           || $number > 999_999_999;

    my $reminder = 0;

    if ($number < 20) {
        $result = $token1{$number};
    }
    elsif ($number < 100) {
        $reminder = $number % 10;
        if ($reminder == 0) {
            $result = $token2{$number};
        }
        else {
            $result = $token2{$number - $reminder}.' '.num2bel_cardinal($reminder);
        }
    }
    elsif ($number < 1_000) {
        $reminder = $number % 100;
        if ($reminder != 0) {
            $result = $token3{$number - $reminder}.' '.num2bel_cardinal($reminder);
        }
        else {
            $result = $token3{$number};
        }
    }
    elsif ($number < 1_000_000) {
        $reminder = $number % 1_000;
        my $tmp1 = ($reminder != 0) ? ' '.num2bel_cardinal($reminder) : '';
        my $tmp2 = substr($number, 0, length($number)-3);
        my $tmp3 = $tmp2 % 100;
        my $tmp4 = $tmp2 % 10;

        if ($tmp3 < 9 || $tmp3 > 20) {
            if ($tmp4 == 1 && $tmp2 == 1) {
                $tmp2 = 'тысяча';
            }
            elsif ($tmp4 == 1) {
                $tmp2 = num2bel_cardinal($tmp2 - $tmp4).' адна тысяча';
            }
            elsif ($tmp4 == 2 && $tmp2 == 2) {
                $tmp2 = 'дзве тысячы';
            }
            elsif ($tmp4 == 2) {
                $tmp2 = num2bel_cardinal($tmp2 - $tmp4).' дзве тысячы';
            }
            elsif ($tmp4 > 2 && $tmp4 < 5) {
                $tmp2 = num2bel_cardinal($tmp2).' тысячы';
            }
            else {
                $tmp2 = num2bel_cardinal($tmp2).' тысяч';
            }
        }
        else {
            $tmp2 = num2bel_cardinal($tmp2).' тысяч';
        }
        $result = $tmp2.$tmp1;
    }
    elsif ($number < 1_000_000_000) {
        $reminder = $number % 1_000_000;
        my $tmp1 = ($reminder != 0) ? ' '.num2bel_cardinal($reminder) : '';
        my $tmp2 = substr($number, 0, length($number)-6);
        my $tmp3 = $tmp2 % 100;
        my $tmp4 = $tmp2 % 10;

        if ($tmp3 < 9 || $tmp3 > 20) {
            if ($tmp4 == 1 && $tmp2 == 1) {
                $tmp2 = 'мільён';
            }
            elsif ($tmp4 == 1) {
                $tmp2 = num2bel_cardinal($tmp2 - $tmp4).' адзін мільён';
            }
            elsif ($tmp4 > 1 && $tmp4 < 5) {
                $tmp2 = num2bel_cardinal($tmp2).' мільёны';
            }
            else {
                $tmp2 = num2bel_cardinal($tmp2).' мільёнаў';
            }
        }
        else {
            $tmp2 = num2bel_cardinal($tmp2).' мільёнаў';
        }

        $result = $tmp2.$tmp1;
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

Lingua::BEL::Num2Word - Number to word conversion in Belarusian


=head1 VERSION

version 0.2603270

Lingua::BEL::Num2Word is module for conversion numbers into their representation
in Belarusian. It converts whole numbers from 0 up to 999 999 999.

=cut

# }}}
# {{{ SYNOPSIS

=pod

=head1 SYNOPSIS

 use Lingua::BEL::Num2Word;

 my $text = Lingua::BEL::Num2Word::num2bel_cardinal( 123 );

 print $text || "sorry, can't convert this number into belarusian language.";

=cut

# }}}
# {{{ Functions Reference

=pod

=head1 Functions Reference

=over 2

=item B<num2bel_cardinal> (positional)

  1   num    number to convert
  =>  str    lexical representation of the input
      undef  if input number is not known

Convert number to text representation.
Only numbers from interval [0, 999_999_999] will
be converted.

=back

=cut

# }}}
# {{{ EXPORTED FUNCTIONS

=pod

=head1 EXPORT_OK

=over 2

=item num2bel_cardinal

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
