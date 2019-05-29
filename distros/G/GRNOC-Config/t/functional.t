use strict;
use Test::Simple tests=>19;
use Data::Dumper;
use GRNOC::Config; 

my $config = GRNOC::Config->new(config_file => "etc/example.xml", force_array => 0);
ok(defined $config, "load config");

my $result = $config->get("/config/db/credentials");
ok(defined $result, "Retrieved Config");
ok($result->{'user'} eq 'readonly');
ok($result->{'password'} eq 'password');


my $result2 = $config->get2("/config/db/credentials");
ok(defined $result2, "Retreived Config");

my $bad = $config->get("/config/db/test");
ok(!(defined($bad)), "Bad path graceful");
my $error = $config->get_error();
ok($error->{'msg'} eq '/config/db/test does not exist in the config', "return an error if path does not exist");

my $user = $config->get('/config/db/credentials[1]/@user');
ok(defined $user, "user defined");
ok($user eq 'readonly', "get the user");

my $text = $config->get('/config/yet');
ok(defined $text, "text defined");
ok($text eq 'again', "text check");

#turn on force array
$config->{'force_array'} = 1;

my $user_array = $config->get('/config/db/credentials[1]/@user');
ok(defined $user_array, "user_array defined");
ok(@{$user_array}[0] eq 'readonly', "get the user in the array");

my $creds = $config->get('/config/db/credentials');
ok(defined $creds, "creds defined");
ok(@{$creds}[0]->{'user'} eq 'readonly', "user check");
ok(@{$creds}[0]->{'password'} eq 'password', "password check");

my $textarr = $config->get('/config/tester');
ok(defined $textarr, "array text defined");
ok(@{$textarr}[0] eq 'this is', "array text check");
ok(@{$textarr}[1] eq 'an array', "array text check");
