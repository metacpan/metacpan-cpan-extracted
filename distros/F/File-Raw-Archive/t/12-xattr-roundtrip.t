#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use File::Raw::Archive;

my $dir = tempdir(CLEANUP => 1);
my $tar = "$dir/xattr.tar";

my $w = File::Raw::Archive->create($tar);
$w->add(name => 'plain.txt',
        content => 'plain xattr',
        xattrs  => {
            'user.label' => 'foo',
            'user.tag'   => 'release',
        });
$w->add(name => 'binary.txt',
        content => 'binary xattr',
        xattrs  => {
            'user.bin'  => "\x00\xff\x01hello\n",   # contains NUL/newline -> b64
        });
$w->close;

my $r = File::Raw::Archive->open($tar);
while (my $e = $r->next) {
    if ($e->name eq 'plain.txt') {
        my $xa = $e->xattrs;
        ok($xa, 'plain entry has xattrs');
        is($xa->{'user.label'}, 'foo', 'plain user.label round-trip');
        is($xa->{'user.tag'},   'release', 'plain user.tag round-trip');
    }
    elsif ($e->name eq 'binary.txt') {
        my $xa = $e->xattrs;
        ok($xa, 'binary entry has xattrs');
        is($xa->{'user.bin'}, "\x00\xff\x01hello\n",
            'binary xattr round-trips bit-exact via base64');
    }
    $e->slurp;
}
$r->close;

done_testing;
