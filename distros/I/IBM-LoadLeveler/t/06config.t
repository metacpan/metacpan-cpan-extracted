# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

use Test::More;
use IBM::LoadLeveler;



# Skip all tests if 02query.t failed, no point running tests if you
# cant get a basic query setup.

if ( -f "SKIP_TEST_LOADLEVELER_NOT_RUNNING" )
{
	plan( skip_all => 'failed basic query, check LoadLeveler running ?');
}
else
{
	plan( tests => 2);
}

#########################

my $version=ll_version();
1 while $version=~s/\.(\d)\./.0$1./g;
$version=~s/\.(\d)$/.0$1/;
$version=~s/\.//g;
$version=~s/^0(\d+)/$1/;

SKIP:
{
	skip('Only Supported in version 3.4 or higher',2) if $version < 3040000;
	
	my $read=ll_read_config();

	ok( $read == API_OK, "ll_read_config - Config Read OK" );

	my $changed=ll_config_changed();

	ok( $changed == 0, "ll_config_changed - Config Not Changed" );
}
