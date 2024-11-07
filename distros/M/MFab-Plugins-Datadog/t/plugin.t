use strict;
use warnings;

use Test::More;
use Test::Mojo;
use FindBin;
use lib "$FindBin::Bin";
use MFab::Plugins::Datadog;
use Mock::Mojo::UserAgent;

Mock::Mojo::UserAgent::apply();

my $app = Test::Mojo->new('Mock::Webserver');

$app->get_ok('/')->content_is("this is an endpoint\n");
is(scalar(@Mock::Mojo::UserAgent::puts), 1, "made a put request");
is($Mock::Mojo::UserAgent::puts[0][1], 'http://localhost:8126/v0.3/traces', "put request to correct endpoint");

Mock::Mojo::UserAgent::reset();

done_testing();
