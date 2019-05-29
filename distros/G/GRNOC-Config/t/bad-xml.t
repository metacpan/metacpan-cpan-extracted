use strict;
use Test::Simple tests=>3;
use Data::Dumper;
use GRNOC::Config; 

my $config = GRNOC::Config->new(config_file => "etc/bad-xml.xml", force_array => 0);
ok(defined $config, "No Error");

my $error = $config->get_error();
ok(defined($error));

my $test = $config->get("/config/db/");
$error = $config->get_error();
ok(defined($error));
