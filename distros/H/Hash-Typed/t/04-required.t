use Test::More;

use Hash::Typed;

use Types::Standard qw/Int/;

tie (
	my %test, 
	'Hash::Typed', 
	[ strict => 1, required => 1, keys => [ one => Int, two => Int, three => Int ] ],
	three => 3, two => 2, one => 1
);

is_deeply(\%test, {one => 1, two => 2, three => 3});

delete $test{three};

is_deeply(\%test, {one => 1, two => 2});

untie(%test);

is_deeply(\%test, {});

eval {
	tie (
		my %test, 
		'Hash::Typed', 
		[ strict => 1, keys => [ one => Int, two => Int, three => Int ] ],
		one => 1, two => 2, three => 3, other => 'not okay'
	);
};

like($@, qr/Strict mode enabled and passed key "other" does not exist in the specification/);


tie (
	my %test, 
	'Hash::Typed', 
	[ required => [qw/one two three other/], keys => [ one => Int, two => Int, three => Int ] ],
	one => 1, two => 2, three => 3, other => 'okay'
);

is_deeply(\%test, { one => 1, two => 2, three => 3, other => 'okay' });

$test{one} = 100;

is($test{one}, 100);

eval {
	$test{one} = 'abc';
};

like("$@", qr/Value "abc" did not pass type constraint "Int"/); 

done_testing;
