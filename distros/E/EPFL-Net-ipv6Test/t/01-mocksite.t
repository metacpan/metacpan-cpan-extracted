# (c) ECOLE POLYTECHNIQUE FEDERALE DE LAUSANNE, Switzerland, VPSI, 2018.
# See the LICENSE file for more details.

use strict;
use warnings;

use lib 't/';
use File::Find::Rule;

use Test::More tests => 3;

use_ok('MockSite');

my $url = MockSite::mockLocalSite('t/resources/ipv6-test');
like( $url, qr/^file:\/\/\//xms, 'local file url' );
$url =~ s/^file:\/\/\///xms;
my @tmp = File::Find::Rule->file()->name('*.json')->in($url);
is( scalar(@tmp), 6, 'count json files' );
