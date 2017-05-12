use strict;
use Digest::SHA3 qw(sha3_224_hex);

# ref. http://www.di-mgt.com.au/sha_testvectors.html

my @vecs = map { eval } <DATA>;

my $numtests = scalar(@vecs) / 2;
print "1..$numtests\n";

for (1 .. $numtests) {
	my $data = shift @vecs;
	my $digest = shift @vecs;
	print "not " unless sha3_224_hex($data) eq $digest;
	print "ok ", $_, "\n";
}

__DATA__
"abc"
"e642824c3f8cf24ad09234ee7d3c766fc9a3a5168d0c94ad73b46fdf"
"abcdbcdecdefdefgefghfghighijhijkijkljklmklmnlmnomnopnopq"
"8a24108b154ada21c9fd5574494479ba5c7e7ab76ef264ead0fcce33"
"a" x 1000000
"d69335b93325192e516a912e6d19a15cb51c6ed5c15243e7a7fd653c"
