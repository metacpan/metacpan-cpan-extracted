#!perl
# Error-path coverage for the public class methods. Each croak path
# should produce a clear message rather than silently corrupt or hang.
use 5.010;
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use File::Raw::Archive;

my $dir = tempdir(CLEANUP => 1);

# Build a small valid archive for the read-side tests.
my $valid = "$dir/valid.tar";
{
    my $w = File::Raw::Archive->create($valid);
    $w->add(name => 'ok.txt', content => 'ok');
    $w->close;
}

sub croaks_like {
    my ($code, $rx, $name) = @_;
    my $err;
    eval { $code->(); 1 } or $err = $@;
    ok(defined $err, "$name: croaked")
        or diag "expected croak, got nothing";
    return unless defined $err;
    like($err, $rx, "$name: message matches");
}

# open: nonexistent path
croaks_like(
    sub { File::Raw::Archive->open("$dir/no-such.tar") },
    qr/cannot open/,
    'open() on nonexistent path',
);

# list: odd number of options
croaks_like(
    sub { File::Raw::Archive->list($valid, 'extra') },
    qr/odd number of options/,
    'list() with odd options',
);

# extract: missing dest
croaks_like(
    sub { File::Raw::Archive->extract($valid, 'name') },
    qr/Usage|odd|extract/,
    'extract() with too few positional args',
);

# extract_all: too few args
croaks_like(
    sub { File::Raw::Archive->extract_all($valid) },
    qr/Usage|extract_all/,
    'extract_all() with too few args',
);

# each: missing callback
croaks_like(
    sub { File::Raw::Archive->each($valid) },
    qr/Usage|coderef|each/,
    'each() without callback',
);

# each: callback not a coderef
croaks_like(
    sub { File::Raw::Archive->each($valid, 'not-a-sub') },
    qr/coderef|Usage/,
    'each() with non-coderef last arg',
);

# extract_all: refuse '..' path by default
{
    my $bad = "$dir/bad.tar";
    my $w = File::Raw::Archive->create($bad);
    $w->add(name => '../escape.txt', content => 'oops');
    $w->close;
    croaks_like(
        sub { File::Raw::Archive->extract_all($bad, "$dir/extract-dest") },
        qr/unsafe path/,
        'extract_all refuses ".." without unsafe_paths',
    );
}

# Writer::add with format=ustar and overflowing field croaks.
{
    my $tar = "$dir/strict.tar";
    my $w = File::Raw::Archive->create($tar, format => 'ustar');
    croaks_like(
        sub { $w->add(name => 'a' x 200, content => 'x') },
        qr/write failed/,
        'Writer::add croaks on ustar overflow',
    );
    $w->close;
}

# create: unknown plugin name
croaks_like(
    sub { File::Raw::Archive->create("$dir/uk.tar", plugin => 'no-such-plugin') },
    qr/unknown plugin/,
    'create() with unknown plugin name',
);

# Truncated archive: read should croak.
{
    my $trunc = "$dir/trunc.tar";
    open my $fh, '>:raw', $trunc or die $!;
    print $fh "garbage that is not a tar header" x 20;
    close $fh;
    croaks_like(
        sub { File::Raw::Archive->list($trunc) },
        qr/malformed archive/,
        'list() croaks on garbage input',
    );
}

done_testing;
