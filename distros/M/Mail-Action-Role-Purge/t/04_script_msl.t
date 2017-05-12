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

mkdir 'aliases' unless -d 'aliases';

END
{   
    rmtree 'aliases' unless @ARGV;
}

my $role = 'Mail::Action::Role::Purge';
use_ok( $role ) or exit;

my $module = 'Mail::SimpleList::Aliases';
use_ok( $module ) or exit;

use_ok('Class::Roles');
Class::Roles->import(
    apply => {
        role => 'Purge',
        to   => 'Mail::SimpleList::Aliases'
    },
);

can_ok( $module, 'new' );
my $aliases = $module->new( 'aliases' );
isa_ok( $aliases, $module );

# create five objects, all of which are expired
my $time = time();
my $increment = 60*60;
for( 1..5 ) {
    my $addy = Mail::SimpleList::Alias->new(
        expires => $time - ($increment + $_),
    );
    $aliases->save(
        $addy,
        generate_address(),
    );
}

# make sure that we have five aliases
is( $aliases->num_objects, 5, 'five aliases exist');

# create five objects without expire times
for( 1..5 ) {
    my $addy = Mail::SimpleList::Alias->new;
    $aliases->save(
        $addy,
        generate_address(),
    );
}

# make sure that we have ten aliases
is( $aliases->num_objects, 10, 'ten aliases exist');

# run the purge script
my $script = File::Spec->catfile(
    File::Spec->catdir("..", "bin"),
    "mail_simplelist_purge.pl",
);
my $rc = system("$^X -Mblib $script -v ./aliases");
is( $rc, 0, "purge script ran successfully");

# make sure we have five aliases
is( $aliases->num_objects, 5, 'five aliases exist');

# sub yanked from Mail::TempAddresses::Addresses since M::SL doesn't
# have an equivalent
sub generate_address
{

	my $id ||= sprintf '%x', reverse scalar time;

	while ($aliases->exists( $id ))
	{
		$id = sprintf '%x', ( reverse ( time() + rand($$) ));
	}

	return $id;
}

