# For Emacs: -*- mode:cperl; mode:folding; coding:utf-8; -*-

package Lingua::BUL::Num2Word;
# ABSTRACT: Number to word conversion in Bulgarian

use 5.16.0;
use utf8;
use warnings;

# {{{ use block

use Carp;
use Export::Attrs;

# }}}
# {{{ var block
our $VERSION = '0.2603260';

my %token1 = qw( 0 нула          1 едно          2 две
                  3 три           4 четири        5 пет
                  6 шест          7 седем         8 осем
                  9 девет         10 десет        11 единадесет
                  12 дванадесет   13 тринадесет   14 четиринадесет
                  15 петнадесет   16 шестнадесет  17 седемнадесет
                  18 осемнадесет  19 деветнадесет
                );
my %token2 = qw( 20 двадесет     30 тридесет     40 четиридесет
                  50 петдесет     60 шестдесет    70 седемдесет
                  80 осемдесет    90 деветдесет
                );
my %token3 = (  100, 'сто',            200, 'двеста',        300, 'триста',
                400, 'четиристотин',    500, 'петстотин',     600, 'шестстотин',
                700, 'седемстотин',     800, 'осемстотин',    900, 'деветстотин'
             );

# }}}

# {{{ _num_to_words                    internal: convert 1-999 to words

sub _num_to_words {
    my ($number) = @_;

    return $token1{$number} if exists $token1{$number};

    if ($number < 100) {
        my $rem = $number % 10;
        if ($rem == 0) {
            return $token2{$number};
        }
        return $token2{$number - $rem} . ' и ' . $token1{$rem};
    }

    my $hund_rem = $number % 100;
    my $hund_val = $number - $hund_rem;

    if ($hund_rem == 0) {
        return $token3{$hund_val};
    }

    # hundreds + remainder: "и" goes before the last component
    # 101 = сто и едно,  120 = сто и двадесет,  123 = сто двадесет и три
    my $tens_rem = $hund_rem % 10;
    if ($hund_rem < 20 || $tens_rem == 0) {
        # single component remainder: hundred "и" remainder
        return $token3{$hund_val} . ' и ' . _num_to_words($hund_rem);
    }

    # two-component remainder (e.g. 23): hundred tens "и" unit
    return $token3{$hund_val} . ' ' . $token2{$hund_rem - $tens_rem} . ' и ' . $token1{$tens_rem};
}

# }}}

# {{{ num2bul_cardinal                 number to string conversion

sub num2bul_cardinal :Export {
    my $number = shift;

    croak 'You should specify a number from interval [0, 999_999_999]'
        if    !defined $number
           || $number !~ m{\A\d+\z}xms
           || $number < 0
           || $number > 999_999_999;

    return $token1{0} if $number == 0;

    my $result = '';

    # {{{ millions
    if ($number >= 1_000_000) {
        my $millions = int($number / 1_000_000);
        $number %= 1_000_000;

        if ($millions == 1) {
            $result = 'един милион';
        }
        elsif ($millions == 2) {
            $result = 'два милиона';
        }
        else {
            $result = _num_to_words($millions) . ' милиона';
        }
    }
    # }}}

    # {{{ thousands
    if ($number >= 1_000) {
        my $thousands = int($number / 1_000);
        $number %= 1_000;

        $result .= ' ' if $result ne '';

        if ($thousands == 1) {
            $result .= 'хиляда';
        }
        elsif ($thousands == 2) {
            $result .= 'две хиляди';
        }
        else {
            $result .= _num_to_words($thousands) . ' хиляди';
        }
    }
    # }}}

    # {{{ remainder (0-999)
    if ($number > 0) {
        if ($result ne '') {
            # "и" before remainder when there is no compound hundreds group:
            # i.e. remainder < 100 (no hundreds at all) or round hundreds (100,200,...,900)
            if ($number < 100 || $number % 100 == 0) {
                $result .= ' и ' . _num_to_words($number);
            }
            else {
                $result .= ' ' . _num_to_words($number);
            }
        }
        else {
            $result = _num_to_words($number);
        }
    }
    # }}}

    return $result;
}

# }}}

1;

__END__

# {{{ POD HEAD

=pod

=encoding utf-8

=head1 NAME

Lingua::BUL::Num2Word - Number to word conversion in Bulgarian


=head1 VERSION

version 0.2603260

Lingua::BUL::Num2Word is module for conversion numbers into their representation
in Bulgarian. It converts whole numbers from 0 up to 999 999 999.

=cut

# }}}
# {{{ SYNOPSIS

=pod

=head1 SYNOPSIS

 use Lingua::BUL::Num2Word;

 my $text = Lingua::BUL::Num2Word::num2bul_cardinal( 123 );

 print $text || "sorry, can't convert this number into bulgarian language.";

=cut

# }}}
# {{{ Functions Reference

=pod

=head1 Functions Reference

=over 2

=item B<num2bul_cardinal> (positional)

  1   num    number to convert
  =>  str    lexical representation of the input
      undef  if input number is not known

Convert number to text representation.
Only numbers from interval [0, 999_999_999] will
be converted.

=item B<_num_to_words> (positional)

  1   num    number (1-999)
  =>  str    Bulgarian text for that number

Internal helper for converting numbers 1-999 to words.

=back

=cut

# }}}
# {{{ EXPORTED FUNCTIONS

=pod

=head1 EXPORT_OK

=over 2

=item num2bul_cardinal

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
