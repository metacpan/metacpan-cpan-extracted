package Gantry::Control::C::AuthenCDBI;
use strict;

use base 'Gantry::Control::C::AuthenBase';
use Gantry::Control::Model::auth_users_cdbi;

sub user_model {
    return 'Gantry::Control::Model::auth_users_cdbi';
}

# EOF
1;

__END__

=head1 NAME 

Gantry::Control::C::AuthenCDBI - AuthenBase subclass for normal ORMs

=head1 SYNOPSIS 

use Gantry::Control::C::AuthenCDBI qw/-Engine=MP20/;

=head1 DESCRIPTION

This module allows authentication against a database.

=head1 METHOD

=over 4

=item user_model

Returns Gantry::Control::Model::auth_users_cdbi.  If you want something else,
try Gantry::Control::C::AuthenRegular or make your own
Gantry::Control::C::AuthenBase subclass.

=back

=head1 APACHE

Sample Apache conf configuration

  <Location /location/to/auth >
    AuthType    Basic
    AuthName    "Manual"
    
    PerlSetVar  auth_dbconn     'dbi:Pg:<database_name>'
    PerlSetVar  auth_dbuser     '<database_user>'
    PerlSetVar  auth_dbpass     '<database_password>'
    
    PerlSetVar  auth_dbcommit   off

    PerlAuthenHandler   Gantry::Control::C::AuthenCDBI

    require     valid-user
  </Location>

=head1 DATABASE 

This is the table that will be queried for the authentication of the
user. 

  create table "auth_users" (
    "id"            int4 default nextval('auth_users_seq') NOT NULL,
    "user_id"       int4,
    "active"        bool,
    "user_name"     varchar,
    "passwd"        varchar,
    "crypt"         varchar,
    "first_name"    varchar,
    "last_name"     varchar,
    "email"         varchar
  );

=head1 METHODS

=over 4

=item handler

The mod_perl authen handler.

=back

=head1 SEE ALSO

Gantry::Control::C::Authz(3), Gantry::Control(3), Gantry(3)

=head1 AUTHOR

Phil Crow <philcrow2000@yahoo.com>

=head1 COPYRIGHT

Copyright (c) 2006, Tim Keefer.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut
