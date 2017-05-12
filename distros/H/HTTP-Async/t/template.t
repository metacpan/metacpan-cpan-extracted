
use strict;
use warnings;

use Test::More skip_all => 'just a template to base other tests on';

use Test::More tests => 5;

use HTTP::Async;
my $q = HTTP::Async->new;

use FindBin;
use lib "$FindBin::Bin";
require TestServer;

# my $s = TestServer->new;
# my $url_root = $s->started_ok("starting a test server");

my @servers = map { TestServer->new() } 1 .. 4;
foreach my $s (@servers) {
    my $url_root = $s->started_ok("starting a test server");
}
