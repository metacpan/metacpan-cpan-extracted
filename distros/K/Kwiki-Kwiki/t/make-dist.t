#!/usr/bin/perl

use strict;
use warnings;
use IO::All;
use Kwiki::Kwiki;
use Archive::Tar;
use File::Temp qw/tempfile tempdir/;
use Test::More;
use File::Basename;

plan tests => 3;

my $dir = tempdir( CLEANUP => 1 );
print STDERR "[!!!] Test dir is $dir\n";

chdir($dir);

# Init KK in it
my $distname = basename($dir).".tar.gz";
Kwiki::Kwiki->make_init;

# Generate a lib/Foo.pm, so it would be Archived by calling KK->make_dist();
io->catfile("lib","Foo.pm")->assert->print("1;\n");

Kwiki::Kwiki->make_dist();
ok(io($distname)->exists, "A tarball is generated");
ok(io($distname)->size > 0, "Has non-zero size");

my $tar = Archive::Tar->new();
$tar->read($distname);
ok($tar->contains_file("Kwiki-Kwiki/lib/Foo.pm"), "It has Foo.pm inside");
