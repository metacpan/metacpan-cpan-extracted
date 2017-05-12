package Gantry::Control::C::AuthzCDBI;
use strict;

use base 'Gantry::Control::C::AuthzBase';

use Gantry::Control::Model::auth_users_cdbi;
use Gantry::Control::Model::auth_group_members_cdbi;
use Gantry::Control::Model::auth_groups_cdbi;

sub user_model {
    return 'Gantry::Control::Model::auth_users_cdbi';
}

sub group_members_model {
    return 'Gantry::Control::Model::auth_group_members_cdbi';
}

# EOF
1;

__END__

=head1 NAME 

Gantry::Control::C::AuthzCDBI - Database based authorization for Class::DBI.

=head1 SYNOPSIS

  use Gantry::Control::C::AuthzCDBI qw/-Engine=MP20/;

=head1 DESCRIPTION

This is a simple database driven autorization system for use with apps
which rely on Class::DBI (or one of its descendents).  If you use a different
ORM, you probably want Gantry::Control::C::AuthzRegular instead of this
module.  This module also details the other Authz modules in the library.

=head1 METHODS

=over 4

=item user_model

Returns Gantry::Control::Model::auth_users_cdbi.  If you want something else,
try Gantry::Control::C::AuthenRegular or make your own
Gantry::Control::C::AuthzBase subclass.

=item group_members_model

Returns Gantry::Control::Model::group_members_cdbi.  If you want something
else, try Gantry::Control::C::AuthzRegular or make your own
Gantry::Control::C::AuthzBase subclass.

=back

=head1 APACHE

Sample Apache conf configuration.

  <Perl>
     use Gantry::Control::C::AuthzCDBI qw/-Engine=MP20/;
  </Perl>
  
  <Location /location/to/auth >
    AuthType    Basic
    AuthName    "Manual"

    PerlSetVar  auth_dbconn     'dbi:Pg:dbname=...'
    PerlSetVar  auth_dbuser     '<database_user>'
    PerlSetVar  auth_dbpass     '<database_password>'
    
    PerlSetVar  auth_dbcommit   off

    PerlAuthzHandler  Gantry::Control::C::AuthzCDBI

    require     group "group_to_require"
  </Location>

=head1 DATABASE 

These are the tables that will be queried for the authorization of the
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

  create table "auth_groups" (
    "id"            int4 default nextval('auth_groups_seq') NOT NULL,
    "ident"         varchar,
    "name"          varchar,
    "description"   text
  );

  create table "auth_group_members" (
    "id"        int4 default nextval('auth_group_members_seq') NOT NULL,
    "user_id"   int4,
    "group_id"  int4    
  );

  create table "auth_pages" (
    "id"          int4 default nextval('auth_pages_seq') NOT NULL,
    "user_perm"   int4,
    "group_perm"  int4,
    "owner_id"    int4,
    "group_id"    int4,
    "uri"         varchar,
    "title"       varchar
  );

=head1 MODULES

=over 4

=item Gantry::Control::C::AuthzCDBI::PageBased

This handler is the authorization portion for page based authorization.
It is controlled by Gantry::Control::C::Pages(3) and will authenticate only
users who have been allowed from the administrative interface into a
particular uri. The module returns FORBIDDEN if you do not have access
to a particular uri.

=back

=head1 METHODS

=over 4

=item handler

The mod_perl authz handler.

=back

=head1 SEE ALSO

Gantry::Control::C::Authen(3), Gantry::Control(3), Gantry(3)

=head1 LIMITATIONS


=head1 AUTHOR

Tim Keefer <tkeefer@gmail.com>
Nicholas Studt <nstudt@angrydwarf.org>

=head1 COPYRIGHT

Copyright (c) 2005-6, Tim Keefer.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut
