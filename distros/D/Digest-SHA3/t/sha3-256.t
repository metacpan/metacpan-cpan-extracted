use strict;
use Digest::SHA3 qw(sha3_256_hex);

my @vecs = map { eval } <DATA>;

my $numtests = scalar(@vecs) / 2;
print "1..$numtests\n";

for (1 .. $numtests) {
	my $data = shift @vecs;
	my $digest = shift @vecs;
	print "not " unless sha3_256_hex($data) eq $digest;
	print "ok ", $_, "\n";
}

__DATA__
"abc"
"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532"
"abcdbcdecdefdefgefghfghighijhijkijkljklmklmnlmnomnopnopq"
"41c0dba2a9d6240849100376a8235e2c82e1b9998a999e21db32dd97496d3376"
"a" x 1000000
"5c8875ae474a3634ba4fd55ec85bffd661f32aca75c6d699d0cdcb6c115891c1"
