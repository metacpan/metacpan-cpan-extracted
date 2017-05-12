#!/usr/bin/perl

use strict;
BEGIN {
	$| = 1;
	$^W = 1;
}

use Test::More;
use File::Spec::Functions ':ALL';
use File::Remove ();

unless( eval { symlink("",""); 1 } ) {
	plan("skip_all" => "No Unix-like symlinks");
	exit(0);
}

plan( tests => 8 );

# Set up the tests
my $testdir = catdir( 't', 'linktest' );
if ( -d $testdir ) {
	File::Remove::remove( \1, $testdir );
	die "Failed to clear test directory '$testdir'" if -d $testdir;
}
ok( ! -d $testdir, 'Cleared testdir' );
unless( mkdir($testdir, 0777) ) {
	die("Cannot create test directory '$testdir': $!");
}
ok( -d $testdir, 'Created testdir' );
my %links = (
	l_ex   => curdir(),
#	l_ex_a => rootdir(),
	l_nex  => 'does_not_exist'
);
my $errs = 0;
foreach my $link (keys %links) {
	my $path = catdir( $testdir, $link );
	unless( symlink($links{$link}, $path )) {
		diag("Cannot create symlink $link -> $links{$link}: $!");
		$errs++;
	}
}
if ( $errs ) {
	die("Could not create test links");
}

ok( File::Remove::remove(\1, map { catdir($testdir, $_) } keys %links), "remove \\1: all links" );

my @entries;

ok( opendir(DIR, $testdir) );
foreach my $dir ( readdir(DIR) ) {
	next if $dir eq curdir();
	next if $dir eq updir();
	push @entries, $dir;
}
ok( closedir(DIR) );

ok( @entries == 0, "no links remained in directory; found @entries" );

ok( File::Remove::remove(\1, $testdir), "remove \\1: $testdir" );

ok( ! -e $testdir,         "!-e: $testdir" );
