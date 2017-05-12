#!/usr/bin/perl -w

# Test File::Tasks::Provider

use strict;
use File::Spec::Functions ':ALL';

# Execute the tests
use Test::More tests => 11;
use File::Find::Rule ();
use File::Tasks      ();
use constant FFR => 'File::Find::Rule';

my $delete_dir = catdir( 't', 'data', 'delete' );
ok( -d $delete_dir, "Found 'delete' test directory" );

# If we are executing this test inside of a SVN checkout, we need
# to make sure that we don't accidentally include SVN folders.
my $Rule;
if ( -d catdir( $delete_dir, '.svn' ) ) {
	$Rule = FFR->or(
		FFR->directory->name('.svn')->prune->discard,
		FFR->new,
		)->file;
}





#####################################################################
# Create a new File::Tasks

{
my $Script = File::Tasks->new;
isa_ok( $Script, 'File::Tasks' );
is( $Script->remove_dir( $delete_dir, $Rule ), 3,
	'->delete_dir returns the correct number of files remove' );
is( scalar($Script->paths), 3, 'Correct number of Tasks added' );
is( scalar($Script->tasks), 3, 'Correct number of Tasks added' );
}





#####################################################################
# Check for ignore support.

{
my $Ignore = FFR->or(
	FFR->directory->name('.svn'),
	FFR->file->name('one.*'),
	);
isa_ok( $Ignore, FFR );
my $Script = File::Tasks->new( ignore => $Ignore );
isa_ok( $Script, 'File::Tasks' );
isa_ok( $Script->ignore, 'File::Find::Rule' );
is( $Script->remove_dir( $delete_dir, $Rule ), 2,
	'->delete_dir returns the correct number of files for remove' );
is( scalar($Script->paths), 2, 'Correct number of Tasks added' );
is( scalar($Script->tasks), 2, 'Correct number of Tasks added' );
}

exit(0);


my $Ignore = FFR->file->name('one.*');
isa_ok( $Ignore, FFR );


sub invert_ffr {
	my $ffr = shift;
	return FFR->or(
		$ffr->prune->discard,
		FFR->new,
		);
}