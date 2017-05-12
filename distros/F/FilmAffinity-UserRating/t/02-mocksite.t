use strict;
use warnings;

use Test::More tests => 3;
use File::Find::Rule;

use lib 't/';

use_ok('MockSite');

my $url = MockSite::mockLocalSite('t/resources/filmaffinity-local-site');
like ($url, qr/^file:\/\/\//, 'local file url');
$url =~s/^file:\/\/\///;
my @tmp = File::Find::Rule->file()->name('*.html')->in($url);
is(scalar(@tmp), 3, 'count html files');
