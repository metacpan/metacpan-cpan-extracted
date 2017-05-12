#!/bin/perl

BEGIN {print "1..4\n";}
END {print "not ok 1\n" unless $loaded;}
use File::RsyncP::Digest;
$loaded = 1;
print "ok 1\n";

my $rsDigest = new File::RsyncP::Digest;
my $data = ("a" x 700) . ("b" x 700) . ("c" x 600);
my $digest = $rsDigest->blockDigest($data, 700, 2, 0x12345678);

if ( unpack("H*", $digest) eq "3c09a624641bf80b0ce3abd208e8645d5b49" ) {
    print "ok 2\n";
} else {
    print "not ok 2\n";
}

my $state = $rsDigest->blockDigest($data, 700, -1, 0);
$digest = $rsDigest->blockDigestUpdate($state, 700,
                                length($data) % 700, 2, 0x12345678);

if ( unpack("H*", $digest) eq "3c09a624641bf80b0ce3abd208e8645d5b49" ) {
    print "ok 3\n";
} else {
    print "not ok 3\n";
}

my $digest16 = $rsDigest->blockDigest($data, 700, 16, 0x12345678);
$digest = $rsDigest->blockDigestExtract($digest16, 2);

if ( unpack("H*", $digest) eq "3c09a624641bf80b0ce3abd208e8645d5b49" ) {
    print "ok 4\n";
} else {
    print "not ok 4\n";
}

