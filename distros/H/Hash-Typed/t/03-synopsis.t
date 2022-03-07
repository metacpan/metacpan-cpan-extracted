use Test::More;

use Hash::Typed;

use Types::Standard qw/Int Str ArrayRef/;

my $test = Hash::Typed->new(
	[ 
		strict => 1, 
		keys => [
			one => Int,
			two => Str,
			three => ArrayRef,
			four => sub { return 1 },
			five => sub { 
				Hash::Typed->new(
					[ keys => [ one => Int ] ],
					%{$_[0]}
				); 
			} 
		] 
	],
	(
		three => [qw/a b c/],
		two => 'def',
		one => 211,
		four => undef,
		five => { one => 633 }
	)
);

is_deeply({%{$test}}, {one => 211, two => 'def', three => [qw/a b c/], four => 1, five => { one => 633 }});


tie my %test, 'Hash::Typed',
	[ 
		strict => 1, 
		keys => [
			one => Int,
			two => Str,
			three => ArrayRef,
			four => sub { return 1 },
			five => sub { Hash::Typed->new(@{$_[0]}); } 
		] 
	],
	(
		three => [qw/a b c/],
		two => 'def',
		one => 211,
		four => undef,
		five => [ [keys => [ one => Int ]], one => 633 ]
	);

is_deeply(\%test, {one => 211, two => 'def', three => [qw/a b c/], four => 1, five => { one => 633 }});

done_testing;
