use strict;
use warnings;
use FindBin;
use lib "t/lib","lib","$FindBin::Bin/../blib/lib","$FindBin::Bin/../blib/arch";
use Test::More;
use JSON::XS;
use Data::Dumper;

our $JSONX = JSON::XS->new->utf8;

use Digest::Guava qw(guava_hash);

my $testdata = do {
	my $filename = 't/testdata.json';
	open my $f, '<', $filename or die "Failed to open file $filename: $!";
  	local $/ = undef;
	my $data = <$f>;
	close($f);
	
	$JSONX->decode($data);
};

for my $input (@$testdata) {
	# warn Dumper $input;
	my ($state, $n_buckets, $expected_hash) = @$input;
	my $result = guava_hash($state, $n_buckets);
	my $description = "($state, $n_buckets) => $expected_hash vs $result";
	is $result, $expected_hash, $description;
}

done_testing();
