use strict;
use warnings;
use Test::More;
use File::Raw::Base64;
use File::Raw qw(import);
use File::Temp qw(tempfile);

# Default: padding is on, matching RFC 4648
{
    my ($fh, $p) = tempfile(UNLINK => 1); close $fh;
    file_spew($p, 'f', plugin => 'base64');
    my $enc = do { local (@ARGV, $/) = $p; <> };
    is($enc, 'Zg==', 'default padding produces "Zg=="');
}

# padding => 0: strip trailing '='
{
    my ($fh, $p) = tempfile(UNLINK => 1); close $fh;
    file_spew($p, 'f', plugin => 'base64', padding => 0);
    my $enc = do { local (@ARGV, $/) = $p; <> };
    is($enc, 'Zg', 'padding => 0 strips trailing "="');
}

# Decoder is always tolerant of missing padding
{
    my ($fh, $p) = tempfile(UNLINK => 1);
    print $fh 'Zg';
    close $fh;
    my $b = file_slurp($p, plugin => 'base64');
    is($b, 'f', 'decoder accepts missing padding');
}

# URL-safe + no padding (the JWT idiom): round-trip
{
    my $payload = "Hello, JWT!";
    my ($fh, $p) = tempfile(UNLINK => 1); close $fh;
    file_spew($p, $payload,
        plugin   => 'base64url',
        padding  => 0,
    );
    my $enc = do { local (@ARGV, $/) = $p; <> };
    unlike($enc, qr/=/, 'urlsafe + padding=0: no "=" in output');

    my $back = file_slurp($p, plugin => 'base64url');
    is($back, $payload, 'urlsafe + padding=0 round-trip');
}

done_testing;
