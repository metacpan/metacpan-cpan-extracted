use warnings;
use strict;

BEGIN {
	eval { require threads; };
	if($@ =~ /\AThis Perl not built to support threads/) {
		require Test::More;
		Test::More::plan(skip_all => "non-threading perl build");
	}
	if($@ ne "") {
		require Test::More;
		Test::More::plan(skip_all => "threads unavailable");
	}
	eval { require Thread::Semaphore; };
	if($@ ne "") {
		require Test::More;
		Test::More::plan(skip_all => "Thread::Semaphore unavailable");
	}
	eval { require threads::shared; };
	if($@ ne "") {
		require Test::More;
		Test::More::plan(skip_all => "threads::shared unavailable");
	}
}

use threads;

use Test::More tests => 3;
use Thread::Semaphore ();
use threads::shared;

alarm 10;   # failure mode may involve an infinite loop

my $done1 = Thread::Semaphore->new(0);
my $exit1 = Thread::Semaphore->new(0);
my $done2 = Thread::Semaphore->new(0);
my $exit2 = Thread::Semaphore->new(0);

my $ok1 :shared;
my $thread1 = threads->create(sub {
	my $ok = 1;
	eval(q{
		use Lexical::SealRequireHints;
		require t::context_1;
		1;
	}) or $ok = 0;
	$ok1 = $ok;
	$done1->up;
	$exit1->down;
});
$done1->down;
ok $ok1;

my $ok2 :shared;
my $thread2 = threads->create(sub {
	my $ok = 1;
	eval(q{
		use Lexical::SealRequireHints;
		require t::context_2;
		1;
	}) or $ok = 0;
	$ok2 = $ok;
	$done2->up;
	$exit2->down;
});
$done2->down;
ok $ok2;

$exit1->up;
$exit2->up;
$thread1->join;
$thread2->join;
ok 1;

1;
