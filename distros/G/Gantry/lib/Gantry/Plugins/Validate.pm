package Gantry::Plugins::Validate;

use strict;
use Date::Calc qw( check_date );

############################################################
# Variables                                                #
############################################################
############################################################
# Functions                                                #
############################################################
#-------------------------------------------------
# is_date( $date )
#-------------------------------------------------
sub is_date { 
    my( $site, $date ) = @_;

    return( 0 ) if ( ! defined $date );

    return( 0 ) if ( $date !~ /^\d{1,2}-\d{1,2}-\d{4}$/ );

    my ( $month, $day, $year ) = split( '-', $date ); 
        
    return( 0 ) if ( ! check_date( $year, $month, $day ) );

    return( 1 );
} # END is_date 

#-------------------------------------------------
# is_email( $email )
#-------------------------------------------------
sub is_email {
    my( $site, $email ) = @_;
    
    return( 0 ) if ( ! defined $email );

    return( 0 ) if ( $email !~ /\@/ );
    
    return( 0 ) if ( $email !~ /\./ );

    return( 1 );
} # END is_email

#-------------------------------------------------
# is_float( $float )
#-------------------------------------------------
sub is_float {
    my( $site, $float ) = @_;

    return( 0 ) if ( ! defined $float );

    return( 1 ) if ( is_integer( $float ) );

    return( 0 ) if ( $float !~ /^-?\d+\.\d+$/ );

    return( 1 );
} # END is_float

#-------------------------------------------------
# is_ident( $ident )
#-------------------------------------------------
sub is_ident {
    my( $site, $ident ) = @_;

    return( 0 ) if ( ! defined $ident );

    return( 0 ) if ( ! is_text( $ident ) );

    return( 0 ) if ( $ident =~ /\s/ );

    return( 1 );
} # END is_ident

#-------------------------------------------------
# is_integer( $int )
#-------------------------------------------------
sub is_integer {
    my( $site, $int ) = @_;

    return( 0 ) if ( ! defined $int );

    return( 0 ) if ( $int !~ /^-?\d+$/ );

    return( 1 );
} # END is_integer

#-------------------------------------------------
# is_ip( $ip )
#-------------------------------------------------
sub is_ip {
    my( $site, $ip ) = @_;

    return( 0 ) if ( ! defined $ip );

    return( 0 ) if ( $ip !~ /^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$/ );

    return( 1 );
} # END is_ip

#-------------------------------------------------
# is_mac( $mac )
#-------------------------------------------------
sub is_mac {
    my( $site, $mac ) = @_;
    
    return( 0 ) if ( ! defined $mac );

    # prolly needs to check more ...
    return( 0 ) if ( $mac !~ /^[0-9A-Fa-f:\.\-\ ]+$/m );
                      
    return( 1 );    

} # END is_mac

#-------------------------------------------------
# is_number( $number )
#-------------------------------------------------
sub is_number {
    my( $site, $number ) = @_;

    return( 0 ) if ( ! defined $number );

    return( 1 ) if ( is_integer( $number ) );

    return( 1 ) if ( is_float( $number ) );

    return( 0 );
} # END is_number

#-------------------------------------------------
# is_text( $text )
#-------------------------------------------------
sub is_text {
    my( $site, $text ) = @_;

    return( 0 ) if ( ! defined $text );

    return( 0 ) if ( length( $text ) < 1 );

    return( 1 );
} # END is_text

#-------------------------------------------------
# is_time( $time )
#-------------------------------------------------
sub is_time {
    my( $site, $time ) = @_;

    return( 0 ) if ( ! defined $time );

    return( 0 ) if ( $time !~ /^\d+:\d+(:\d+)?$/ );

    my ( $hours, $minutes, $seconds ) = split( ':', $time );

    return( 0 ) if ( ( $hours < 0 ) || ( $hours > 23 ) );
    return( 0 ) if ( ( $minutes < 0 ) || ( $minutes > 59 ) );

    if ( defined $seconds ) {
        return( 0 ) if ( ( $seconds < 0 ) || ( $seconds > 59 ) );
    }

    return( 1 );
} # END is_time

# EOF
1;

__END__

=head1 NAME 

Gantry::Plugin::Validate - Validates input values.

=head1 SYNOPSIS

  is_date
    if ( is_date( $date ) )

  is_email
    if ( is_email( $email ) )

  is_float 
    if ( is_float( $float ) )

  is_ident
    if ( is_ident( $ident ) )

  is_integer
    if ( is_integer( $integer ) )

  is_ip
    if ( is_ip( $ip ) )

  is_mac
    if ( is_mac( $mac ) )

  is_number
    if ( is_number( $number ) )

  is_text 
    if ( is_text( $text ) )

  is_time
    if ( is_time( $time ) )

=head1 DESCRIPTION

This module allows the validation of many common types of input.

=head1 FUNCTIONS 

=over 4

=item is_date( $date )

This function takes a date, C<$date>, and verifies that it is indeed a valid
date. The date must be of the form "MM-DD-YYYY". The function returns 
either '1' or '0'.

=item is_email( $email )

This function checks to see if C<$email> is a valid email address. It checks
only the form of the email address and not if the username or the domain 
exist. The function returns either '1' or '0'.

=item is_float( $float )

This function checks to see if C<$float> is a valid floating point number. 
The function returns either '1' or '0'.

=item is_ident( $ident )

This function checks to see if C<$ident> is a valid text ident. This
means it has text, and none of the text is a space.  The function
returns either '1' or '0'.

=item is_integer( $integer )

This function checks to see if C<$integer> is in fact a valid integer number.
The function returns either '1' or '0'.

=item is_ip( $ip )

This function checks to see if C<$ip> is a valid ip address. The function
returns either '1' or '0'.

=item is_mac( $mac )

This function checks to see if C<$mac> contains the valid characters 
for a MAC address. It does not currently check to see if the MAC address
is of the proper length. The function returns either '1' or '0'.

=item is_number( $number )

This function checks to see if C<$number> is a valid number. It does this
by checking if it passes C<is_integer()> or C<is_float()>. The function 
returns eiter a '1' or a '0'.

=item is_text( $text )

This function checks to see if C<$text> does contain text. This is a
fairly broad range of things mainly it must be defined and have a length
that is greater than 0. The function returns either a '1' or a '0'.

=item is_time( $time )

This function checks to see if C<$time> does contain a valid time. A
valid date is in military time ( 0-23:0-59 ) seconds are optional. 

=back

=head1 SEE ALSO

Gantry(3), Date::Calc(3)

=head1 LIMITATIONS 

This module depends on Date::Calc(3) for the is_date validation.

=head1 AUTHOR

Tim Keefer <tkeefer@gmail.com>
Nicholas Studt <nstudt@angrydwarf.org>

=head1 COPYRIGHT

Copyright (c) 2005-6, Tim Keefer.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut
