package Gantry::Control::C::Access;

use strict;

use constant MP2 => (
    exists $ENV{MOD_PERL_API_VERSION} and
    $ENV{MOD_PERL_API_VERSION} >= 2 
);

# must explicitly import for mod_perl2
BEGIN {
    if (MP2) {
        require Gantry::Engine::MP20;
        Gantry::Engine::MP20->import();
    }
}

############################################################
# Functions                                                #
############################################################

######################################################################
# Main Execution Begins Here                                         #
######################################################################
sub handler : method { 
    my( $self, $r ) = @_; 

    my $remote_ip = $self->remote_ip( $r );

    # Range, or specfic ips.
    my $ranges  = $r->dir_config( 'AuthAllowRanges' );

    if ( defined $r->dir_config( 'auth_allow_ranges' ) ) {
        $ranges = $r->dir_config( 'auth_allow_ranges' );
    }

    my $ips = $r->dir_config( 'AuthAllowIps' );

    if ( defined $r->dir_config( 'auth_allow_ips' ) ) {
        $ips = $r->dir_config( 'auth_allow_ips' );
    }

    my $ignore = $r->dir_config( 'AccessNoOverRide' );

    if ( defined $r->dir_config( 'ignore_access_handler' ) ) {
        if ( $r->dir_config( 'ignore_access_handler' ) =~/^y/i ) {
            $ignore = 1;
        }
        elsif ( $r->dir_config( 'ignore_access_handler' ) =~ /^n/i ) {
            $ignore = 0;
        }
    }
    
    $ignore     = 0 if ( ! defined $ignore );

    if ( defined $ranges ) {
        # make the decimal version of the ip.

        my @remote = split( '\.', $remote_ip );

        my $dip = ip2bin( $remote[0] );
        $dip    .= ip2bin( $remote[1] );
        $dip    .= ip2bin( $remote[2] );
        $dip    .= ip2bin( $remote[3] );

        # This is broken in 5.05
        #my $dip1 = sprintf( "%08b %08b %08b %08b", split( '\.', $remote_ip ));
        
        for my $range ( split( ',', $ranges ) ) {
            my ( $ranged, $slash ) = $range =~ /^(.*)\/(\d+)$/;

            my @ranger  = split( '\.', $ranged );
            my $drng    = ip2bin( $ranger[0] );
            $drng       .= ip2bin( $ranger[1] );
            $drng       .= ip2bin( $ranger[2] );
            $drng       .= ip2bin( $ranger[3] );

            # This is broken in 5.05
            #my $drng = sprintf( "%08b%08b%08b%08b", split( '\.', $ranged ) );

            if ( substr( $dip, 0, $slash) eq substr( $drng, 0, $slash ) ) { 

                if ( ! $r->user ) { 
                    $r->user( 'anoymous_ip_user' );
                }
                
                if ( ! $ignore ) {
                    $r->set_handlers( PerlAuthenHandler => [ 
                        sub{ $self->status_const( 'OK' ) }
                    ] );
                    $r->set_handlers( PerlAuthzHandler  => [
                        sub{ $self->status_const( 'OK' ) } ] );
                }

                return( $self->status_const( 'OK' ) );
            }
        }
    }

    if ( defined $ips ) {
        for my $ip ( split( ',', $ips ) ) {
            if ( $ip =~ /^\s?$remote_ip\s?$/ ) {
                if ( ! $r->user ) { 
                    $r->user( 'anoymous_ip_user' );
                }

                if ( ! $ignore ) {
                    $r->set_handlers( PerlAuthenHandler => [ 
                        sub{ $self->status_const( 'OK' ) }
                    ] );
                    $r->set_handlers( PerlAuthzHandler  => [
                        sub{ $self->status_const( 'OK' ) } ] );
                }

                return( $self->status_const( 'OK' ) );
            }
        }
    }

    return( $self->status_const( 'DECLINED' ) ); 

} # END handler 

#-------------------------------------------------
# ip2bin( $ip )
#-------------------------------------------------
# dec 2 bin for the ip address.
#-------------------------------------------------
sub ip2bin {
    my $dec = shift;

    my $bin = unpack( "B32", pack( "N", $dec ) );
    $bin    =~ s/^0+(?=\d)//;

    if ( length( $bin ) < 8 ) { 
        return( '0' x ( 8 - length( $bin ) ) . $bin );
    }
    else {
        return( $bin );
    }
} # END ip2bin

#-------------------------------------------------
# $self->import(  @options )
#-------------------------------------------------
sub import {
    my ( $self, @options ) = @_;

    my( $engine, $tplugin );

    foreach (@options) {

        # Import the proper engine
        if (/^-Engine=(.*)$/) {
            $engine = "Gantry::Engine::$1";
            eval "use $engine";
            if ( $@ ) {
                die "unable to load engine $1 ($@)";
            }
        }

    }

} # end: import

# EOF
1;

__END__

=head1 NAME 

Gantry::Control::C::Access - Authentication by IP

=head1 DESCRIPTION

This is an Authentication module against an IP range.

=head1 APACHE 

This is the minimum configuration to set up Authen on a location, 
it is probably more usefull with Authz on and the App based authz handlers
turned on as well. The C<auth_allow_ranges> takes ranges of ip address in
cidr notation comma seperated. The C<auth_allow_ips> takes single ip
addresses seperated by commas. The C<auth_ignore_access_handler> allows 
the access not to over ride authen and authz if needed, set to 1 not 
to override do not set if you want the override to happen.

  <Location / >
    
    PerlSetVar  auth_allow_ranges  "192.168.1.0/24,192.168.2.0/24"
    PerlSetVar  auth_allow_ips     "127.0.0.1" 
    PerlSetVar  auth_ignore_access_handler  1 

    AuthType Basic
    AuthName "My Auth Location"

    PerlAccessHandler   Gantry::Control::C::Access

    require valid-user
 </Location>

=head1 DATABASE

No database is specfically required for this module.

=head1 METHODS

=over 4

=item handler

The mod_perl access handler.

=item ip2bin

For internal use.

=back

=head1 SEE ALSO

Gantry(3)

=head1 LIMITATIONS

It only checks against the IP addresses and users table and only
provides yes/no access. For more granuality check out the Authz handlers
to turn on as well. 

=head1 AUTHOR

Tim Keefer <tkeefer@gmail.com>

=head1 COPYRIGHT

Copyright (C) 2005-6, Tim Keefer.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut
