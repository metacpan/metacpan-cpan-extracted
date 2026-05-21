#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
use File::Raw;
use File::Temp qw(tempdir);

# File::Raw doesn't statically enforce the type contract (every plugin
# except the LAST in a READ chain must return bytes). What we DO test
# here is that when a plugin further down the chain receives a
# non-byte SV (because an upstream plugin returned a structured ref),
# the failure surfaces as a clear runtime error from the downstream
# plugin — not as a silent corruption or a memory bug. Plugins that
# accept anything via SvPV will tolerate refs (Perl stringifies refs
# to "ARRAY(0x...)"), so we use a strict downstream that rejects
# refs explicitly.

my $dir = tempdir(CLEANUP => 1);

# Producer: returns a structured arrayref (not bytes).
File::Raw::register_plugin('to_array', {
    read => sub { my ($p, $b, $o) = @_; return [ split //, $b ] },
});

# Consumer: insists on a non-ref scalar; mirrors the kind of guard a
# byte-transform plugin (gzip, base64) should have.
File::Raw::register_plugin('strict_bytes_consumer', {
    read => sub {
        my ($p, $bytes, $o) = @_;
        die "strict_bytes_consumer: expected bytes, got " . ref($bytes) . " ref\n"
            if ref $bytes;
        return uc $bytes;
    },
});

my $f = "$dir/x.txt";
File::Raw::spew($f, 'abc');

subtest 'structured plugin in non-final READ slot fails clearly' => sub {
    eval {
        File::Raw::slurp($f,
            plugin => ['to_array', 'strict_bytes_consumer']);
    };
    like($@, qr/expected bytes, got ARRAY ref/,
        'downstream plugin sees the structured ref and complains');
};

subtest 'structured plugin in FINAL slot is fine' => sub {
    my $rows = File::Raw::slurp($f, plugin => ['strict_bytes_consumer', 'to_array']);
    is_deeply($rows, ['A', 'B', 'C'],
        'last plugin can return any shape; uppercase bytes split into chars');
};

done_testing;
