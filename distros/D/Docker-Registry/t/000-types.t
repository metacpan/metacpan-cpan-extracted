use warnings;
use strict;

use Test::More;

use Docker::Registry::Types qw(DockerRegistryURI);
use URI;

my $uri = URI->new();
ok(DockerRegistryURI->check($uri), "isa URI");
ok(DockerRegistryURI->coerce('https://foo.bar.nl'), "coerced URI");


done_testing;
