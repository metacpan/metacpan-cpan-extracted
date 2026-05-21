#!perl
use 5.008003;
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use File::Raw qw(import);
use File::Raw::Gzip;

my $dir = tempdir(CLEANUP => 1);

# A valid gzip blob to use for decode-side checks.
my $valid = "$dir/valid.gz";
file_spew($valid, "hello", plugin => 'gzip');

sub croaks_like {
    my ($code, $rx, $name) = @_;
    my $err;
    eval { $code->(); 1 } or $err = $@;
    ok(defined $err, "$name: croaked");
    like($err, $rx, "$name: error matches");
}

croaks_like(
    sub { file_slurp($valid, plugin => 'gzip', no_such_key => 1) },
    qr/unknown option/,
    'unknown option key',
);

croaks_like(
    sub { file_spew("$dir/x.gz", "x", plugin => 'gzip', level => 99) },
    qr/level must be 0\.\.9/,
    'level out of range',
);

croaks_like(
    sub { file_spew("$dir/x.gz", "x", plugin => 'gzip', level => -1) },
    qr/level must be 0\.\.9/,
    'level negative',
);

croaks_like(
    sub { file_slurp($valid, plugin => 'gzip', mode => 'wat') },
    qr/mode must be one of/,
    'bad mode string',
);

croaks_like(
    sub { file_spew("$dir/x.gz", "x", plugin => 'gzip', mode => 'auto') },
    qr/File::Raw::Gzip/,
    'mode=auto rejected on encode',
);

croaks_like(
    sub { file_spew("$dir/x.gz", "x", plugin => 'gzip', mem_level => 0) },
    qr/mem_level must be 1\.\.9/,
    'mem_level too low',
);

croaks_like(
    sub { file_spew("$dir/x.gz", "x", plugin => 'gzip', mem_level => 10) },
    qr/mem_level must be 1\.\.9/,
    'mem_level too high',
);

croaks_like(
    sub { file_slurp($valid, plugin => 'gzip', chunk_size => 0) },
    qr/chunk_size must be/,
    'chunk_size zero',
);

croaks_like(
    sub { file_slurp($valid, plugin => 'gzip', chunk_size => -5) },
    qr/chunk_size must be/,
    'chunk_size negative',
);

croaks_like(
    sub { file_spew("$dir/x.gz", "x", plugin => 'gzip', strategy => 'nope') },
    qr/strategy must be one of/,
    'bad strategy name',
);

# Sanity: the valid blob still decodes after all those failed calls.
is(file_slurp($valid, plugin => 'gzip'), "hello",
    'plugin still works after a series of croaks');

done_testing;
