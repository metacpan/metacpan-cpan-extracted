package Gantry::Utils::DBConnHelper::Script;
use strict; use warnings;

use base 'Gantry::Utils::DBConnHelper';

Gantry::Utils::DBConnHelper->set_subclass(
    'Gantry::Utils::DBConnHelper::Script'
);

my $dbh;
my $conn_info;

my $auth_dbh;
my $auth_conn_info;

sub get_dbh {
    return $dbh;
}

sub set_dbh {
    my $class = shift;
    $dbh      = shift;
}

sub get_conn_info {
    return $conn_info;
}

sub set_conn_info {
    my $class  = shift;
    $conn_info = shift;
}

#-----------------------------------------------------------------
# The methods below are for cgi scripts which use auth databases.
#-----------------------------------------------------------------

sub get_auth_dbh {
    return $auth_dbh;
}

sub set_auth_dbh {
    my $class = shift;
    $auth_dbh = shift;
}

sub get_auth_conn_info {
    return ( $auth_conn_info ) ? $auth_conn_info : $conn_info;
}

sub set_auth_conn_info {
    my $class       = shift;
    $auth_conn_info = shift;
}

1;

=head1 NAME

Gantry::Utils::DBConnHelper::Script - connection info and dbh cache manager for scripts

=head1 SYNOPSIS

    use Gantry::Utils::DBConnHelper::Script {
        dbconn => 'dbi:Pg:dbname=mydb;host=127.0.0.1',
        dbuser => 'someuser',
        dbpass => 'not_saying',
    };

OR

    use Gantry::Utils::DBConnHelper::Script;

    # ... do something, usually involving figuring out your conn info

    Gantry::Utils::DBConnHelper::Script->set_conn_info( $conn_info_hash_ref );

In either case, if you need httpd authentication (say in CGI):

    Gantry::Utils::DBConnHelper::Script->set_auth_conn_info(
            $auth_conn_hash_ref
    );

=head1 DESCRIPTION

When you use a model which inherits from Gantry::Utils::CDBI or
Gantry::Utils::Model etc., using this module can help with database
connection management.  Feel free to implement your own subclass
of Gantry::Utils::DBConnHelper if you need more control.  That
base class specifies which methods you must implement.

=head1 Normal Connection METHODS

See Gantry::Utils::DBConnHelper for a description of the methods available
here.

Note that only cgi scripts need to worry about the auth methods.
Off line scripts don't need to authenticate through apache.

Here is a list of the methods documented in Gantry::Utils::DBConnHelper.

=over 4

=item get_auth_conn_info

=item get_auth_dbh

=item get_conn_info

=item get_dbh

=item set_auth_conn_info

=item set_auth_dbh

=item set_conn_info

=item set_dbh

=back

=head1 AUTHOR

Phil Crow <philcrow2000@yahoo.com>

=head1 COPYRIGHT and LICENSE

Copyright (c) 2005-6, Tim Keefer.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut
