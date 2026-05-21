use strict;
use warnings;
use Test::More;
use File::Raw::Base64;
use File::Raw qw(import);
use File::Temp qw(tempfile);

# URL-safe alphabet: + and / become - and _ respectively.
# Pick an input that forces both substitutions.
# 0xfb,0xff,0xbf encodes to "+/+/" in standard alphabet -> "-/-_" in URL-safe...
# Actually let's compute by example: bytes 0xff,0xff,0xff -> "////" std,
# "____" urlsafe. Bytes 0xfb,0xef,0xbe -> "++++" std maybe; let's use a
# simple known triple: any byte combo whose low 6 bits include both 62
# and 63.
#
# Cleanest test: encode the same payload via both plugins and verify the
# expected character substitutions.

my $payload = "\xff\xff\xff" .            # all 1 bits -> "////"
              "\xfb\xef\xbe";              # bits flipped to land on 62 indices

my ($f1, $p1) = tempfile(UNLINK => 1); close $f1;
my ($f2, $p2) = tempfile(UNLINK => 1); close $f2;

file_spew($p1, $payload, plugin => 'base64');
file_spew($p2, $payload, plugin => 'base64url');

my $std = do { local (@ARGV, $/) = $p1; <> };
my $url = do { local (@ARGV, $/) = $p2; <> };

# URL-safe is the same as standard with + -> -, / -> _
(my $expected = $std) =~ tr{+/}{-_};
is($url, $expected, 'base64url alphabet substitution: + -> -, / -> _');

# Round-trip via base64url
my ($f3, $p3) = tempfile(UNLINK => 1);
print $f3 $url; close $f3;
my $got = file_slurp($p3, plugin => 'base64url');
is($got, $payload, 'base64url decode round-trip');

# urlsafe option on the standard plugin overrides the alphabet
my ($f4, $p4) = tempfile(UNLINK => 1); close $f4;
file_spew($p4, $payload, plugin => 'base64', urlsafe => 1);
my $forced = do { local (@ARGV, $/) = $p4; <> };
is($forced, $expected,
    'base64 plugin + urlsafe => 1 produces URL-safe alphabet');

done_testing;
