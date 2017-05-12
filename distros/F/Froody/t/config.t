# Test the config function on Froody::Dispatch

use strict;
use warnings;

use Test::More tests => 3;

use Froody::Dispatch;
use lib 't/lib';

my $client = Froody::Dispatch->config({
  modules => [ 'DTest::Test' ], 
});

my @methods = method_names($client);

ok scalar @methods, "Something is loaded from DTest";

my $apiclient = Froody::Dispatch->config({
  modules => [ 'DTest' ], 
});

is_deeply [ method_names($apiclient) ] , \@methods, "Loading the API works, too";

my $filtered_client = Froody::Dispatch->config({
  modules => [ 'DTest' ], 
  filters => [ 'froody.*.*' ]
});

$TODO = "Figure out why this isn't working";
is scalar method_names($filtered_client), 4, 'Just the reflection methods';

sub method_names {
  my $client = shift;
  sort map { $_->full_name } $client->get_methods
}
