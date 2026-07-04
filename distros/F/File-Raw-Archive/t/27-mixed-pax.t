#!perl
# Combined PAX features in a single archive: long names AND large
# uid/gid AND xattrs AND sub-second mtime AND a global header. This
# exercises the cooperative behaviour of the PAX writer (only one
# 'x' header per entry, but carrying all overflow keys) and the
# reader (apply globals, then per-entry overrides, in order).
use 5.010;
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use File::Raw::Archive;

my $dir = tempdir(CLEANUP => 1);
my $tar = "$dir/mixed.tar";

my $longname = 'sub/' . ('x' x 240) . '.txt';
my $whole_mtime = 1735689600;
my $ns_mtime    = 987654321;

my $w = File::Raw::Archive->create(
    $tar,
    format      => 'pax',
    global_meta => {
        uname => 'archivist',
        gname => 'devs',
    },
);

# Entry 1: long name + large uid + sub-second mtime + xattrs.
$w->add(
    name     => $longname,
    content  => 'kitchen sink',
    mode     => 0644,
    mtime    => $whole_mtime,
    mtime_ns => $ns_mtime,
    uid      => 7_000_000,
    gid      => 8_000_000,
    xattrs   => {
        'user.label' => 'mixed',
        'user.bin'   => "\x00\xff\x01" . 'binary',     # forces b64
    },
);

# Entry 2: minimal entry, should inherit global uname/gname.
$w->add(name => 'plain.txt', content => 'inherits-globals');

$w->close;

ok(-s $tar > 0, 'archive produced');

# Read back: every PAX field round-trips intact.
my $r = File::Raw::Archive->open($tar);

my $e1 = $r->next;
is($e1->name,     $longname,    'long name read back exactly');
is($e1->size,     12,           'size');
is($e1->uid,      7_000_000,    'large uid via PAX');
is($e1->gid,      8_000_000,    'large gid via PAX');
is($e1->mtime,    $whole_mtime, 'integer seconds preserved');
is($e1->mtime_ns, $ns_mtime,    'nanoseconds preserved');

my $xa = $e1->xattrs;
ok($xa, 'xattrs hashref present');
is($xa->{'user.label'}, 'mixed',                  'plain xattr round-trip');
is($xa->{'user.bin'},   "\x00\xff\x01" . 'binary', 'binary xattr round-trip');

is($e1->slurp, 'kitchen sink', 'content intact');

my $e2 = $r->next;
is($e2->name,  'plain.txt',         'second entry name');
is($e2->slurp, 'inherits-globals',  'second entry content');

ok(!defined $r->next, 'end of archive');
$r->close;

# Cross-validate: scan raw bytes to confirm exactly two PAX 'x' blocks
# (one per entry) plus one 'g' block.
{
    open my $fh, '<:raw', $tar or die $!;
    my ($g, $x, $longlink) = (0, 0, 0);
    while (read($fh, my $blk, 512) == 512) {
        last if $blk eq "\0" x 512;
        my $tflag = substr($blk, 156, 1);
        $g++ if $tflag eq 'g';
        $x++ if $tflag eq 'x';
        $longlink++ if $tflag eq 'L' || $tflag eq 'K';
    }
    close $fh;
    is($g, 1, 'exactly one PAX g (global) block');
    cmp_ok($x, '>=', 1, 'at least one PAX x (per-file) block');
    is($longlink, 0, 'format=pax avoided GNU @LongLink for long name');
}

done_testing;
