package Gantry::Control;
use strict;

require Exporter;

use Gantry::Utils::DB;
use Gantry::Utils::SQL;
use Gantry::Utils::Validate;

use vars qw( @ISA @EXPORT );

############################################################
# Variables                                                #
############################################################
@ISA        = qw( Exporter );
@EXPORT     = qw(   dec2bin
                    encrypt
                    get_grnam
                    get_grgid
                    get_pwnam
                    get_pwuid
                    get_usrgrp  );
    
############################################################
# Functions                                                #
############################################################

#-------------------------------------------------
# dec2bin( $bits )
#-------------------------------------------------
sub dec2bin {
    my $bits = shift;

    return( 0, 0, 0 ) if ( ! $bits );

    # Is there a nicer way to do this ?
    return( ( split( '', unpack( 'B32', pack( 'N', $bits ) ) ) )[-3..-1] );
} # END dec2bin

#-------------------------------------------------
# encrypt( $string )
#-------------------------------------------------
sub encrypt {
    my $str = shift;

    # Emulates unix crypt(3)
    my @chars = ( '.', '/', 0..9, 'A'..'Z', 'a'..'z' )[ rand 64, rand 64 ];

    return( crypt( $str, join( '', @chars ) ) );
} # END encrypt 

#-------------------------------------------------
# get_grnam( $dbh, $group_name )
#-------------------------------------------------
sub get_grnam {
    my ( $dbh, $name ) = @_;
    
    # act like C's getgrnam
    my $sth = db_query( $dbh, 'get a groups id', 
                        'SELECT id FROM auth_groups WHERE name = ', 
                        sql_str( $name ) );

    my $gid = db_next( $sth ); 

    db_finish( $sth );

    $gid = 0 if ( ! $gid );

    return( $gid );
} # END get_grnam

#-------------------------------------------------
# get_grgid( $dbh, $gid )
#-------------------------------------------------
sub get_grgid {
    my ( $dbh, $gid ) = @_;
    
    $gid = 0 if ( ! $gid );
    
    # act like C's getgrgid
    my $sth = db_query( $dbh, 'get a groups name', 
                        'SELECT name FROM auth_groups WHERE id = ',
                        sql_num( $gid ) );

    my $gname = db_next( $sth ); 

    db_finish( $sth );

    $gname = '' if ( ! $gname );

    return( $gid );
} # END get_grgid

#-------------------------------------------------
# get_pwnam( $dbh, $name ) 
#-------------------------------------------------
sub get_pwnam {
    my ( $dbh, $name ) = @_;

    my $sth = db_query( $dbh, 'Get users info',
                        'SELECT id, password, first_name, last_name, email, ',
                        'active FROM auth_users WHERE user_name = ',
                        sql_str( $name ) );

    my ( $id, $passwd, $first, $last, $email, $active ) = db_next( $sth );

    db_finish( $sth );  
    
    # act like C's getpwuid 
    return( $id || 0, $active || 0, $passwd || '', $first || '', 
            $last || '', $email || '' );
} # END get_pwnam

#-------------------------------------------------
# get_pwuid( $dbh, $uid )
#-------------------------------------------------
sub get_pwuid {
    my ( $dbh, $uid ) = @_;

    $uid = 0 if ( ! $uid );

    my $sth = db_query( $dbh, 'Get users info',
                        'SELECT user_name, password, first_name, last_name, ',
                        'email, active FROM auth_users WHERE id = ',
                        sql_num( $uid ) );

    my ( $uname, $passwd, $first, $last, $email, $active ) = db_next( $sth );

    db_finish( $sth );  
    
    # act like C's getpwuid 
    return( $uname || '', $active || 0, $passwd || '', $first || '', 
            $last || '', $email || '' );
} # END get_pwuid

#-------------------------------------------------
# get_usrgrp( $dbh, $uid )
#-------------------------------------------------
sub get_usrgrp {
    my ( $dbh, $uid ) = @_;

    my %grp;

    $uid = 0 if ( ! $uid );

    my $sth = db_query( $dbh, 'get groups user is in', 
                        'SELECT auth_groups.id, auth_groups.name FROM ',
                        'auth_groups, auth_group_members WHERE ',
                        'auth_groups.id = auth_group_members.group_id AND ',
                        'auth_group_members.user_id = ', sql_num( $uid ) );

    while ( my ( $gid, $gname ) = db_next( $sth ) ) {
        $grp{$gid} = $gname;
    }

    db_finish( $sth );

    return( \%grp ); # Gets all of a users groups as a hash reference.
} # END get_usrgrp

# EOF
1;

__END__

=head1 NAME 

Gantry::Control - The Core for User Management and Administration

=head1 SYNOPSIS

  use Gantry::Control;

  dec2bin
    ( $one, $two, $three ) = dec2bin( $bits );

  encrypt
    $encrypted = encrypt( $unencripted );

  get_grnam
    $gid = get_grnam( $dbh, $group_name );

  get_grgid
    $group_name = get_grgid( $dbh, $gid );

  get_pwnam
    ( $user_id, $active, $passwd, $first, $last, $email ) = 
      get_pwnam( $dbh, $user_name );

  get_pwuid
    ( $user_name, $active, $passwd, $first, $last, $email ) = 
      get_pwuid( $dbh, $user_id );

  get_usergrp
    $grp = get_usrgrp( $dbh, $uid );

=head1 DESCRIPTION

This module is a library of useful access functions that would be used
in other handlers, it also details the other modules that belong to the
Control tree.

=head1 FUNCTIONS 

=over 4

=item ( $user, $group, $world ) = dec2bin( $bits )

This function decodes three digit permissions used by the page based
authentication and management, the first value in the array is a boolean
of the user permission. The second and third are for group and world
respectively. All values are either '1' for they have permission or '0'
for no permission.

=item $encrypted = encrypt( $unencripted )

This function is just a wrapper to the standard unix crypt so it can be
easily used, and consitantly even.

=item $gid = get_grnam( $dbh, $group_name )

Finds a groups gid based on the group name.

=item $group_name = get_grgid( $dbh, $gid )

Finds a groups name based on the groups id.

=item @user_info = get_pwnam( $dbh, $user_name )

This emulates C's getpwnam save it operates on the database. The return
values are, in this order: Users database id, a boolean for the active
status of the user, the users password ( as kept in the database ), the
users first name, the users last name, and the users email address.

=item @user_info = get_pwuid( $dbh, $user_id )

This emulates C's getpwuid save it operates on the database. The return
values are, in this order: Users username, a boolean for the active
status of the user, the users password ( as kept in the database ), the
users first name, the users last name, and the users email address.

=item $grp = get_usrgrp( $dbh, $uid )

This function takes the database handle and a users id. It returns a
hash reference of group ids to their name that the user is in.

=back

=head1 MODULES

=over 4

=item Gantry::Control::C::Access

=item Gantry::Control::C::AuthenRegular

This module allows authentication against a database. Woo.

=item Gantry::Control::C::AuthzRegular

This is a simple database driven autorization system. This module also
details the other Authz modules in the library.

=item Gantry::Control::C::Groups

This controller module handles all of the group manipulation for 
the authorization and authentication handlers. 

=item Gantry::Control::C::Pages

This controller module is the frontend for the 
Gantry::Control::Authz::PageBased authentication handler. One would 
specify pages as well as the permissions with this frontend module.

=item Gantry::Control::C::Users

This Handler manages users in the database to facilitate the use of that
information for authentication, autorization, and use in applications. 
This replaces the use of htpasswd for user management and puts more
information at the finger tips of the application.

=back

=head1 SCHEMA FOR AUTH TABLES

    create sequence "auth_users";
    create table "auth_users" (
        "id"            int4 default nextval('auth_users_seq'::text) NOT NULL,
        "user_id"       int4 default currval('auth_users_seq') NOT NULL,
        "active"        bool,
        "user_name"     varchar,
        "passwd"        varchar,
        "crypt"         varchar,
        "first_name"    varchar,
        "last_name"     varchar,
        "email"         varchar,
        CONSTRAINT auth_users_pk PRIMARY KEY (user_id)
    );

    create sequence "auth_groups_seq";
    create table "auth_groups" (
        "id"            int4 default nextval('auth_groups_seq'::text) NOT NULL,
        "name"          varchar,
        "ident"         varchar,
        "description"   text
    );

    create sequence "auth_pages_seq";
    create table "auth_pages" (
        "id"            int4 default nextval('auth_pages_seq'::text) NOT NULL,
        "user_perm"     int4,
        "group_perm"    int4,
        "world_perm"    int4,
        "owner_id"      int4,
        "group_id"      int4,
        "uri"           varchar,
        "title"         varchar
    );

    create sequence "auth_group_members_seq";
    create table "auth_group_members" (
        "id" int4 default nextval('auth_group_members_seq'::text) NOT NULL,
        "user_id"   int4,
        "group_id"  int4
    );

=head1 SEE ALSO

Gantry(3)

=head1 AUTHOR

Tim Keefer <tkeefer@gmail.com>
Nick Studt

=head1 COPYRIGHT

Copyright (C) 2005-6, Tim Keefer

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut
