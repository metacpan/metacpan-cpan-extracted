use strict;
use Test::Simple tests=>4;
use Data::Dumper;
use GRNOC::Config; 

my $config = GRNOC::Config->new(config_file => "etc/does-not-exist.xml");
ok(defined($config), "load non existing config");
my $error = $config->get_error();
ok($error->{'msg'} eq "File does not exist!! Unable to initialize config", "error message file doesn't exist");

$config = GRNOC::Config->new(config_file => '');
ok(defined($config), "load no config");
$error = $config->get_error();
ok($error->{'msg'} eq "No File to parse!! Unable to initialize config","error message no file" ); 


