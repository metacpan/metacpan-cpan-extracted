#!/usr/bin/perl -w
use Test::More qw(no_plan);
use Config;

# Tests to check if options given at initialization are failing as expecting


BEGIN {
	use_ok('Log::Funlog',"error","0.1");
}
ok(! eval{ use Log::Funlog; Log::Funlog->new() }, "No 'verbose' specified");
ok(! eval{ use Log::Funlog; Log::Funlog->new(verbose => '1') }, 'verbose => 1');
ok(  eval{ use Log::Funlog; Log::Funlog->new(verbose => 'MaX/1') }, 'verbose => MaX/1');
ok(! eval{ use Log::Funlog; Log::Funlog->new(verbose => '1/1',cosmetic => "e\t") }, 'cosmetic => e\t');
ok(! eval{ use Log::Funlog; Log::Funlog->new(verbose => '1/1',cosmetic => "\t") }, 'cosmetic => \t');
ok(! eval{ use Log::Funlog; Log::Funlog->new(verbose => '1/1',cosmetic => 'ee') }, 'cosmetic => "ee"');
ok(  eval{ use Log::Funlog; Log::Funlog->new(verbose => '1/1',daemon => 0) }, 'daemon => 0');
ok(! eval{ use Log::Funlog; Log::Funlog->new(verbose => '1/1',daemon => 1) }, "'daemon' specified without 'file'");
SKIP: {
	use Config;
	skip('We are on MSWin32',2) if ($Config{'osname'} eq 'MSWin32');
	ok(! eval{ use Log::Funlog; Log::Funlog->new(verbose => '1/1',colors => [1] ) }, 'colors => [1]');
	ok( eval{ use Log::Funlog; Log::Funlog->new(verbose => '1/1',colors => 1)}, 'Colors wanted but we are on win32');
}
SKIP: {
	eval{ require Log::Funlog::Lang };
	skip 'Log::Funlog::Lang not present' if ($@);
	if (! $@) {
		ok(!  eval{ use Log::Funlog; Log::Funlog->new(verbose => '1/1', fun => 101) }, 'fun => 101' );
		ok(!  eval{ use Log::Funlog; Log::Funlog->new(verbose => '1/1', fun => 0) }, 'fun => 0' );
		ok(!  eval{ use Log::Funlog; Log::Funlog->new(verbose => '1/1', fun => -1) }, 'fun < 0' );
	}
}
