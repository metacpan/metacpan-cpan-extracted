# For Emacs: -*- mode:cperl; mode:folding; coding:utf-8; -*-

package Lingua::SLV::Num2Word;
# ABSTRACT: Number to word conversion in Slovenian

use 5.16.0;
use utf8;
use warnings;

# {{{ use block

use Carp;
use Export::Attrs;

# }}}
# {{{ var block
our $VERSION = '0.2603270';
my %token1 = qw( 0 nič            1 ena            2 dva
                 3 tri            4 štiri          5 pet
                 6 šest           7 sedem          8 osem
                 9 devet          10 deset          11 enajst
                 12 dvanajst      13 trinajst       14 štirinajst
                 15 petnajst      16 šestnajst      17 sedemnajst
                 18 osemnajst     19 devetnajst
               );
my %token2 = qw( 20 dvajset       30 trideset       40 štirideset
                 50 petdeset      60 šestdeset      70 sedemdeset
                 80 osemdeset     90 devetdeset
               );
my %token3 = ( 100, 'sto',        200, 'dvesto',     300, 'tristo',
               400, 'štiristo',   500, 'petsto',     600, 'šeststo',
               700, 'sedemsto',   800, 'osemsto',    900, 'devetsto'
            );

# }}}

# {{{ num2slv_cardinal           number to string conversion

sub num2slv_cardinal :Export {
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
            # Slovenian: units + "in" + tens (like German)
            $result = $token1{$reminder}.'in'.$token2{$number - $reminder};
        }
    }
    elsif ($number < 1_000) {
        $reminder = $number % 100;
        if ($reminder != 0) {
            $result = $token3{$number - $reminder}.' '.num2slv_cardinal($reminder);
        }
        else {
            $result = $token3{$number};
        }
    }
    elsif ($number < 1_000_000) {
        $reminder = $number % 1_000;
        my $tmp1 = ($reminder != 0) ? ' '.num2slv_cardinal($reminder) : '';
        my $tmp2 = substr($number, 0, length($number)-3);

        if ($tmp2 == 1) {
            $tmp2 = 'tisoč';
        }
        else {
            $tmp2 = num2slv_cardinal($tmp2).' tisoč';
        }
        $result = $tmp2.$tmp1;
    }
    elsif ($number < 1_000_000_000) {
        $reminder = $number % 1_000_000;
        my $tmp1 = ($reminder != 0) ? ' '.num2slv_cardinal($reminder) : '';
        my $tmp2 = substr($number, 0, length($number)-6);
        my $tmp3 = $tmp2 % 100;
        my $tmp4 = $tmp2 % 10;
        my $mega;

        # Slovenian million declension:
        #   1          -> milijon
        #   2          -> dva milijona  (dual)
        #   3-4        -> milijone      (plural nominative)
        #   5+, 11-19  -> milijonov     (genitive plural)
        if ($tmp3 >= 11 && $tmp3 <= 19) {
            # teens always use genitive plural
            $mega = 'milijonov';
        }
        elsif ($tmp4 == 1 && $tmp2 == 1) {
            $mega = 'milijon';
        }
        elsif ($tmp4 == 1) {
            # 21, 31, ... -> en milijon
            $mega = 'milijon';
        }
        elsif ($tmp4 == 2 && $tmp2 == 2) {
            $mega = 'milijona';  # dual
        }
        elsif ($tmp4 == 2) {
            $mega = 'milijona';  # dual ending
        }
        elsif ($tmp4 == 3 || $tmp4 == 4) {
            $mega = 'milijone';
        }
        else {
            $mega = 'milijonov';
        }

        if ($tmp2 == 1) {
            $tmp2 = 'en '.$mega;
        }
        else {
            $tmp2 = num2slv_cardinal($tmp2).' '.$mega;
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

Lingua::SLV::Num2Word - Number to word conversion in Slovenian


=head1 VERSION

version 0.2603270

Lingua::SLV::Num2Word is module for conversion numbers into their representation
in Slovenian. It converts whole numbers from 0 up to 999 999 999.

=cut

# }}}
# {{{ SYNOPSIS

=pod

=head1 SYNOPSIS

 use Lingua::SLV::Num2Word;

 my $text = Lingua::SLV::Num2Word::num2slv_cardinal( 123 );

 print $text || "sorry, can't convert this number into slovenian language.";

=cut

# }}}
# {{{ Functions Reference

=pod

=head1 Functions Reference

=over 2

=item B<num2slv_cardinal> (positional)

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

=item num2slv_cardinal

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
