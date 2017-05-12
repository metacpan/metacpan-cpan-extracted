use strict;
use Digest::SHA3 qw(sha3_384_hex);

my @vecs = map { eval } <DATA>;

my $numtests = scalar(@vecs) / 2;
print "1..$numtests\n";

for (1 .. $numtests) {
	my $data = shift @vecs;
	my $digest = shift @vecs;
	print "not " unless sha3_384_hex($data) eq $digest;
	print "ok ", $_, "\n";
}

__DATA__
"abc"
"ec01498288516fc926459f58e2c6ad8df9b473cb0fc08c2596da7cf0e49be4b298d88cea927ac7f539f1edf228376d25"
"abcdbcdecdefdefgefghfghighijhijkijkljklmklmnlmnomnopnopq"
"991c665755eb3a4b6bbdfb75c78a492e8c56a22c5c4d7e429bfdbc32b9d4ad5aa04a1f076e62fea19eef51acd0657c22"
"a" x 1000000
"eee9e24d78c1855337983451df97c8ad9eedf256c6334f8e948d252d5e0e76847aa0774ddb90a842190d2c558b4b8340"
