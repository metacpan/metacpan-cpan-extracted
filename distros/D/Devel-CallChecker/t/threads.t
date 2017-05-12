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

sub tsub1 (@) { $_[0] }
sub tsub2 (@) { $_[0] }
sub nsub (@) { $_[0] }
our @three = (3);

my $done1 = Thread::Semaphore->new(0);
my $exit1 = Thread::Semaphore->new(0);
my $done2 = Thread::Semaphore->new(0);
my $exit2 = Thread::Semaphore->new(0);

my $ok1 :shared;
my $thread1 = threads->create(sub {
	my $ok = 1;
	require Devel::CallChecker;
	require t::LoadXS;
	require t::WriteHeader;
	t::WriteHeader::write_header("callchecker0", "t", "threads1");
	t::LoadXS::load_xs("threads1", "t",
		[Devel::CallChecker::callchecker_linkable()]);
	eval(q{nsub(@three)}) == 3 or $ok = 0;
	eval(q{tsub1(@three)}) == 3 or $ok = 0;
	t::threads1::cv_set_call_checker_proto(\&tsub1, "\$");
	eval(q{nsub(@three)}) == 3 or $ok = 0;
	eval(q{tsub1(@three)}) == 1 or $ok = 0;
	$ok1 = $ok;
	$done1->up;
	$exit1->down;
});
$done1->down;
ok $ok1;

my $ok2 :shared;
my $thread2 = threads->create(sub {
	my $ok = 1;
	require Devel::CallChecker;
	require t::LoadXS;
	require t::WriteHeader;
	t::WriteHeader::write_header("callchecker0", "t", "threads2");
	t::LoadXS::load_xs("threads2", "t",
		[Devel::CallChecker::callchecker_linkable()]);
	eval(q{nsub(@three)}) == 3 or $ok = 0;
	eval(q{tsub2(@three)}) == 3 or $ok = 0;
	t::threads2::cv_set_call_checker_proto(\&tsub2, "\$");
	eval(q{nsub(@three)}) == 3 or $ok = 0;
	eval(q{tsub2(@three)}) == 1 or $ok = 0;
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
