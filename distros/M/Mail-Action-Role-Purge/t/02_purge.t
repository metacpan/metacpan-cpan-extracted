#!/usr/bin/perl -w

BEGIN
{
    chdir 't' if -d 't';
    use lib '../lib', '../blib/lib';
}

use strict;

use Test::More tests => 21;

use File::Path;

mkdir 'addresses' unless -d 'addresses';

END
{   
    rmtree 'addresses' unless @ARGV;
}

my $role = 'Mail::Action::Role::Purge';
use_ok( $role ) or exit;

my $module = 'Mail::TempAddress::Addresses';
use_ok( $module );

use_ok('Class::Roles');
Class::Roles->import(
    apply => {
        role => 'Purge',
        to   => 'Mail::TempAddress::Addresses'
    },
);

can_ok( $module, 'new' );
my $addys = $module->new( 'addresses' );
isa_ok( $addys, $module );

# make sure no addresses exist
is( $addys->num_objects, 0, 'no addresses exist');

# create five objects, none of which expire yet
my $time = time();
my $increment = 60*60;
for( 1..5 ) {
    my $addy = Mail::TempAddress::Address->new(
        expires => $time + ($increment + $_),
    );
    $addys->save(
        $addy,
        $addys->generate_address(),
    );
}

# make sure that we have five addresses
is( $addys->num_objects, 5, 'five addresses exist');

# attempt to purge
my $purged = $addys->purge();
is( $purged, 0, 'nothing purged' );

# make sure that we still have five addresses
is( $addys->num_objects, 5, 'five addresses exist');

# create five objects, all of which are expired
for( 1..5 ) {
    my $addy = Mail::TempAddress::Address->new(
        expires => $time - ($increment + $_),
    );
    $addys->save(
        $addy,
        $addys->generate_address(),
    );
}

# make sure that we have ten addresses
is( $addys->num_objects, 10, 'ten addresses exist');

# create five objects, all of which expired a long
# time ago
$increment = 60*60*24;
for( 1..5 ) {
    my $addy = Mail::TempAddress::Address->new(
        expires => $time - ($increment + $_),
    );
    $addys->save(
        $addy,
        $addys->generate_address(),
    );
}

# make sure that we have fifteen addresses
is( $addys->num_objects, 15, 'fifteen addresses exist');

# try to purge with a minimum of a half day
$purged = $addys->purge( 60*60*24 );
is( $purged, 5, 'five addresses purged' );

# make sure that we have ten addresses
is( $addys->num_objects, 10, 'ten addresses exist');

# create five objects, all of which expired a long
# time ago
$increment = 60*60*24;
for( 1..5 ) {
    my $addy = Mail::TempAddress::Address->new(
        expires => $time - ($increment + $_),
    );
    $addys->save(
        $addy,
        $addys->generate_address(),
    );
}

# make sure that we have fifteen addresses
is( $addys->num_objects, 15, 'fifteen addresses exist');

# try to purge with a minimum of a half day using freeform syntax
$purged = $addys->purge( '12h' );
is( $purged, 5, 'five addresses purged' );

# make sure that we have ten addresses
is( $addys->num_objects, 10, 'ten addresses exist');

# do a purge without a minimum
$purged = $addys->purge();
is( $purged, 5, 'five addresses purged');
 
# make sure that we have five addresses
is( $addys->num_objects, 5, 'five addresses exist');

# create five objects without expire times
for( 1..5 ) {
    my $addy = Mail::TempAddress::Address->new;
    $addys->save(
        $addy,
        $addys->generate_address(),
    );
}

# make sure that we have ten addresses
is( $addys->num_objects, 10, 'ten addresses exist');

# attempt to purge
$purged = $addys->purge();
is( $purged, 0, 'nothing purged' );

# make sure that we still have ten addresses
is( $addys->num_objects, 10, 'ten addresses exist');
