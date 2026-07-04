#!perl
# Compression auto-detection on read. Default behaviour: sniff the
# first two bytes for gzip magic (0x1f 0x8b); if absent, treat as
# uncompressed. Explicit compression options bypass the sniff.
use 5.010;
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use File::Raw::Archive;

my $dir = tempdir(CLEANUP => 1);

# Build a plain tar and a gzipped tar with the same contents.
my @entries = (
    [ 'one.txt'   => 'first'  ],
    [ 'two.txt'   => 'second' ],
    [ 'three.txt' => 'third'  ],
);

my $plain = "$dir/plain.tar";
{
    my $w = File::Raw::Archive->create($plain);
    $w->add(name => $_->[0], content => $_->[1]) for @entries;
    $w->close;
}

my $gz = "$dir/wrapped.tar.gz";
{
    my $w = File::Raw::Archive->create($gz, compression => 'gzip');
    $w->add(name => $_->[0], content => $_->[1]) for @entries;
    $w->close;
}

# Sanity: bytes 0-1 of $gz are the gzip magic.
{
    open my $fh, '<:raw', $gz or die $!;
    read($fh, my $magic, 2);
    close $fh;
    is(unpack('H*', $magic), '1f8b', 'gz file starts with gzip magic');
}

# --- Read paths ---

# Plain tar with no compression option: auto-sniffs, sees no magic,
# reads as plain.
{
    my $rows = File::Raw::Archive->list($plain);
    is(scalar @$rows, 3, 'plain auto-sniff: 3 entries');
    is($rows->[0]{name}, 'one.txt', 'plain: first name');
}

# Gzip tar with no compression option: auto-sniffs, sees magic, decompresses.
{
    my $rows = File::Raw::Archive->list($gz);
    is(scalar @$rows, 3, 'gz auto-sniff: 3 entries');
    is($rows->[1]{name}, 'two.txt', 'gz: second name');
    is($rows->[2]{name}, 'three.txt', 'gz: third name');
}

# Explicit compression => 'auto' is identical to default behaviour.
{
    my $rows = File::Raw::Archive->list($gz, compression => 'auto');
    is(scalar @$rows, 3, 'compression=auto on gz: 3 entries');
}
{
    my $rows = File::Raw::Archive->list($plain, compression => 'auto');
    is(scalar @$rows, 3, 'compression=auto on plain: 3 entries');
}

# Explicit compression => 'gzip' on a plain tar: tries to decompress
# bytes that aren't gzip and croaks.
{
    my $err;
    eval { File::Raw::Archive->list($plain, compression => 'gzip'); 1 } or $err = $@;
    ok($err, 'compression=gzip on plain tar croaks');
}

# Explicit compression => 'none' on a gz file: skips sniff, hands raw
# gz bytes to the tar parser, which sees garbage and croaks.
{
    my $err;
    eval { File::Raw::Archive->list($gz, compression => 'none'); 1 } or $err = $@;
    ok($err, 'compression=none on .tar.gz croaks (gz bytes not tar)');
}

# Each iteration over a .tar.gz works without explicit compression.
my @names;
File::Raw::Archive->each($gz, sub { push @names, $_[0]->name });
is_deeply(\@names, ['one.txt', 'two.txt', 'three.txt'],
    'each() auto-sniffs gz on read');

done_testing;
