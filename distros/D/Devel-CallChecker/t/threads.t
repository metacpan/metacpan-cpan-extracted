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

use Test::More tests => 3;
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

BEGIN { unshift @INC, "./t/lib"; }

sub tsub1 (@) { $_[0] }
sub tsub2 (@) { $_[0] }
sub nsub (@) { $_[0] }
our @three = (3);

test_in_thread(sub {
	require Devel::CallChecker;
	require t::LoadXS;
	require t::WriteHeader;
	t::WriteHeader::write_header("callchecker0", "t", "threads1");
	t::LoadXS::load_xs("threads1", "t",
		[Devel::CallChecker::callchecker_linkable()]);
	eval(q{nsub(@three)}) == 3 or return 0;
	eval(q{tsub1(@three)}) == 3 or return 0;
	t::threads1::cv_set_call_checker_proto(\&tsub1, "\$");
	eval(q{nsub(@three)}) == 3 or return 0;
	eval(q{tsub1(@three)}) == 1 or return 0;
	return 1;
});

test_in_thread(sub {
	require Devel::CallChecker;
	require t::LoadXS;
	require t::WriteHeader;
	t::WriteHeader::write_header("callchecker0", "t", "threads2");
	t::LoadXS::load_xs("threads2", "t",
		[Devel::CallChecker::callchecker_linkable()]);
	eval(q{nsub(@three)}) == 3 or return 0;
	eval(q{tsub2(@three)}) == 3 or return 0;
	t::threads2::cv_set_call_checker_proto(\&tsub2, "\$");
	eval(q{nsub(@three)}) == 3 or return 0;
	eval(q{tsub2(@three)}) == 1 or return 0;
	return 1;
});

$_->up foreach @exit_sems;
$_->join foreach @threads;
ok 1;

1;
