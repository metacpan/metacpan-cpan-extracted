use strict;
use warnings;
use Test::More;
use File::Raw::Base64;
use File::Raw qw(import);
use File::Temp qw(tempfile);

# Empty input round-trips to empty output (both directions)
{
    my ($fh, $p) = tempfile(UNLINK => 1); close $fh;
    file_spew($p, '', plugin => 'base64');
    my $enc = do { local (@ARGV, $/) = $p; <> };
    $enc = '' unless defined $enc;
    is($enc, '', 'encode empty -> empty');

    my $b = file_slurp($p, plugin => 'base64');
    is($b, '', 'decode empty -> empty');
}

# Larger-than-default-buffer round-trip. We deliberately stay modest
# (512 KiB) and build the payload via a tiny deterministic LCG instead
# of `pack 'C*', map { ... } 1..N` - the map-list approach builds an
# N-element list of Perl scalars before pack runs, which exhausted
# small VMs on the OpenBSD smoke testers (per CPAN report 127da502
# and friends, Aug 2026 - SIGKILL on this very test). 512 KiB encodes
# to ~684 KiB of output and exercises the realloc-growth path of
# out_reserve() without stressing the install-time machine.
{
    my $size = 512 * 1024;
    my $payload = '';
    my $s = 1;
    while (length($payload) < $size) {
        $s = ($s * 1103515245 + 12345) & 0x7fffffff;
        $payload .= chr($s & 0xff);
    }
    is(length($payload), $size, "$size-byte deterministic blob built");

    my ($fh, $p) = tempfile(UNLINK => 1); close $fh;
    file_spew($p, $payload, plugin => 'base64');
    my $back = file_slurp($p, plugin => 'base64');
    ok($back eq $payload, "$size-byte round-trip preserves all bytes");
}

done_testing;
