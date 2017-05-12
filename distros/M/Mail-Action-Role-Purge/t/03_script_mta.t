#!/usr/bin/perl -w

use Test::More tests => 9;

BEGIN
{
    chdir 't' if -d 't';
    use lib '../lib', '../blib/lib';
}

use strict;

use File::Path;
use File::Spec;

mkdir 'addresses' unless -d 'addresses';

END
{   
    rmtree 'addresses' unless @ARGV;
}

my $role = 'Mail::Action::Role::Purge';
use_ok( $role ) or exit;

my $module = 'Mail::TempAddress::Addresses';
use_ok( $module ) or exit;

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

# create five objects, all of which are expired
my $time = time();
my $increment = 60*60;
for( 1..5 ) {
    my $addy = Mail::TempAddress::Address->new(
        expires => $time - ($increment + $_),
    );
    $addys->save(
        $addy,
        $addys->generate_address(),
    );
}

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

# run the purge script
my $script = File::Spec->catfile(
    File::Spec->catdir("..", "bin"),
    "mail_tempaddress_purge.pl",
);
my $rc = system("$^X -Mblib $script -v ./addresses");
is( $rc, 0, "purge script ran successfully");

# make sure we have five addresses
is( $addys->num_objects, 5, 'five addresses exist');
