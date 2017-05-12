use strict;
use warnings;

use lib 't/';
use File::Find::Rule;

use Test::More tests => 3;

use_ok('MockSite');

my $url = MockSite::mockLocalSite('t/resources/t-gone');
like ($url, qr/^file:\/\/\//, 'local file url');
$url =~s/^file:\/\/\///;
my @tmp = File::Find::Rule->file()->name('*.html')->in($url);
is(scalar(@tmp), 3, 'count html files');
