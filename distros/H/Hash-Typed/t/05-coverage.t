use Test::More;

use Hash::Typed;

use Types::Standard qw/Int/;

eval {
	tie (
		my %test, 
		'Hash::Typed', 
		[ strict => 1, required => [qw/one two three/], keys => [ one => Int, two => Int, three => Int ] ],
		three => 3, two => 2
	);
};

like("$@", qr/Required key one not set./); 

eval {
	tie (
		my %test, 
		'Hash::Typed', 
		[ strict => 1, required => [qw/one two three/], keys => {} ],
		three => 3, two => 2, one => 1
	);
};

like("$@", qr/keys spec must currently be an ARRAY/); 

tie (
	my %test, 
	'Hash::Typed', 
	[ strict => 1, required => [qw/one two three/], keys => [ one => Int, two => Int, three => Int ] ],
	three => 3, two => 2, one => 1
);

ok(!(delete $test{four}));

ok(delete $test{one});

ok(scalar %test);

ok(!(undef %test));


done_testing;
