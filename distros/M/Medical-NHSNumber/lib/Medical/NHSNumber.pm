package Medical::NHSNumber;

use warnings;
use strict;

=head1 NAME

Medical::NHSNumber - Check if an NHS number is valid

=head1 VERSION

Version 0.04

=cut

our $VERSION = '0.04';


=head1 SYNOPSIS

Everyone registered with the NHS in England and Wales has their own
unique NHS number. The NHS number enables health care professionals
in the UK to obtain, link and index electronic health records for an 
individual across a multiple sources of clinical information.

Given a new-style NHS number, returns true if the number is
valid and false if the number appears to be invalid.

    use Medical::NHSNumber;

    my $nhs_no = '1234561234';
    my $rv = Medical::NHSNumber::is_valid( $nhs_no );

The validation is performed using the Modulus 11 algorith. More
details on the exact implementation followed can be found on the
NHS Connecting for Health website at L<http://www.connectingforhealth.nhs.uk/industry/docs/pds/index.html?dat_nhs_no.htm>

Additional information on Modulus 11 can also be found on this
HP site L<http://docs.hp.com/en/32209-90024/apds02.html>

Please note, this module will only check the validity of new style
NHS numbers i.e. ten digit numbers. There are over 21 different formats
for older styles of NHS numbers which currently, this module does 
not support. If you do happen to know the specifics for the older 
versions and would like to tell me, I would be more than happy to 
incorporate some logic for them.

=head1 FUNCTIONS

=head2 is_valid

Given a new-style NHS number, returns true if the number is
valid and false if the number appears to be invalid.

     my $rv = Medical::NHSNumber::is_valid( $nhs_no );

=cut

my $RH_WEIGHTS = {
    0 => 10,
    1 => 9,
    2 => 8,
    3 => 7,
    4 => 6,
    5 => 5,
    6 => 4,
    7 => 3,
    8 => 2,
};

sub is_valid {
    my $number = shift;

    return 
        unless ( defined $number);
    
    my @digits = split //, $number;
    
    return 
        unless ( scalar(@digits) == 10 );
    
    return 
        unless ( $number =~ /\d{10}/ );
    
    ##
    ## obtain the check digit, 10th digit in NHS number
    
    my $check_digit = pop @digits;
    
    ##
    ## Loop through first 9 digits and add up
    ## their weighted factor.    
    
    my $sum;
    my $n = 0;
    foreach my $digit ( @digits ){
        my $weight = $RH_WEIGHTS->{ $n };
        my $weighted_digit = $weight * $digit;
        $sum += $weighted_digit;
        $n++;
    }
    
    my $remainder              = $sum % 11;
    my $calculated_check_digit = 11 - $remainder;
    
    ##
    ## If check digit is 11, reset it to zero.
    
    if ( $calculated_check_digit == 11 ) {
        $calculated_check_digit = 0;
    }
    
    ##
    ## If the calculated check digit is not equal 
    ## to the 10th digit of the entered NHS number
    ## or is equal to 10, the number is invalid.
    
    if ( 
        $calculated_check_digit == 10 ||
        $calculated_check_digit != $check_digit ) {
        return ;
    } else {
        return 1;
    }

}


=head1 AUTHOR

Dr Spiros Denaxas, C<< <s.denaxas at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-medical-nhsnumber at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Medical-NHSNumber>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Medical::NHSNumber


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Medical-NHSNumber>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Medical-NHSNumber>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Medical-NHSNumber>

=item * Search CPAN

L<http://search.cpan.org/dist/Medical-NHSNumber/>

=item * Source code

The source code can be found on github L<https://github.com/spiros/Medical-NHSNumber>

=back

=head1 COPYRIGHT & LICENSE

Copyright 2009 Dr Spiros Denaxas.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of Medical::NHSNumber
