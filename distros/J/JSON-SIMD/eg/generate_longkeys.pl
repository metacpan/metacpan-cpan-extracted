use JSON::SIMD;

my $k = "a" x 1e5;
my $x = {};
for (1..50) {
	$x->{$k} = $k;
	$k++;
}
print encode_json($x);
