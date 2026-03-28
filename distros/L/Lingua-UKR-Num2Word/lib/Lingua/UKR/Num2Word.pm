# For Emacs: -*- mode:cperl; mode:folding; coding:utf-8 -*-

package Lingua::UKR::Num2Word;
# ABSTRACT: Number to word conversion in Ukrainian

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
     1 => 'один',          2 => 'два',
     3 => 'три',           4 => 'чотири',
     5 => "п'ять",         6 => 'шість',
     7 => 'сім',           8 => 'вісім',
     9 => "дев'ять",      10 => 'десять',
    11 => 'одинадцять',   12 => 'дванадцять',
    13 => 'тринадцять',   14 => 'чотирнадцять',
    15 => "п'ятнадцять",  16 => 'шістнадцять',
    17 => 'сімнадцять',   18 => 'вісімнадцять',
    19 => "дев'ятнадцять",
);
my %token2 = (
    20 => 'двадцять',     30 => 'тридцять',
    40 => 'сорок',        50 => "п'ятдесят",
    60 => 'шістдесят',    70 => 'сімдесят',
    80 => 'вісімдесят',   90 => "дев'яносто",
);
my %token3 = (
    100 => 'сто',         200 => 'двісті',
    300 => 'триста',      400 => 'чотириста',
    500 => "п'ятсот",     600 => 'шістсот',
    700 => 'сімсот',      800 => 'вісімсот',
    900 => "дев'ятсот",
);

# }}}

# {{{ num2ukr_cardinal           number to string conversion

sub num2ukr_cardinal :Export {
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
            $result = $token2{$number - $reminder}.' '.num2ukr_cardinal($reminder);
        }
    }
    elsif ($number < 1_000) {
        $reminder = $number % 100;
        if ($reminder != 0) {
            $result = $token3{$number - $reminder}.' '.num2ukr_cardinal($reminder);
        }
        else {
            $result = $token3{$number};
        }
    }
    elsif ($number < 1_000_000) {
        $reminder = $number % 1_000;
        my $tmp1 = ($reminder != 0) ? ' '.num2ukr_cardinal($reminder) : '';
        my $tmp2 = substr($number, 0, length($number)-3);
        my $tmp3 = $tmp2 % 100;
        my $tmp4 = $tmp2 % 10;

        if ($tmp3 < 9 || $tmp3 > 20) {
            if ($tmp4 == 1 && $tmp2 == 1) {
                $tmp2 = 'тисяча';
            }
            elsif ($tmp4 == 1) {
                $tmp2 = num2ukr_cardinal($tmp2 - $tmp4).' одна тисяча';
            }
            elsif ($tmp4 == 2 && $tmp2 == 2) {
                $tmp2 = 'дві тисячі';
            }
            elsif ($tmp4 == 2) {
                $tmp2 = num2ukr_cardinal($tmp2 - $tmp4).' дві тисячі';
            }
            elsif ($tmp4 > 2 && $tmp4 < 5) {
                $tmp2 = num2ukr_cardinal($tmp2).' тисячі';
            }
            else {
                $tmp2 = num2ukr_cardinal($tmp2).' тисяч';
            }
        }
        else {
            $tmp2 = num2ukr_cardinal($tmp2).' тисяч';
        }
        $result = $tmp2.$tmp1;
    }
    elsif ($number < 1_000_000_000) {
        $reminder = $number % 1_000_000;
        my $tmp1 = ($reminder != 0) ? ' '.num2ukr_cardinal($reminder) : '';
        my $tmp2 = substr($number, 0, length($number)-6);
        my $tmp3 = $tmp2 % 100;
        my $tmp4 = $tmp2 % 10;

        if ($tmp3 < 9 || $tmp3 > 20) {
            if ($tmp4 == 1 && $tmp2 == 1) {
                $tmp2 = 'мільйон';
            }
            elsif ($tmp4 == 1) {
                $tmp2 = num2ukr_cardinal($tmp2 - $tmp4).' один мільйон';
            }
            elsif ($tmp4 > 1 && $tmp4 < 5) {
                $tmp2 = num2ukr_cardinal($tmp2).' мільйони';
            }
            else {
                $tmp2 = num2ukr_cardinal($tmp2).' мільйонів';
            }
        }
        else {
            $tmp2 = num2ukr_cardinal($tmp2).' мільйонів';
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

Lingua::UKR::Num2Word - Number to word conversion in Ukrainian


=head1 VERSION

version 0.2603270

Lingua::UKR::Num2Word is module for conversion numbers into their representation
in Ukrainian. It converts whole numbers from 0 up to 999 999 999.

=cut

# }}}
# {{{ SYNOPSIS

=pod

=head1 SYNOPSIS

 use Lingua::UKR::Num2Word;

 my $text = Lingua::UKR::Num2Word::num2ukr_cardinal( 123 );

 print $text || "sorry, can't convert this number into ukrainian language.";

=cut

# }}}
# {{{ Functions Reference

=pod

=head1 Functions Reference

=over 2

=item B<num2ukr_cardinal> (positional)

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

=item num2ukr_cardinal

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
