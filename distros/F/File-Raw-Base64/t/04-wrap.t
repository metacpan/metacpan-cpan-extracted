use strict;
use warnings;
use Test::More;
use File::Raw::Base64;
use File::Raw qw(import);
use File::Temp qw(tempfile);

# 200 bytes -> ~268 base64 chars; enough to wrap several times at 64 / 76
my $payload = 'x' x 200;

# wrap => 0 (default): single line, no embedded newlines
{
    my ($fh, $p) = tempfile(UNLINK => 1); close $fh;
    file_spew($p, $payload, plugin => 'base64');
    my $enc = do { local (@ARGV, $/) = $p; <> };
    unlike($enc, qr/\n/, 'wrap => 0: no embedded newlines');
}

# wrap => 64: lines split every 64 chars (PEM style)
{
    my ($fh, $p) = tempfile(UNLINK => 1); close $fh;
    file_spew($p, $payload, plugin => 'base64', wrap => 64);
    my $enc = do { local (@ARGV, $/) = $p; <> };
    my @lines = split /\n/, $enc, -1;
    pop @lines if @lines && $lines[-1] eq '';   # trailing newline
    for my $line (@lines[0 .. $#lines - 1]) {
        is(length($line), 64, "wrap => 64: full line is 64 chars");
    }
    cmp_ok(length($lines[-1]), '<=', 64,
        'wrap => 64: last line <= 64 chars');
}

# wrap => 76 (MIME)
{
    my ($fh, $p) = tempfile(UNLINK => 1); close $fh;
    file_spew($p, $payload, plugin => 'base64', wrap => 76);
    my $enc = do { local (@ARGV, $/) = $p; <> };
    my @lines = split /\n/, $enc, -1;
    pop @lines if @lines && $lines[-1] eq '';
    for my $line (@lines[0 .. $#lines - 1]) {
        is(length($line), 76, "wrap => 76: full line is 76 chars");
    }
}

# Decode of wrapped output round-trips
{
    my ($fh, $p) = tempfile(UNLINK => 1); close $fh;
    file_spew($p, $payload, plugin => 'base64', wrap => 64);
    my $back = file_slurp($p, plugin => 'base64');
    is($back, $payload, 'decode strips embedded newlines, round-trips');
}

# Custom eol: \r\n
{
    my ($fh, $p) = tempfile(UNLINK => 1); close $fh;
    file_spew($p, $payload, plugin => 'base64', wrap => 64, eol => "\r\n");
    my $enc = do { local (@ARGV, $/) = $p; <> };
    like($enc, qr/\r\n/, 'eol => "\\r\\n" emits CRLF');
    my $back = file_slurp($p, plugin => 'base64');
    is($back, $payload, 'decode tolerates CRLF line endings');
}

done_testing;
