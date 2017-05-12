package Gantry::Utils::AuthCDBI;
use strict; use warnings;

use base 'Class::DBI::Sweet';

# note we ask for auth_db_Main to be imported, but it comes in as db_Main
use Gantry::Utils::ModelHelper qw(
    auth_db_Main
    get_form_selections
    retrieve_all_for_main_listing
);

my $db_options = { __PACKAGE__->_default_attributes };

__PACKAGE__->_remember_handle('Main');

sub get_db_options {
    return $db_options;
}

#-------------------------------------------------
# db_Main
#-------------------------------------------------   
# This method supplied by Gantry::Utils::ModelHelper

#-------------------------------------------------
# $class->get_form_selctions
#-------------------------------------------------
# This method supplied by Gantry::Utils::ModelHelper

#-------------------------------------------------
# $class->retrieve_all_for_main_listing
#-------------------------------------------------
# This method supplied by Gantry::Utils::ModelHelper

1;

=head1 NAME

Gantry::Utils::AuthCDBI - Class::DBI base model for Gantry Auth

=head1 SYNOPSIS

This module expects to retrieve the database connection,
username and password from the apache conf file like this:

<Location / >
    PerlOptions +GlobalRequest
    
    PerlSetVar auth_dbconn 'dbi:Pg:[database]'
    PerlSetVar auth_dbuser 'myuser'
    PerlSetVar auth_dbpass 'mypass'
</Location>

Or, from the cgi engines constructor:

    my $cgi = Gantry::Engine::CGI->new(
        locations => ...,
        config => {
            auth_dbconn =>  'dbi:Pg:[database]',
            auth_dbuser =>  'myuser',
            auth_dbpass =>  'mypass',
        }
    );

Or, from a script:

    #!/usr/bin/perl

    use Gangtry::Utils::DBConnHelper::Script;

    Gangtry::Utils::DBConnHelper::Script->set_auth_db_conn(
        {
            auth_dbconn =>  'dbi:Pg:[database]',
            auth_dbuser =>  'myuser',
            auth_dbpass =>  'mypass',
        }
    );

=head1 DESCRIPTION

This module provide the base methods for Class::DBI, including the db
connection through Gantry::Utils::ModelHelper (and its friends in
the Gantry::Utils::DBConnHelper family).

=head1 METHODS

=over 4

=item get_db_options

Returns the dbi connection options, which are usually supplied by Class::DBI's
_default_attributes method.

=back

=head1 AUTHOR

Tim Keefer <tkeefer@gmail.com>

=head1 COPYRIGHT and LICENSE

Copyright (c) 2005-6, Tim Keefer.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut
