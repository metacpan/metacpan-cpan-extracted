#
#    Constraints.pm - Standard constraints for use in HTML::FormValidator.
#
#    This file is part of FormValidator.
#
#    Author: Francis J. Lacoste <francis.lacoste@Contre.COM>
#
#    Copyright (C) 1999,2000 iNsu Innovations Inc.
#    Copyright (C) 2001 Francis J. Lacoste
#    Parts Copyright 1996-1999 by Michael J. Heins <mike@heins.net>
#    Parts Copyright 1996-1999 by Bruce Albrecht  <bruce.albrecht@seag.fingerhut.com>
#
#    Parts of this module are based on work by
#    Bruce Albrecht, <bruce.albrecht@seag.fingerhut.com> contributed to
#    MiniVend.
#
#    Parts also based on work by Michael J. Heins <mikeh@minivend.com>
#
#    This program is free software; you can redistribute it and/or modify
#    it under the terms same terms as perl itself.
#
use strict;

package HTML::FormValidator::Constraints;

=pod

=pod

=head1 NAME

HTML::FormValidator::Constraints - Basic sets of constraints.
on input profile.

=head1 SYNOPSIS

In an HTML::FormValidator profile:

    constraints  =>
	{
	    email	=> "email",
	    fax		=> "american_phone",
	    phone	=> "american_phone",
	    state	=> "state",
	},

=head1 DESCRIPTION

Those are the builtin constraint that can be specified by name in the
input profiles.

=over

=item email

Checks if the email LOOKS LIKE an email address. This checks if the
input contains one @, and a two level domain name. The address portion
is checked quite liberally. For example, all those probably invalid
address would pass the test :

    nobody@top.domain
    %?&/$()@nowhere.net
    guessme@guess.m

=cut

# Many of the following validator are taken from
# MiniVend 3.14. (http://www.minivend.com)
# Copyright 1996-1999 by Michael J. Heins <mike@heins.net>

sub valid_email {
    my $email = shift;

    return $email =~ /[\040-\176]+\@[-A-Za-z0-9.]+\.[A-Za-z]+/;
}

my $state = <<EOF;
AL AK AZ AR CA CO CT DE FL GA HI ID IL IN IA KS KY LA ME MD
MA MI MN MS MO MT NE NV NH NJ NM NY NC ND OH OK OR PA PR RI
SC SD TN TX UT VT VA WA WV WI WY DC AP FP FPO APO GU VI
EOF

my $province = <<EOF;
AB BC MB NB NF NS NT ON PE QC SK YT YK NU
EOF

=pod

=item state_or_province

This one checks if the input correspond to an american state or a canadian
province.

=cut

sub valid_state_or_province {
    return valid_state(@_) || valid_province(@_);
}

=pod

=item state

This one checks if the input is a valid two letter abbreviation of an 
american state.

=cut

sub valid_state {
    my $val = shift;
    return $state =~ /\b$val\b/i;
}

=pod

=item province

This checks if the input is a two letter canadian province
abbreviation.

=cut

sub valid_province {
    my $val = shift;
    return $province =~ /\b$val\b/i;
}

=pod

=item zip_or_postcode

This constraints checks if the input is an american zipcode or a
canadian postal code.

=cut

sub valid_zip_or_postcode {
    return valid_zip(@_) || valid_postcode(@_);
}

=pod

=item postcode

This constraints checks if the input is a valid Canadian postal code.

=cut

sub valid_postcode {
    my $val = shift;
    $val =~ s/[_\W]+//g;
    return $val =~ /^[ABCEGHJKLMNPRSTVXYabceghjklmnprstvxy]\d[A-Za-z][- ]?\d[A-Za-z]\d$/;
}

=pod

=item zip

This input validator checks if the input is a valid american zipcode :
5 digits followed by an optional mailbox number.

=cut

sub valid_zip {
    my $val = shift;
    return $val =~ /^\s*\d{5}(?:[-]\d{4})?\s*$/;
}

=pod

=item phone

This one checks if the input looks like a phone number, (if it
contains at least 6 digits.)

=cut

sub valid_phone {
    my $val = shift;

    return $val =~ tr/0-9// >= 6;
}

=pod

=item american_phone

This constraints checks if the number is a possible North American style
of phone number : (XXX) XXX-XXXX. It has to contains more than 7 digits.

=cut

sub valid_american_phone {
    my $val = shift;
    return $val =~ tr/0-9// >= 7;
}

=pod

=item cc_number

This is takes two parameters, the credit card number and the credit cart
type. You should take the hash reference option for using that constraint.

The number is checked only for plausibility, it checks if the number could
be valid for a type of card by checking the checksum and looking at the number
of digits and the number of digits of the number.

This functions is only good at weeding typos and such. IT DOESN'T
CHECK IF THERE IS AN ACCOUNT ASSOCIATED WITH THE NUMBER.

=cut

# This one is taken from the contributed program to 
# MiniVend by Bruce Albrecht
sub valid_cc_number {
    my ( $the_card, $card_type ) = @_;

    my ($index, $digit, $product);
    my $multiplier = 2;        # multiplier is either 1 or 2
    my $the_sum = 0;

    return 0 if length($the_card) == 0;

    # check card type
    return 0 unless $card_type =~ /^[admv]/i;

    return 0 if ($card_type =~ /^v/i && substr($the_card, 0, 1) ne "4") ||
      ($card_type =~ /^m/i && substr($the_card, 0, 1) ne "5") ||
	($card_type =~ /^d/i && substr($the_card, 0, 4) ne "6011") ||
	  ($card_type =~ /^a/i && substr($the_card, 0, 2) ne "34" &&
	   substr($the_card, 0, 2) ne "37");

    # check for valid number of digits.
    $the_card =~ s/\s//g;    # strip out spaces
    return 0 if $the_card !~ /^\d+$/;

    $digit = substr($the_card, 0, 1);
    $index = length($the_card)-1;
    return 0 if ($digit == 3 && $index != 14) ||
        ($digit == 4 && $index != 12 && $index != 15) ||
            ($digit == 5 && $index != 15) ||
                ($digit == 6 && $index != 13 && $index != 15);


    # calculate checksum.
    for ($index--; $index >= 0; $index --)
    {
        $digit=substr($the_card, $index, 1);
        $product = $multiplier * $digit;
        $the_sum += $product > 9 ? $product - 9 : $product;
        $multiplier = 3 - $multiplier;
    }
    $the_sum %= 10;
    $the_sum = 10 - $the_sum if $the_sum;

    # return whether checksum matched.
    $the_sum == substr($the_card, -1);
}

=pod

=item cc_exp

This one checks if the input is in the format MM/YY or MM/YYYY and if
the MM part is a valid month (1-12) and if that date is not in the past.

=cut

sub valid_cc_exp {
    my $val = shift;

    my ($month, $year) = split('/', $val);
    return 0 if $month !~ /^\d+$/ || $year !~ /^\d+$/;
    return 0 if $month <1 || $month > 12;
    $year += ($year < 70) ? 2000 : 1900 if $year < 1900;
    my @now=localtime();
    $now[5] += 1900;
    return 0 if ($year < $now[5]) || ($year == $now[5] && $month <= $now[4]);

    return 1;
}

=pod

=item cc_type

This one checks if the input field starts by M(asterCard), V(isa),
A(merican express) or D(iscovery).

=cut

sub valid_cc_type {
    my $val = shift;

    return $val =~ /^[MVAD]/i;
}

1;

__END__

=pod

=head1 SEE ALSO

HTML::FormValidator(3) HTML::FormValidator::Filters(3)
HTML::FormValidator::ConstraintsFactory(3)

=head1 CREDITS

Some of those input validation functions have been taken from MiniVend
by Michael J. Heins <mike@heins.net>

The credit card checksum validation was taken from contribution by
Bruce Albrecht <bruce.albrecht@seag.fingerhut.com> to the MiniVend
program.

=head1 AUTHORS

    Francis J. Lacoste <francis.lacoste@iNsu.COM>
    Michael J. Heins <mike@heins.net>
    Bruce Albrecht  <bruce.albrecht@seag.fingerhut.com>

=head1 COPYRIGHT

Copyright (c) 1999 iNsu Innovations Inc.
All rights reserved.

Parts Copyright 1996-1999 by Michael J. Heins <mike@heins.net>
Parts Copyright 1996-1999 by Bruce Albrecht  <bruce.albrecht@seag.fingerhut.com>

This program is free software; you can redistribute it and/or modify
it under the terms as perl itself.

=cut
