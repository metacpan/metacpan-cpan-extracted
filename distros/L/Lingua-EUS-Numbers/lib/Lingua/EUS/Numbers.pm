# For Emacs: -*- mode:cperl; mode:folding; coding:utf-8; -*-

package Lingua::EUS::Numbers;
# ABSTRACT: Number 2 word conversion in EUS.

# {{{ use block

use 5.10.1;

use warnings;
use strict;
use Carp;
use vars qw(
  @EXPORT_OK @ISA $VERSION
  %num2alpha
);
require Exporter;

# }}}
# {{{ variables declaration

@ISA     = qw(Exporter);

$VERSION = 0.0682;

@EXPORT_OK = qw(
  %num2alpha
  &cardinal2alpha
  &ordinal2alpha
);

# The Bask numeral system is vigesimal (base 20). So far, going to
# 999_999_999_999.

%num2alpha = (
    0          => 'zero',
    1          => 'bat',
    2          => 'bi',
    3          => 'hiru',
    4          => 'lau',
    5          => 'bost',
    6          => 'sei',
    7          => 'zazpi',
    8          => 'zortzi',
    9          => 'bederatzi',
    10         => 'hamar',
    11         => 'hamaika',
    12         => 'hamabi',
    13         => 'hamahiru',
    14         => 'hamalau',
    15         => 'hamabost',
    16         => 'hamasei',
    17         => 'hamazazpi',
    18         => 'hemezortzi',
    19         => 'hemeretzi',
    20         => 'hogei',
    40         => 'berrogei',
    60         => 'hirurogei',
    80         => 'laurogei',
    100        => 'ehun',
    200        => 'berrehun',
    300        => 'hirurehun',
    400        => 'laurehun',
    500        => 'bostehun',
    600        => 'seiehun',
    700        => 'zazpiehun',
    800        => 'zortziehun',
    900        => 'bederatziehun',
    1000       => 'mila',
    1000000    => 'milioi bat',
    1000000000 => 'mila milioi'
);

#Names for quantifiers, every block of 3 digits
#(thousands, millions, billions)
my %block2alpha = (
    block1 => 'mila',
    block2 => 'milioi',
    block3 => 'mila milioi'
);

# }}}

#This function accepts an integer (scalar) as a parameter and 
#returns a string (array), which is its Bask cardinal equivalent.
# {{{ cardinal2alpha

sub cardinal2alpha {
    my $orig_num = shift // return;
    my @result   = ();
    my ( $thousands, $hundreds, $tens, $units );
    my $num = $orig_num;

    #Input validation
    unless ( $num =~ /^\d+$/ ) {
        carp "Entry $num not valid. Should be numeric characters only";
        return;
    }

    if ( $num > 999_999_999_999 or $num < 0 ) {
        carp "Entry $num not valid. Number should be an integer between 0 and 999,999,999,999";
        return;
    }

    #Handling special cases
    return $num2alpha{0} if $num == 0;
    return $num2alpha{$num} if $num2alpha{$num};

    my $len = length($num);

    #Main logic: cutting number by block of 3 digits 
    while ( $len > 3 ) {

        $num = reverse($num);

        #Dealing with the part off the block(s) of three 
        my $extra_digits = substr( $num, int( ( $len - 1 ) / 3 ) * 3 );
        $extra_digits = reverse($extra_digits);
        push ( @result, triple_digit_handling($extra_digits) )
          unless $extra_digits == 1;

        #Adding name for the quantifier
        my $quantif = 'block' . ( int( ( $len - 1 ) / 3 ) );
        push ( @result, $block2alpha{$quantif} ) unless $num =~ /000$/;

        #Special case for 1 million: adding the term for "one" 
        push ( @result, $num2alpha{1} ) if $len == 7 && $extra_digits == 1;

        #Adding "eta" after millions (except when there's no thousand) 
        my $whats_left = substr( reverse($num), length($extra_digits) );
        if ( ( $len <= 8 and $len >= 7 )
            && $whats_left != 0
            && ( reverse($num) !~ /^[^0]000/ ) )
        {
            push ( @result, "eta" );
        }

        #Adding 'eta' for hundreds, except when there are tens and/or units 
        if ( length($num) <= 6 ) {
            ( $units, $tens, $hundreds, $thousands, my @rest ) =
              split ( //, reverse($orig_num) );

            if (   ( $hundreds  != 0 && $tens == 0 && $units == 0 )
                || ( $hundreds  == 0 && ( $tens || $units ) ) && $num !~ /^0/
                || ( $thousands == 0 && $hundreds == 0 && ( $tens || $units ) )
              )
            {
                push ( @result, "eta" );
            }
        }

        #Dealing with the remaining digits
        $num = reverse($num);
        $num = substr( $num, length($extra_digits) );
        $len = length($num);

    }    #end while len > 3

    if ( $len <= 3 ) {
        push ( @result, triple_digit_handling($num) );
        return "@result";
    }
}

# }}}

#This function takes an integer (scalar) as a parameter, which is
#a 3-digit number or less, and returns a string (array), which is 
#its Bask equivalent.
# {{{ triple_digit_handling

sub triple_digit_handling {
    my $num    = shift;
    my @result = ();
    my ( $hundreds, $tens, $units, @tens_n_units );

    #Handling exceptional cases 
    return if $num > 999 || $num < 0;
    return if $num == 0;
    return $num2alpha{$num} if $num2alpha{$num};

    my $len = length($num);

    #Handling 2-digit numbers
    if ( $len == 2 ) {
        ( $tens, $units ) = split ( //, sprintf( "%02d", $num ) );
        @result = double_digit_handling( $tens, $units );
        return @result;
    }

    #Handling 3-digit numbers
    if ( $len == 3 ) {
        ( $hundreds, $tens, $units ) = split ( //, sprintf( "%03d", $num ) );
        unless ( $hundreds == 0 ) {
            $hundreds *= 100;
            push ( @result, $num2alpha{$hundreds} );
            push ( @result, "eta" ) if $tens || $units;
        }

        @tens_n_units = double_digit_handling( $tens, $units );
        push ( @result, @tens_n_units );
        return @result;
    }

}

# }}}

#This function takes two integers (scalars) as parameters (tens and units)
#and returns a string (array), which is their Bask equivalent.
# {{{ double_digit_handling

sub double_digit_handling {
    my $diz  = shift;
    my $unit = shift;
    my $num  = "$diz$unit";
    my @result;

    #Handling exceptional cases 
    return if $num == 0;

    return $num2alpha{$num} if $num2alpha{$num};

    return $num2alpha{$unit} unless $diz;

    #Dealing with base 20  
    if ( $diz =~ /[3579]/ ) {
        $diz -= 1;
        $unit += 10;
    }
    $diz = $diz * 10;

    if ($unit) { push ( @result, "$num2alpha{$diz}ta" ); }
    else { push ( @result, $num2alpha{$diz} ); }
    push ( @result, $num2alpha{$unit} );

    return @result;
}

# }}}

#This function accepts an integer (scalar) as a parameter and
#returns a string (array), which is its Bask ordinal equivalent.
# {{{ ordinal2alpha

sub ordinal2alpha {
    my $num = shift // return;
    my @result;

    #Handling special cases
    return unless $num =~ /^\d+$/;
    return if ( $num < 0 || $num > 999_999_999_999 );
    return "lehenengo" if $num == 1;

    push ( @result, join ( '', cardinal2alpha($num), "garren" ) );
    return "@result";
}

# }}}

1;
__END__

# {{{ module documentation

=pod

=head1 NAME

Lingua::EUS::Numbers - Converts numbers into Bask (Euskara).

=head1 VERSION

version 0.0682

=head1 SYNOPSIS

  # Functional interface 
  use Lingua::EUS::Numbers;
  my $number = shift;
  print "The cardinal value of $number is " . cardinal2alpha($number) . " in Euskara.\n";
  print "The ordinal value of $number is " . ordinal2alpha($number) . " in Euskara.\n";

=head1 DESCRIPTION

Number 2 word conversion in EUS.

This module converts numbers (cardinals and ordinals) into their Bask (Euskara)
equivalents.  It accepts positive integers up to, but not including, 1 trillion.
Incidentally, the Bask counting system is vigesimal, i.e. base 20.

The module uses unified Bask (Euskara Batua), which sometimes varies from the
Bask spoken in the seven Bask provinces, especially from Labourd (Lapurdi) in
the Northen Bask Country (Ipar Euskal Herria).  However, Euskara Batua is the
official Bask taught in Bask schools (Ikastolak) throughout the seven
provinces.

For example, the cardinal '18' is 'hemezortzi' in Euskara Batua, while it is
'hamazortzi' in Lapurdi.  Those who wish to use their own version of Euskara can
export %num2alpha and modify it at their own discretion.

A Bask legend says that even the Devil did not succeed in learning this
truly unique language, but that should not deter you from doing
so.  Euskara is an orphan language of mysterious origins, apparently unrelated
to any language anywhere else in the world.  It is believed to predate the
Indo-European invasion and if so, this is one of the world's most ancient
languages.

Bask people refer to themselves as Euskaldunak, or 'speakers of the Euskara'.  
Being part of the Bask Nation is a question of language, not ethnicity or place
of birth.  There is not even a word for 'being a Bask' in Euskara.  So if you
learn this fascinating language, you too can become Euskaldun.

=head1 FUNCTIONS

=over 4

=item cardinal2alpha($number)

This function accepts an integer (scalar) as a parameter and returns a string
(array), which is its Bask cardinal equivalent.

It returns C<undef> if a)the argument passed is not defined, or b)the
argument is not an integer, or c)the integer passed does not fall between zero
and 999,999,999,999.

=item ordinal2alpha($number)

This function accepts an integer (scalar) as a parameter and returns a string
(array), which is its Bask ordinal equivalent.

It returns C<undef> if a)the argument passed is not defined, or b)the
argument is not an integer, or c)the integer passed does not fall between zero
and 999,999,999,999.

=back

=head1 EXPORT

This module exports by default the functions cardinal2alpha() and
ordinal2alpha().  It can also export the hash %num2alpha.

=head1 SOURCE

The Bask encyclopedia "Administrazio-hizkeraren entziklopedia" and its
web pages referring to Bask numbers (cardinals and ordinals) at:
http://www.ivap.com/eusk/entziklo/kardinal.htm and http://www.ivap.com/eusk/entziklo/ordinal.htm.

=head1 BUGS AND COMMENTS

If you find one, please use the Request Tracker Interface -
http://rt.cpan.org/NoAuth/Bugs.html?Dist=Lingua-EU-Numbers to report
it. 

=head1 SEE ALSO

Lingua::FR::Numbers, Lingua::Num2Word

=head1 THANKS 

Milesker to Briac Pilpré who gave me the idea for this module, and who also
thought about exporting the hash %num2alpha for people wanting to use their own
version of Euskara.

Esker asko to Deric Gerlach who reviewed my English and my overall pod
documentation.

=head1 AUTHOR

Isabelle Hernandez, <isabelle@cpan.org>

Maintenance
PetaMem s.r.o. <info@petamem.com>

=head1 COPYRIGHT AND LICENSE

Copyright 2002 by Isabelle Hernandez

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut

# }}}
