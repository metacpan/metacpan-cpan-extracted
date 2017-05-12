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

my $dir = tempdir( CLEANUP => 1 );
print STDERR "[!!!] Test dir is $dir\n";

chdir($dir);

# Init KK

Kwiki::Kwiki->make_init;

# Fake some .pm under source/lib
io->catfile(qw(kwiki sources list))->assert->print(<<FAKE);
=== cpan
--- Acme
=== inc
--- Foo.pm
--- Foo/Bar.pm
FAKE

io->catfile('plugins')->print("#\n")->close;

io->catfile(qw(kwiki src inc lib Foo.pm))->assert->println("1;");
io->catfile(qw(kwiki src inc lib Foo Bar.pm))->assert->println("1;");

### Test if make_lib() copy over them to lib/

Kwiki::Kwiki->make_lib();

ok(io->catfile(qw(lib Acme.pm))->exists, "Acme.pm installed");
ok(io->catfile(qw(lib Foo.pm))->exists, "Foo.pm copied");
ok(io->catfile(qw(lib Foo Bar.pm))->exists, "Foo/Bar.pm copied");
