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
	if("$]" < 5.008003) {
		require Test::More;
		Test::More::plan(skip_all =>
			"threading breaks PL_sv_placeholder on this Perl");
	}
	if("$]" < 5.008009) {
		require Test::More;
		Test::More::plan(skip_all =>
			"threading corrupts memory on this Perl");
	}
	if("$]" >= 5.009005 && "$]" < 5.010001) {
		require Test::More;
		Test::More::plan(skip_all =>
			"threading breaks assertions on this Perl");
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

use Test::More tests => 6;
use Thread::Semaphore ();
use threads::shared;

alarm 10;   # failure mode may involve an infinite loop

my(@exit_sems, @threads);

sub test_in_thread($) {
	my($test_code) = @_;
	my $done_sem = Thread::Semaphore->new(0);
	my $exit_sem = Thread::Semaphore->new(0);
	push @exit_sems, $exit_sem;
	my $ok :shared;
	push @threads, threads->create(sub {
		$ok = !!$test_code->();
		$done_sem->up;
		$exit_sem->down;
	});
	$done_sem->down;
	ok $ok;
}

sub basic_test {
	eval(q{
		use IO::ExplicitHandle;
		if(0) { print 123; }
		1;
	});
	return !!($@ =~ /\AUnspecified I\/O handle in print /);
}

test_in_thread(\&basic_test) for 0..1;
ok basic_test();
test_in_thread(\&basic_test) for 0..1;

$_->up foreach @exit_sems;
$_->join foreach @threads;
ok 1;

1;
