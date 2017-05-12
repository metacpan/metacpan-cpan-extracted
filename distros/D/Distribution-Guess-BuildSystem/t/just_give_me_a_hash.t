#!/usr/bin/perl
use strict;
use warnings;

use Test::More 'no_plan';
use Cwd;
use File::Spec::Functions qw(catfile);

my $class = 'Distribution::Guess::BuildSystem';

use_ok( $class );

can_ok( $class, 'just_give_me_a_hash' );

my $start_dir = cwd();

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
{
my @dirs = (
	't/test-distros/makemaker-true',
	't/test-distros/module-build-compat',
	't/test-distros/module-install-autoinstall'
	);

my $guesser = $class->new;
isa_ok( $guesser, $class );

foreach my $dir ( @dirs )
	{
	$^W = 0;
	
	my $name = catfile( split m|/|, $dir );
	#diag( "directory is $name\n" );
	ok( -d $name, "directory [$name] exists" );
	
	ok( chdir $name, "changed into test directory" );
	
	
	my $hash = $guesser->just_give_me_a_hash;
	isa_ok( $hash, ref {} );
	
	ok( chdir $start_dir, "back into original directory" );
	}
}

