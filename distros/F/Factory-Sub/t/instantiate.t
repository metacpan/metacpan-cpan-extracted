use Test::More;
use Factory::Sub qw/Str HashRef ArrayRef StrToArray StrToHash HashToArray/;

my $factory = Factory::Sub->new(
	[Str, Str, sub { return 1 }],
	[Str, HashRef, sub { return 2 }],
	[ArrayRef, HashRef, sub { return 3 }]
);

$factory->add(StrToArray->by(', '), StrToHash->by(' '), HashToArray->by('keys'), sub { 
	return $_[1];
});

is($factory->('scalar', 'scalar'), 1);
is($factory->('scalar', { hash => 'ref' }), 2);
is($factory->([qw/a b c/], { hash => 'ref' }), 3);
is_deeply($factory->('a, b, c', 'one two three four', { one => 2 }), { one => 'two', three => 'four' });
done_testing();
