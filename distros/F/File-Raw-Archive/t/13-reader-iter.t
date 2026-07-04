#!perl
# Manual Reader iteration: $r = open; while ($e = $r->next) { ... }; $r->close.
# Exercises the per-entry XS API rather than the high-level each/list helpers.
use 5.010;
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use File::Raw::Archive;

my $dir = tempdir(CLEANUP => 1);
my $tar = "$dir/iter.tar";

my $w = File::Raw::Archive->create($tar);
$w->add(name => 'one.txt',   content => 'first');
$w->add(name => 'two.txt',   content => 'second');
$w->add(name => 'three.txt', content => 'third');
$w->close;

# Manual iteration via Reader object.
my $r = File::Raw::Archive->open($tar);
isa_ok($r, 'File::Raw::Archive::Reader', 'open returns a Reader');

my $first = $r->next;
isa_ok($first, 'File::Raw::Archive::Entry', 'next returns an Entry');
is($first->name, 'one.txt', 'first entry name');

my $second = $r->next;
is($second->name, 'two.txt', 'second entry name');

my $third = $r->next;
is($third->name, 'three.txt', 'third entry name');

my $eof = $r->next;
ok(!defined $eof, 'next returns undef at end-of-archive');

$r->close;
ok(1, 'close completed without error');

# Calling next on a closed reader croaks.
my $r2 = File::Raw::Archive->open($tar);
$r2->close;
my $err;
eval { $r2->next; 1 } or $err = $@;
ok($err, 'next on closed reader croaks');

# Idempotent close.
my $r3 = File::Raw::Archive->open($tar);
$r3->close;
eval { $r3->close; 1 } or fail("second close croaked: $@");
ok(1, 'close is idempotent');

# Reader DESTROY runs cleanly when the Reader goes out of scope without
# explicit close - just open one and let it drop, no asserts beyond no
# warnings/errors.
{
    my $r4 = File::Raw::Archive->open($tar);
    $r4->next;
    # No explicit close; DESTROY should run when $r4 leaves scope.
}
ok(1, 'Reader DESTROY runs cleanly without explicit close');

done_testing;
