use Test::More;
use Factory::Sub qw/Str HashRef ArrayRef StrToArray StrToHash HashToArray/;

my $factory = Factory::Sub->new(
	[sub { return 'fallback' }],
	[sub { @_ }, sub { return 'undef'; } ],
	[Str, Str, sub { return 1 }],
	[Str, HashRef, sub { return 2 }],
	[ArrayRef, HashRef, sub { return 3 }]
);

$factory->add(StrToArray->by(', '), StrToHash->by(' '), HashToArray->by('keys'), sub { 
	return $_[1];
});

is($factory->(undef), 'undef' ); 
is($factory->('scalar', 'scalar'), 1);
is($factory->('scalar', { hash => 'ref' }), 2);
is($factory->([qw/a b c/], { hash => 'ref' }), 3);
is_deeply($factory->('a, b, c', 'one two three four', { one => 2 }), { one => 'two', three => 'four' });
is($factory->(undef, undef, undef), 'fallback');

$factory->add(undef);

eval {
	$factory->(undef, undef, undef);
};

like($@, qr/No matching factory sub for given params undef undef undef/);

done_testing();
