use Test::More;
use Tie::Hash;
use Hash::ExtendedKeys::Tie;
tie my %ha, 'Hash::ExtendedKeys::Tie';

$ha{one} = 'two';
is ($ha{one}, 'two');

%ha = ();

my $ref = [qw/one two/];
$ha{$ref} = 'three';
is($ha{$ref}, 'three');
for ( keys %ha ) {
	is_deeply($_, $ref);
}

%ha = ();

$ha{{ a => 1 }} = { b => 2, c => 3 };
is_deeply($ha{{a => 1}}, { b => 2, c => 3 });

$ha{{ a => 1 }} = { d => 4 };
is_deeply($ha{{a => 1}}, { d => 4 });

for ( keys %ha ) {
	is_deeply($_, { a => 1});
}

ok(1);
done_testing;
