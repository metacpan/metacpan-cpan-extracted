#!/usr/bin/perl

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 13;
use File::Spec::Functions ':ALL';
use File::Remove ();
use Cwd          ();

# Create the test directories
my $base = Cwd::abs_path(Cwd::cwd());
my $cwd  = rel2abs(catdir('t', 'cwd'));
my $foo  = rel2abs(catdir('t', 'cwd', 'foo'));
my $file = rel2abs(catdir('t', 'cwd', 'foo', 'bar.txt'));
File::Remove::clear($cwd);
mkdir($cwd,0777)  or die "mkdir($cwd): $!";
mkdir($foo,0777)  or die "mkdir($foo): $!";
open( FILE, ">$file" ) or die "open($file): $!";
print FILE "blah\n";
close( FILE ) or die "close($file): $!";
ok( -d $cwd,  "$cwd directory exists" );
ok( -d $foo,  "$foo directory exists" );
ok( -f $file, "$file file exists"     );

# Test that _moveto behaves as expected
SCOPE: {
	is(
		File::Remove::_moveto(
			File::Spec->catdir($base, 't'), # remove
			File::Spec->catdir($base), # cwd
		),
		'',
		'_moveto returns correct for normal case',
	);

	my $moveto1 = File::Remove::_moveto(
		File::Spec->catdir($base, 't'), # remove
		File::Spec->catdir($base, 't'), # cwd
	);
	$moveto1 =~ s/\\/\//g;
	is( $moveto1, $base, '_moveto returns correct for normal case' );

	my $moveto2 = File::Remove::_moveto(
		File::Spec->catdir($base, 't'),        # remove
		File::Spec->catdir($base, 't', 'cwd'), # cwd
	);
	$moveto2 =~ s/\\/\//g;
	is( $moveto2, $base, '_moveto returns correct for normal case' );

	# Regression: _moveto generates false positives
	# cwd:      /tmp/cpan2/PITA-Image/PITA-Image-0.50
	# remove:   /tmp/eBtQxTPGHC
	# moveto:   /tmp
	# expected: ''
	is(
		File::Remove::_moveto(
			File::Spec->catdir($base, 't'),           # remove
			File::Spec->catdir($base, 'lib', 'File'), # cwd
		),
		'',
		'_moveto returns null as expected',
	);
}

# Change the current working directory into the first
# test directory and store the absolute path.
chdir($cwd) or die "chdir($cwd): $!";
my $cwdabs = Cwd::abs_path(Cwd::cwd());
ok( $cwdabs =~ /\bcwd$/, "Expected abs path is $cwdabs" );

# Change into the directory that should be deleted
chdir('foo') or die "chdir($foo): $!";
my $fooabs = Cwd::abs_path(Cwd::cwd());
ok( $fooabs =~ /\bfoo$/, "Deleting from abs path is $fooabs" );

# Delete the foo directory
ok( File::Remove::remove(\1, $foo), "remove($foo) ok" );

# We should now be in the bottom directory again
is( Cwd::abs_path(Cwd::cwd()), $cwdabs, "We are now back in the original directory" );

# Move back to the base dir and confirm everything was deleted.
chdir($base) or die "chdir($base): $!";
ok( ! -e $foo,  "$foo does not exist"  );
ok( ! -e $file, "$file does not exist" );
