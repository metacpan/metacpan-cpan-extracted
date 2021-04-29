use Test::More;
use Hash::RestrictedKeys;

my $hash = Hash::RestrictedKeys->new(qw/one two three/);

$hash->{one} = 1;
$hash->{two} = 2;
$hash->{three} = 3;

is($hash->{one}, 1);
is($hash->{two}, 2);
is($hash->{three}, 3);

eval { $hash->{four} = 'kaput' };
like($@, qr/Invalid key four. Allowed keys: one, two, three/);

done_testing;

