use strict;
use Digest::SHA::PurePerl qw(sha512_hex);

my @vecs = map { eval } <DATA>;

my $numtests = scalar(@vecs) / 2;
print "1..$numtests\n";

my $skip = sha512_hex("") ? 0 : 1;

for (1 .. $numtests) {
	my $data = shift @vecs;
	my $digest = shift @vecs;
	unless ($skip) {
		print "not " unless sha512_hex($data) eq $digest;
	}
	print "ok ", $_, $skip ? " # skip: no 64-bit" : "", "\n";
}

__DATA__
"abc"
"ddaf35a193617abacc417349ae20413112e6fa4e89a97ea20a9eeee64b55d39a2192992a274fc1a836ba3c23a3feebbd454d4423643ce80e2a9ac94fa54ca49f"
"abcdefghbcdefghicdefghijdefghijkefghijklfghijklmghijklmnhijklmnoijklmnopjklmnopqklmnopqrlmnopqrsmnopqrstnopqrstu"
"8e959b75dae313da8cf4f72814fc143f8f7779c6eb9f7fa17299aeadb6889018501d289e4900f7e4331b99dec4b5433ac7d329eeb6dd26545e96e55b874be909"
