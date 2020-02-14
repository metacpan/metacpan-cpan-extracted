use strict;
use warnings;
use Test::More;
use Test::Fatal;

use Test::Requires 'Sub::HandlesVia';
use Test::Requires 'Types::Standard';

my $accessor;
my $popper;

my $obj = do {
	package Local::Class;
	use Types::Standard 'ArrayRef';
	use Lexical::Accessor 'lexical_has';
	
	lexical_has attr => (
		is          => 'rw',
		isa         => ArrayRef,
		accessor    => \$accessor,
		handles_via => 'Array',
		handles     => [
			\$popper   => 'pop',
			pusher     => 'push',
		],
	);
	
	bless {};
};

my @nums = (1..10);

$obj->$accessor(\@nums);

is_deeply(
	$obj->$accessor,
	[1..10],
);

$obj->pusher(11, 12, 49);

is_deeply(
	$obj->$accessor,
	[1..12, 49],
);

is(
	scalar($obj->$popper),
	49,
);

is_deeply(
	$obj->$accessor,
	[1..12],
);

done_testing;

