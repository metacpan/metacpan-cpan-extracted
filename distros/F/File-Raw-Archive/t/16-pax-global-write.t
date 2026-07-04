#!perl
# PAX 'g' global header emission via the global_meta create option:
# subsequent entries inherit the global keys until overridden by a
# per-file 'x' header.
use 5.010;
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use File::Raw::Archive;

my $dir = tempdir(CLEANUP => 1);
my $tar = "$dir/global.tar";

my $w = File::Raw::Archive->create(
    $tar,
    global_meta => {
        uname => 'lee',
        gname => 'staff',
    },
);
$w->add(name => 'one.txt', content => 'A', uid => 501, gid => 20);
$w->add(name => 'two.txt', content => 'B', uid => 501, gid => 20);
$w->close;

ok(-s $tar > 0, 'archive produced');

# Find the 'g' header by scanning the raw bytes for typeflag 'g'.
# The typeflag is at offset 156 of every 512-byte tar block.
{
    open my $fh, '<:raw', $tar or die $!;
    my $found_g = 0;
    while (read($fh, my $block, 512) == 512) {
        last if $block eq "\0" x 512;
        my $tflag = substr($block, 156, 1);
        $found_g++ if $tflag eq 'g';
    }
    close $fh;
    is($found_g, 1, 'exactly one PAX global header emitted');
}

# Reading back: the entries should still iterate cleanly. (The reader
# accumulates the global keys but our XS layer doesn't expose uname/
# gname on the entry hashref - global keys are applied via PAX-record
# parsing; smoke-check by ensuring the regular entries are intact.)
my $r = File::Raw::Archive->open($tar);
my @names;
while (my $e = $r->next) {
    push @names, $e->name;
    $e->slurp;
}
$r->close;
is_deeply(\@names, ['one.txt', 'two.txt'], 'entries readable past global header');

done_testing;
