use Test::More;
use Hash::RestrictedKeys;

my $hash = Hash::RestrictedKeys->new(qw/one two three/);

$hash->{one} = 1;
$hash->{two} = 2;
$hash->{three} = 3;

for my $key (keys %{$hash}) {
	like($key, qr/one|two|three/, "expected $key");
}

is(exists $hash->{one}, 1);

is(delete $hash->{one}, 1);

is(scalar %{$hash}, 2);

ok(!(undef %{$hash}));

done_testing;

