#!perl
# Entry payload mechanics: slurp memoisation, read($n) partial pulls,
# _skip when payload not consumed.
use 5.010;
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use File::Raw::Archive;

my $dir = tempdir(CLEANUP => 1);
my $tar = "$dir/payload.tar";

my $payload_a = "A" x 10000;
my $payload_b = join('', map { chr(($_ % 95) + 32) } 1 .. 5000);

my $w = File::Raw::Archive->create($tar);
$w->add(name => 'a.bin', content => $payload_a);
$w->add(name => 'b.bin', content => $payload_b);
$w->add(name => 'c.bin', content => 'tiny');
$w->add(name => 'd.bin', content => 'last');
$w->close;

# slurp memoises: calling twice returns the same bytes without
# re-reading from the archive.
{
    my $r = File::Raw::Archive->open($tar);
    my $e = $r->next;
    is($e->name, 'a.bin', 'first entry name');
    my $first  = $e->slurp;
    my $second = $e->slurp;
    is($first,  $payload_a, 'slurp pulls full payload');
    is($second, $payload_a, 'second slurp returns same bytes');
    ok($first eq $second, 'two slurps yield equal scalars');
    $r->close;
}

# read($n) pulls partial bytes, repeated calls drain to EOF.
{
    my $r = File::Raw::Archive->open($tar);
    my $e = $r->next;        # a.bin
    my $chunk1 = $e->read(1024);
    is(length $chunk1, 1024, 'read(1024) returned 1024 bytes');
    my $chunk2 = $e->read(2048);
    is(length $chunk2, 2048, 'read(2048) returned 2048 bytes');
    is(substr($payload_a, 0, 1024),         $chunk1, 'first chunk matches');
    is(substr($payload_a, 1024, 2048),      $chunk2, 'second chunk matches');
    # Continue advancing - $r->next should drain whatever is left.
    my $next = $r->next;
    is($next->name, 'b.bin', 'next() advances past unread payload');
    is($next->slurp, $payload_b, 'b.bin payload intact');
    $r->close;
}

# _skip discards payload without slurping; subsequent next() lands on
# the right entry. (The Reader's auto-drain on next() exercises this
# path internally; here we call it explicitly.)
{
    my $r = File::Raw::Archive->open($tar);
    my $e1 = $r->next;
    $e1->_skip;
    my $e2 = $r->next;
    is($e2->name, 'b.bin', '_skip then next lands on next entry');
    $e2->_skip;
    my $e3 = $r->next;
    is($e3->name, 'c.bin', 'second _skip + next');
    is($e3->slurp, 'tiny', 'tiny payload still readable after multiple _skips');
    $r->close;
}

# read past EOF returns empty string.
{
    my $r = File::Raw::Archive->open($tar);
    my $e = $r->next;
    my $all = $e->read(1_000_000);
    is(length $all, 10000, 'oversize read clamps to entry size');
    is($all, $payload_a, 'oversize read content matches');
    my $more = $e->read(100);
    is($more, '', 'read after EOF returns empty string');
    $r->close;
}

done_testing;
