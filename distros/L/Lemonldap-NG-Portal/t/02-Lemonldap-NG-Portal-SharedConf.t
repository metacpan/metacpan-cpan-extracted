# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Lemonldap-NG-Portal-SharedConf.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 2;
BEGIN { use_ok('Lemonldap::NG::Portal::SharedConf') }

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

# Try to load an alternate conffile
use File::Temp;
my $dir = File::Temp::tempdir();
my $ini = File::Temp->new( DIR => $dir );

print $ini "[all]

[configuration]
type=File
dirName=$dir

[portal]
portalSkin = test
";

$ini->flush();

open( CONF, ">$dir/lmConf-1" ) or die $@;

print CONF "
cfgNum
	1

useXForwardedForIP
	0

key
	tmp

";

CONF->flush();

my $portal = Lemonldap::NG::Portal::SharedConf->new(
    {
        globalStorage => 'Apache::Session::File',
        domain        => 'example.com',
        configStorage => { confFile => "$ini" },
    }
);

my $test = $portal->{portalSkin};

ok( $test eq "test", "Custom INI file" );

