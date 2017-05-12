package Gantry::Utils::DBConnHelper::MP13;
use strict; use warnings;

use Gantry::Conf;

use base 'Gantry::Utils::DBConnHelper';

Gantry::Utils::DBConnHelper->set_subclass(
    'Gantry::Utils::DBConnHelper::MP13'
);

#----------------------------------------------------------------
# Methods for regular connections
#----------------------------------------------------------------

sub get_dbh {
    my $dbh;
    my $r = Apache->request();
    
    if ( not $Apache::ServerStarting ) {
        $dbh = $r->pnotes( 'dbh' );
    }

    return $dbh;
}

sub set_dbh {
    my $class = shift;
    my $dbh   = shift;
    my $r     = Apache->request();

    if ( not $Apache::ServerStarting ) {
        $r->pnotes( 'dbh', $dbh );
    }
}

sub _get_gantry_conf {
    my $r = shift;
    my $location = $r->location;
    my $instance   = $r->dir_config( 'GantryConfInstance' );
    my $conf;

    return unless defined $instance;

    my $gconf_file = $r->dir_config( 'GantryConfFile' );

    # Check for a cached version first.
    $conf = $r->pnotes( "conf_${instance}_${location}" );
    
    unless ($conf) {
        $conf = Gantry::Conf->retrieve(
            {
                instance    => $instance,
                config_file => $gconf_file,
            }
        );
        
        $r->pnotes( "conf_${instance}_${location}", $conf );
    }
    
    return $conf;
}

sub get_conn_info {
    my $r           = Apache->request();
    my $gantry_conf = _get_gantry_conf( $r );

    if ( $gantry_conf ) {
        return {
            dbconn => $gantry_conf->{ 'dbconn' },
            dbuser => $gantry_conf->{ 'dbuser' },
            dbpass => $gantry_conf->{ 'dbpass' },
        }
    }
    else  {
        return {
            dbconn => $r->dir_config( 'dbconn' ),
            dbuser => $r->dir_config( 'dbuser' ),
            dbpass => $r->dir_config( 'dbpass' ),
        };
    }
}

#----------------------------------------------------------------
# Methods for auth connections
#----------------------------------------------------------------

sub get_auth_dbh {
    my $auth_dbh;
    my $r = Apache->request();

    if ( not $Apache::ServerStarting ) {
        $auth_dbh = $r->pnotes( 'auth_dbh' );
    }

    return $auth_dbh;
}

sub set_auth_dbh {
    my $class    = shift;
    my $auth_dbh = shift;
    my $r        = Apache->request();

    if ( not $Apache::ServerStarting ) {
        $r->pnotes( 'auth_dbh', $auth_dbh );
    }
}

sub get_auth_conn_info {
    my $r           = Apache->request();
    my $gantry_conf = _get_gantry_conf( $r );
    my $auth_conn;
    
    $auth_conn->{ auth_dbconn } =   $gantry_conf->{ 'auth_dbconn' } ||
                                    $r->dir_config( 'auth_dbconn' ) ||
                                    $gantry_conf->{ 'dbconn' } ||
                                    $r->dir_config( 'dbconn' );
    
    $auth_conn->{ auth_dbuser } =   $gantry_conf->{ 'auth_dbuser' } ||
                                    $r->dir_config( 'auth_dbuser' ) ||
                                    $gantry_conf->{ 'dbuser' } ||
                                    $r->dir_config( 'dbuser' );
    
    $auth_conn->{ auth_dbpass } =   $gantry_conf->{ 'auth_dbpass' } ||
                                    $r->dir_config( 'auth_dbpass' ) ||
                                    $gantry_conf->{ 'dbpass' } ||
                                    $r->dir_config( 'dbpass' );
    
    return $auth_conn;
}

1;

=head1 NAME

Gantry::Utils::DBConnHelper::MP13 - connection info and dbh cache manager for mod_perl 1

=head1 SYNOPSIS

    use Gantry::Utils::DBConnHelper::MP13;

    # put these PerlSetVars in your conf (as needed):
    #   dbconn
    #   dbuser
    #   dbpass
    #   auth_dbconn
    #   auth_dbuser
    #   auth_dbpass
    
=head1 DESCRIPTION

When you use a model which inherits from Gantry::Utils::CDBI or
Gantry::Utils::Model, using this module can help with database
connection management.  Feel free to implement your own subclass
of Gantry::Utils::DBConnHelper if you need more control.

This module is designed to work with mod_perl 1.3.  There is
another module for mod_perl 2 candidates: Gantry::Utils::DBConnHelper::MP20.

=head1 METHODS

See Gantry::Utils::DBConnHelper for a description of the methods available
here.  But note that there are no set_conn_info or set_auth_conn_info
methods.  All values are taken from PerlSetVars.

If you do not define an auth_dbconn PerlSetVar, this module will return
the regular connection information, if it is ever asked for auth connection
information.

Here is a list of the methods documented in Gantry::Utils::DBConnHelper.

=over 4

=item get_auth_conn_info

=item get_auth_dbh

=item get_conn_info

=item get_dbh

=item set_auth_dbh

=item set_dbh

=back

=head1 AUTHOR

Phil Crow <philcrow2000@yahoo.com>

=head1 COPYRIGHT and LICENSE

Copyright (c) 2006, Phil Crow.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut
