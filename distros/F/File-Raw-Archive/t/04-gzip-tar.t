#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);

eval { require File::Raw::Gzip; 1 }
    or plan skip_all => 'File::Raw::Gzip required for compression';
use File::Raw::Archive;

my $dir = tempdir(CLEANUP => 1);
my $path = "$dir/test.tar.gz";

# Build a .tar.gz via our writer.
my $w = File::Raw::Archive->create($path, compression => 'gzip', level => 9);
$w->add(name => 'one.txt',   content => 'first entry');
$w->add(name => 'two.txt',   content => "x" x 4096);
$w->add(name => 'three.txt', content => "y" x 8192);
$w->close;

ok(-s $path > 0, '.tar.gz produced (' . (-s $path) . ' bytes)');

# Read back through gzip auto-detect.
my $r = File::Raw::Archive->open($path);
my @entries;
while (my $e = $r->next) {
    push @entries, { name => $e->name, content => $e->slurp };
}
$r->close;

is(scalar @entries, 3, '3 entries from .tar.gz');
is($entries[0]{name}, 'one.txt', 'first name');
is($entries[0]{content}, 'first entry', 'first content');
is($entries[1]{content}, "x" x 4096, 'second content');
is($entries[2]{content}, "y" x 8192, 'third content');

# Force compression => 'gzip' on read.
my $r2 = File::Raw::Archive->open($path, compression => 'gzip');
my $first = $r2->next;
is($first->name, 'one.txt', 'force gzip mode reads first entry');
$r2->close;

done_testing;
