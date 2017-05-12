# -*- cperl -*-

use strict;
use warnings;
use Test::More tests => 6;

BEGIN {
    use_ok('Log::Dispatch');
    use_ok('Log::Dispatch::Growl');
}

# 1
do {
    my $dispatcher = Log::Dispatch::Growl->new(
	name => 'growl',
	min_level => 'debug',
    );

    ok($dispatcher, 'new 1');

    eval {
	$dispatcher->log(
	    level => 'debug',
	    message  => "Testing Log::Dispatch::Growl $Log::Dispatch::Growl::VERSION",
	);
    };
    ok( ! $@, 'call 1');
    diag $@ if $@;
};

# 2
do {
    my $dispatcher = Log::Dispatch::Growl->new(
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
    diag $@ if $@;
};
