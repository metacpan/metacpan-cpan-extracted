# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Helios.t'

# 2012-08-04:  Changed config tests to use (and test) new Helios::Config 
# instead of Helios::Service->getConfigFromIni().  Also changed Helios::Service
# tests to instantiate a service object using direct instead of indirect 
# object notation.  Also added test of Helios::Service->prep() method.
# [LH] [2015-08-14]: Changed all CRLF endings to Unix-style LF endings.

#########################

use Test::More;
unless ( defined($ENV{HELIOS_INI}) ) {
	plan skip_all => '$HELIOS_INI not defined';
} else {
	plan tests => 7;
}


#########################


# let's try to read the INI file and connect to the helios database
# (HELIOS_INI needs to be set for that)

# first check configuration
use_ok('Helios::Config');

my $config_class = Helios::Config->init();
isa_ok($config_class, 'Helios::Config');
ok ( $config_class->parseConfig(), 'parsing configuration'); 
my $conf = $config_class->getConfig();
ok( defined($conf->{dsn}), 'dsn for collective database');

# now test base service class
use_ok('Helios::Service');
$service = Helios::Service->new();
isa_ok($service, 'Helios::Service');
ok ( $service->prep(), 'prep()ing service');

