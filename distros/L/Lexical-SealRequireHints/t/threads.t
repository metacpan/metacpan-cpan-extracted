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

use Test::More tests => 12;
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

our $onset_test;
my $onset_unfixed;

$^H |= 0x20000 if "$]" < 5.009004;
$^H{"Lexical::SealRequireHints/test"} = 1;

$onset_test = "";
eval q{ require "t/onset.pl"; 1 } or die $@;
delete $INC{"t/onset.pl"};
$onset_unfixed = $onset_test;

test_in_thread(sub {
	$onset_test = "";
	eval q{ require "t/onset.pl"; 1 } or die $@;
	delete $INC{"t/onset.pl"};
	return $onset_test eq $onset_unfixed;
});

test_in_thread(sub {
	require Lexical::SealRequireHints;
	Lexical::SealRequireHints->import;
	$onset_test = "";
	eval q{ require "t/onset.pl"; 1 } or die $@;
	delete $INC{"t/onset.pl"};
	return $onset_test eq "undef";
});

$onset_test = "";
eval q{ require "t/onset.pl"; 1 } or die $@;
delete $INC{"t/onset.pl"};
is $onset_test, $onset_unfixed;

test_in_thread(sub {
	$onset_test = "";
	eval q{ require "t/onset.pl"; 1 } or die $@;
	delete $INC{"t/onset.pl"};
	return $onset_test eq $onset_unfixed;
});

test_in_thread(sub {
	require Lexical::SealRequireHints;
	$onset_test = "";
	eval q{ require "t/onset.pl"; 1 } or die $@;
	delete $INC{"t/onset.pl"};
	return $onset_test eq $onset_unfixed;
});

test_in_thread(sub {
	eval(q{
		use Lexical::SealRequireHints;
		require t::context_1;
		1;
	})
});

require Lexical::SealRequireHints;

$onset_test = "";
eval q{ require "t/onset.pl"; 1 } or die $@;
delete $INC{"t/onset.pl"};
is $onset_test, $onset_unfixed;

test_in_thread(sub {
	$onset_test = "";
	eval q{ require "t/onset.pl"; 1 } or die $@;
	delete $INC{"t/onset.pl"};
	return $onset_test eq $onset_unfixed;
});

test_in_thread(sub {
	Lexical::SealRequireHints->import;
	$onset_test = "";
	eval q{ require "t/onset.pl"; 1 } or die $@;
	delete $INC{"t/onset.pl"};
	return $onset_test eq "undef";
});

Lexical::SealRequireHints->import;

$onset_test = "";
eval q{ require "t/onset.pl"; 1 } or die $@;
delete $INC{"t/onset.pl"};
is $onset_test, "undef";

test_in_thread(sub {
	$onset_test = "";
	eval q{ require "t/onset.pl"; 1 } or die $@;
	delete $INC{"t/onset.pl"};
	return $onset_test eq "undef";
});

$_->up foreach @exit_sems;
$_->join foreach @threads;
ok 1;

1;
