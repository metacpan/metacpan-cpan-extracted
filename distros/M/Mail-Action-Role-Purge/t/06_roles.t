#!/usr/bin/perl
#
# $Id: 06_roles.t 155 2004-12-27 04:19:23Z james $
#

use strict;
use warnings;

BEGIN
{
    chdir 't' if -d 't';
    use lib '../lib', '../blib/lib';
}

use strict;

use Test::More tests => 12;

use File::Path;

mkdir 'addresses' unless -d 'addresses';

END
{   
    rmtree 'addresses' unless @ARGV;
}

use Test::Role;
    
use_ok('Mail::TempAddress::Addresses');
use_ok('Mail::Action::Role::Purge');
use_ok('Class::Roles');
Class::Roles->import(
    apply => {
        role => 'Purge',
        to   => 'Mail::TempAddress::Addresses'
    },
);
does_ok('Mail::TempAddress::Addresses', 'Purge');
can_ok('Mail::TempAddress::Addresses', 'object_names');
can_ok('Mail::TempAddress::Addresses', 'num_objects');
can_ok('Mail::TempAddress::Addresses', 'delete_from_storage');

my $addys = Mail::TempAddress::Addresses->new( 'addresses' );
isa_ok( $addys, 'Mail::TempAddress::Addresses');
does_ok( $addys, 'Purge');
can_ok( $addys, 'object_names');
can_ok( $addys, 'num_objects');
can_ok( $addys, 'delete_from_storage');

#
# EOF

