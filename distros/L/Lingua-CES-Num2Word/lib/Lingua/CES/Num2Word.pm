# For Emacs: -*- mode:cperl; mode:folding; coding:utf-8; -*-

package Lingua::CES::Num2Word;
# ABSTRACT: Number 2 word conversion in CES.

# {{{ use block

use 5.10.1;

use strict;
use warnings;
use utf8;

use Carp;
use Perl6::Export::Attrs;

# }}}
# {{{ BEGIN

our $VERSION  = 0.1106;
our $REVISION = '$Rev: 1106 $';

# }}}
# {{{ variables

my %token1 = qw( 0 nula         1 jedna         2 dva
                 3 tři          4 čtyři         5 pět
                 6 šest         7 sedm          8 osm
                 9 devět        10 deset        11 jedenáct
                 12 dvanáct     13 třináct      14 čtrnáct
                 15 patnáct     16 šestnáct     17 sedmnáct
                 18 osmnáct     19 devatenáct
               );
my %token2 = qw( 20 dvacet      30 třicet       40 čtyřicet
                 50 padesát     60 šedesát      70 sedmdesát
                 80 osmdesát    90 devadesát
               );
my %token3 = (  100, 'sto', 200, 'dvě stě',   300, 'tři sta',
                400, 'čtyři sta', 500, 'pět set',   600, 'šest set',
                700, 'sedm set',  800, 'osm set',   900, 'devět set'
             );

# }}}

# {{{ num2ces_cardinal           number to string conversion

sub num2ces_cardinal :Export {
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
            $result = $token2{$number - $reminder}.' '.num2ces_cardinal($reminder);
        }
    }
    elsif ($number < 1_000) {
        $reminder = $number % 100;
        if ($reminder != 0) {
            $result = $token3{$number - $reminder}.' '.num2ces_cardinal($reminder);
        }
        else {
            $result = $token3{$number};
        }
    }
    elsif ($number < 1_000_000) {
        $reminder = $number % 1_000;
        my $tmp1 = ($reminder != 0) ? ' '.num2ces_cardinal($reminder) : '';
        my $tmp2 = substr($number, 0, length($number)-3);
        my $tmp3 = $tmp2 % 100;
        my $tmp4 = $tmp2 % 10;

        if ($tmp3 < 9 || $tmp3 > 20) {
            if ($tmp4 == 1 && $tmp2 == 1) {
                $tmp2 = 'tisíc';
            }
            elsif ($tmp4 == 1) {
                $tmp2 = num2ces_cardinal($tmp2 - $tmp4).' jeden tisíc';
            }
            elsif($tmp4 > 1 && $tmp4 < 5) {
                $tmp2 = num2ces_cardinal($tmp2).' tisíce';
            }
            else {
                $tmp2 = num2ces_cardinal($tmp2).' tisíc';
            }
        }
        else {
            $tmp2 = num2ces_cardinal($tmp2).' tisíc';
        }
        $result = $tmp2.$tmp1;
    }
    elsif ($number < 1_000_000_000) {
        $reminder = $number % 1_000_000;
        my $tmp1 = ($reminder != 0) ? ' '.num2ces_cardinal($reminder) : '';
        my $tmp2 = substr($number, 0, length($number)-6);
        my $tmp3 = $tmp2 % 100;
        my $tmp4 = $tmp2 % 10;

        if ($tmp3 < 9 || $tmp3 > 20) {
            if ($tmp4 == 1 && $tmp2 == 1) {
                $tmp2 = 'milion';
            }
            elsif ($tmp4 == 1) {
                $tmp2 = num2ces_cardinal($tmp2 - $tmp4).' jeden milion';
            }
            elsif($tmp4 > 1 && $tmp4 < 5) {
                $tmp2 = num2ces_cardinal($tmp2).' miliony';
            }
            else {
                $tmp2 = num2ces_cardinal($tmp2).' milionů';
            }
        }
        else {
            $tmp2 = num2ces_cardinal($tmp2).' milionů';
        }

        $result = $tmp2.$tmp1;
    }

    return $result;
}

# }}}

1;

__END__

# {{{ POD HEAD

=pod

=head1 NAME

=head2 Lingua::CES::Num2Word 

=head1 VERSION

version 0.1106

Number 2 word conversion in CES.

Lingua::CES::Num2Word is module for conversion numbers into their representation
in Czech. It converts whole numbers from 0 up to 999 999 999.

=cut

# }}}
# {{{ SYNOPSIS

=pod

=head1 SYNOPSIS

 use Lingua::CES::Num2Word;

 my $text = Lingua::CES::Num2Word::num2ces_cardinal( 123 );

 print $text || "sorry, can't convert this number into czech language.";

=cut

# }}}
# {{{ Functions Reference

=pod

=head1 Functions Reference

=over 2

=item B<num2ces_cardinal> (positional)

  1   number  number to convert
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

=item num2ces_cardinal


=back

=cut

# }}}
# {{{ POD FOOTER

=pod

=head1 AUTHOR

 coding, maintenance, refactoring, extensions, specifications:

   Roman Vasicek <info@petamem.com>

=head1 COPYRIGHT

Copyright (C) PetaMem, s.r.o. 2004-present

=cut

# }}}
