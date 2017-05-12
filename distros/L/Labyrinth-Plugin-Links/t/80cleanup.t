#!/usr/bin/perl -w
use strict;

use lib qw(t/lib);
use Fake::Loader;

use Test::More tests => 1;

my $loader = Fake::Loader->new;
my $dir = $loader->directory;

$loader->cleanup();

if($^O =~ /Win32/i) {   # Windows cannot delete until after process has stopped
    ok(1);
} else {
    ok( ! -d $dir,   'directory removed' );
}
