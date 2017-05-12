#!/usr/bin/perl
use strict;
use warnings;

use Lib::Furl qw(:funcs);

my $url    = 'https://github.com/stricaud/faup';
my $urlLen = length($url);

my $fh = furl_init();

my $ret = furl_decode($fh, $url, $urlLen);
print "furl_decode ret[$ret]\n";

print furl_show($fh, ',', *STDOUT),"\n";

my $size = furl_get_host_size($fh);
print "host_size: $size\n";

furl_terminate($fh);
