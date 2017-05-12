#!/usr/bin/perl

# Compile-testing for File::UserConfig

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 27;
use File::Spec::Functions ':ALL';
use File::UserConfig ();
use File::Remove 'clear', 'remove';

my $testfrom = catdir( 't', 'testfrom' );
my $testto   = catdir( 't', 'testto'   );

ok( -d $testfrom, 'testfrom exists' );
clear( $testto );
ok( ! -e $testto, "testto doesn't exist" );

# Get a config via another package to avoid freaking out
# _caller.
is( MyFoo::call1(), 'MyFoo', '_caller works' );
is( MyFoo::call2(), 'MyFoo', '_caller isnt confused by subclasses' );

my $config = MyFoo::foo();
isa_ok( $config, 'File::UserConfig' );
is( $config->dist     => 'File-UserConfig', '->dist matches expected' );
is( $config->dirname  => 'testto',          '->dirname matches expected' );
is( $config->sharedir => $testfrom,
	'->sharedir matches expected' );
ok( -d $config->sharedir, '->sharedir exists' );
ok( -d File::ShareDir::dist_dir( $config->dist ), 'Found the default one' );
is( $config->homedir  => 't', '->homedir returns expected' );
ok( -d $config->homedir, '->homedir exists' );
ok( -d File::HomeDir->my_data, 'Could get the REAL data dir' );
is( $config->configdir, catdir( curdir(), $testto ),
	'->configdir matches expected' );
ok( -d $config->configdir, '->configdir exists' );
ok( -f catfile( $config->configdir, 'afile.conf' ),
	'Found expected config file' );
ok( -d catfile( $config->configdir, 'subdir' ),
	'Found expected directory' );
ok( -f catfile( $config->configdir, 'subdir', 'bfile.txt' ),
	'Found expected config file in subdirectory' );
if ( -e $testto ) { remove( \1, $testto ) }

# Repeat using the more defaults
my $config2 = MyFoo::bar();
END {
	if ( $config2 and -e $config2->configdir ) {
		remove( \1, $config2->configdir );
	}
}
isa_ok( $config2, 'File::UserConfig' );
is( $config2->dist     => 'File-UserConfig', '->dist matches expected' );
ok( -d $config2->sharedir, '->sharedir exists' );
is( $config2->homedir  => 't', '->homedir returns expected' );
ok( -d $config2->homedir, '->homedir exists' );
ok( $config2->configdir, '->configdir returned' );
ok( -d $config2->configdir, '->configdir exists' );
ok( -f catfile( $config2->configdir, 'afile.conf' ),
	'Found expected config file' );
ok( ! -d catfile( $config2->configdir, 'subdir' ),
	'Found expected directory' );
if ( $config2 and -d $config2->configdir ) {
	remove( \1, $config2->configdir );
}

exit(0);

package MyFoo;

sub foo {
	return File::UserConfig->new(
		dist     => 'File-UserConfig',
		dirname  => 'testto',
		sharedir => $testfrom,
		homedir  => 't',
		);
}

sub bar {
	return File::UserConfig->new(
		dist     => 'File-UserConfig',
		module   => 'File::UserConfig',
		homedir  => 't',
		);
}

sub call1 { File::UserConfig->_caller() }
sub call2 { MyConfig->_caller()         }

package MyConfig;

use base 'File::UserConfig';

sub dummy { 1 }

1;
