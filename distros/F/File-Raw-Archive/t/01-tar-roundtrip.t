#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use File::Raw::Archive;

my $dir = tempdir(CLEANUP => 1);
my $path = "$dir/test.tar";

my $w = File::Raw::Archive->create($path);
$w->add(name => 'a.txt', content => 'hello world',     mode => 0644);
$w->add(name => 'b.txt', content => "x" x 5000,        mode => 0644);
$w->add(name => 'sub/');
$w->add(name => 'sub/c.txt', content => "nested\n",    mode => 0600);
$w->close;

ok(-s $path > 0, 'tarball produced (' . (-s $path) . ' bytes)');

my $r = File::Raw::Archive->open($path);
my @entries;
while (my $e = $r->next) {
    push @entries, {
        name => $e->name,
        size => $e->size,
        mode => $e->mode,
        type => $e->type,
        content => $e->is_file ? $e->slurp : undef,
    };
}
$r->close;

is(scalar @entries, 4, '4 entries');
is($entries[0]{name}, 'a.txt', 'first entry name');
is($entries[0]{content}, 'hello world', 'first entry content');
is($entries[1]{size}, 5000, 'second entry size');
is($entries[1]{content}, "x" x 5000, 'second entry content');
ok($entries[2]{type} == File::Raw::Archive::AE_DIR, 'sub/ is a directory');
is($entries[3]{name}, 'sub/c.txt', 'nested entry name');
is($entries[3]{content}, "nested\n", 'nested entry content');

done_testing;
