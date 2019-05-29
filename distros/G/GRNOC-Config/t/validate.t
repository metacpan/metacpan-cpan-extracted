use strict;
use Test::Simple tests=>2;
use Data::Dumper;
use GRNOC::Config; 

my $config = GRNOC::Config->new(config_file => "etc/example.xml", force_array => 1, schema => "etc/example_schema.xsd", debug => 1);
ok(defined $config, "load config");

my $res = $config->validate();
ok($res == 1, "Config Validates");

