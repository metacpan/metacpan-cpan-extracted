#!/usr/bin/perl

use strict;
use warnings;
use IO::All;
use Kwiki::Kwiki;
use File::Temp qw/tempfile tempdir/;
use Test::More;

if($ENV{KwikiKwikiTestAll}) {
    plan tests => 3;
} else {
    plan skip_all => "Heavy test, only developer want to do this. Define \$KwikiKwikiTestAll env var if you want to run this test.";
}

# Prepare a fake local module dir

my $local_module_dir = tempdir ( CLEANUP => 1 );
io->catfile($local_module_dir, "lib", "Baz.pm")->assert->println("1;");

#

my $dir = tempdir( CLEANUP => 1 );
print STDERR "[!!!] Test dir is $dir\n";

chdir($dir);


# Init KK in it# my $kk = Kwiki::Kwiki->make_init;

Kwiki::Kwiki->make_init;

# Change srouce list to only a minimum set for testing

io->catfile(qw(kwiki sources list))->print(<<SLIST);
=== svn
--- http://svn.kwiki.org/ingy/Kwiki
=== inc
--- UNIVERSAL.pm
=== local
--- $local_module_dir
SLIST

### Test if make_src() copy over them to kwiki/src

Kwiki::Kwiki->make_src();

ok(io->catfile(qw(kwiki src svn Kwiki lib Kwiki.pm))->exists);
ok(io->catfile(qw(kwiki src inc lib UNIVERSAL.pm))->exists);
ok(io->catfile(qw(kwiki src local lib Baz.pm))->exists);
