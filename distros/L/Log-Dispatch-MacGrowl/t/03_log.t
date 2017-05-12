#

use strict;
use warnings;
use Test::More tests => 6;

BEGIN {
    use_ok('Log::Dispatch');
    use_ok('Log::Dispatch::MacGrowl');
}

# 1
do {
    my $dispatcher = Log::Dispatch::MacGrowl->new(
	name => 'growl',
	min_level => 'debug',
    );

    ok($dispatcher, 'new 1');

    eval {
	$dispatcher->log(
	    level => 'debug',
	    message  => "Testing Log::Dispatch::MacGrowl $Log::Dispatch::MacGrowl::VERSION",
	);
    };
    ok( ! $@, 'call 1');
};

# 2
do {
    my $dispatcher = Log::Dispatch::MacGrowl->new(
	name => 'growl',
	min_level => 'debug',

	title => '* This is test.',
	priority => -1,
	sticky => 0,
	icon_file => '/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/AlertCautionIcon.icns',
    );

    ok($dispatcher, 'new 2');

    eval {
	$dispatcher->log(
	    level => 'emergency',
	    message  => "The quick brown fox jumps over the lazy dog.",
	);
    };
    ok( ! $@, 'call 2');
};
