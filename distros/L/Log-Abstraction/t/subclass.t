use strict;
use warnings;

use Test::Most;
use Test::Returns;

BEGIN { use_ok('Log::Abstraction') }

{
	package SubClass;
	our @ISA = qw(Log::Abstraction);

	1;
}

my $sub = SubClass->new();
lives_ok(sub { $sub->warn('should be logged') }, 'can subclass');
returns_is($sub->messages(), { type => 'arrayref', min => 1, max => 1 }, 'messages returns an arrayref' );
diag(Data::Dumper->new([$sub->messages()])->Dump()) if($ENV{'LOG_VERBOSE'});

is_deeply(
	$sub->messages(),
	[
		{ level => 'warn', message => 'should be logged' },
	]
);

done_testing();
