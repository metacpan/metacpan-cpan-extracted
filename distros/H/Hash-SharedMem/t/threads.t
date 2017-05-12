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

use File::Temp 0.22 qw(tempdir);
use Test::More tests => 44;
use Thread::Semaphore ();
use threads::shared;

our $tmpdir = tempdir(CLEANUP => 1);

alarm 1000;

our $ping1 = Thread::Semaphore->new(0);
our $pong1 = Thread::Semaphore->new(0);
our $ping2 = Thread::Semaphore->new(0);
our $pong2 = Thread::Semaphore->new(0);

my $ok1 :shared;
my $thread1 = threads->create(sub {
	my $ok = 1;
	our $sh;
	eval(q{
		use Hash::SharedMem qw(shash_open check_shash);
		$sh = shash_open("$tmpdir/t0", "rwc");
		check_shash($sh);
		ref($sh) eq "Hash::SharedMem::Handle" or die;
		1;
	}) or $ok = 0;
	$pong1->up;
	$ping1->down;
	eval(q{
		check_shash($sh);
		ref($sh) eq "Hash::SharedMem::Handle" or die;
		1;
	}) or $ok = 0;
	$ok1 = $ok;
	$pong1->up;
	$ping1->down;
});

my $ok2 :shared;
my $thread2 = threads->create(sub {
	my $ok = 1;
	our $sh;
	$ping2->down;
	eval(q{
		use Hash::SharedMem qw(shash_open check_shash);
		$sh = shash_open("$tmpdir/t0", "rwc");
		check_shash($sh);
		ref($sh) eq "Hash::SharedMem::Handle" or die;
		1;
	}) or $ok = 0;
	$pong2->up;
	$ping2->down;
	eval(q{
		check_shash($sh);
		ref($sh) eq "Hash::SharedMem::Handle" or die;
		1;
	}) or $ok = 0;
	$ok2 = $ok;
	$pong2->up;
	$ping2->down;
});

$pong1->down;
$ping2->up;
$pong2->down;
$ping1->up;
$pong1->down;
$ping2->up;
$pong2->down;

ok $ok1;
ok $ok2;

$ping1->up;
$ping2->up;
$thread1->join;
$thread2->join;
ok 1;

SKIP: {
skip "this perl doesn't fully support cloning", 41
	unless ("$]" >= 5.008009 && "$]" < 5.009) || "$]" >= 5.009003;

our $ping3 = Thread::Semaphore->new(0);
our $pong3 = Thread::Semaphore->new(0);
our $ping4 = Thread::Semaphore->new(0);
our $pong4 = Thread::Semaphore->new(0);

my $ok3 :shared;
my $ok4 :shared;
my $thread3 = threads->create(sub {
	my $ok = 1;
	eval(q{
		use Hash::SharedMem qw(shash_open check_shash);
		my $sh = shash_open("$tmpdir/t0", "rwc");
		check_shash($sh);
		ref($sh) eq "Hash::SharedMem::Handle" or die;
		1;
	}) or $ok = 0;
	threads->create(sub {
		my $ok = 1;
		our $sh;
		$ping4->down;
		eval(q{
			$sh = shash_open("$tmpdir/t0", "rwc");
			check_shash($sh);
			ref($sh) eq "Hash::SharedMem::Handle" or die;
			1;
		}) or $ok = 0;
		$pong4->up;
		$ping4->down;
		eval(q{
			check_shash($sh);
			ref($sh) eq "Hash::SharedMem::Handle" or die;
			1;
		}) or $ok = 0;
		$ok4 = $ok;
		$pong4->up;
		$ping4->down;
	})->detach;
	$ok3 = $ok;
	$pong3->up;
	$ping3->down;
});

$pong3->down;
$ping4->up;
$pong4->down;
$ping3->up;
$thread3->join;
$ping4->up;
$pong4->down;

ok $ok3;
ok $ok4;

$ping4->up;
ok 1;

ok eval(q{
	use Hash::SharedMem qw(
		shash_open is_shash check_shash
		shash_set shash_get
	);
1; });

our $ping5 = Thread::Semaphore->new(0);
our $pong5 = Thread::Semaphore->new(0);
our $ping6 = Thread::Semaphore->new(0);
our $pong6 = Thread::Semaphore->new(0);

my $ok5 :shared;
my $thread5 = threads->create(sub {
	my $ok = 1;
	our $sh;
	eval(q{
		$sh = shash_open("$tmpdir/t0", "rwc");
		check_shash($sh);
		ref($sh) eq "Hash::SharedMem::Handle" or die;
		1;
	}) or $ok = 0;
	$pong5->up;
	$ping5->down;
	eval(q{
		check_shash($sh);
		ref($sh) eq "Hash::SharedMem::Handle" or die;
		1;
	}) or $ok = 0;
	$ok5 = $ok;
	$pong5->up;
	$ping5->down;
});

my $ok6 :shared;
my $thread6 = threads->create(sub {
	my $ok = 1;
	our $sh;
	$ping6->down;
	eval(q{
		$sh = shash_open("$tmpdir/t0", "rwc");
		check_shash($sh);
		ref($sh) eq "Hash::SharedMem::Handle" or die;
		1;
	}) or $ok = 0;
	$pong6->up;
	$ping6->down;
	eval(q{
		check_shash($sh);
		ref($sh) eq "Hash::SharedMem::Handle" or die;
		1;
	}) or $ok = 0;
	$ok6 = $ok;
	$pong6->up;
	$ping6->down;
});

$pong5->down;
$ping6->up;
$pong6->down;
$ping5->up;
$pong5->down;
$ping6->up;
$pong6->down;

ok $ok5;
ok $ok6;

$ping5->up;
$ping6->up;
$thread5->join;
$thread6->join;
ok 1;

my $a20 = join("abcdef", 0..999);
my $r;
ok eval(q{
	my $sh = shash_open("$tmpdir/t0", "rwc");
	check_shash($sh);
	ref($sh) eq "Hash::SharedMem::Handle" or die;
	shash_set($sh, "a20", $a20);
	shash_get($sh, "a20") eq $a20 or die;
1; });

ok eval(q{
	my $sh = shash_open("$tmpdir/t0", "rwc");
	check_shash($sh);
	ref($sh) eq "Hash::SharedMem::Handle" or die;
	$r = \shash_get($sh, "a20");
1; });
is $$r, $a20;
our $ping7 = Thread::Semaphore->new(0);
our $pong7 = Thread::Semaphore->new(0);
my $ok7 :shared;
my $thread7 = threads->create(sub {
	$ping7->down;
	$ok7 = $$r eq $a20;
	$r = undef;
	$pong7->up;
	$ping7->down;
});
is $$r, $a20;
$ping7->up;
$pong7->down;
is $$r, $a20;
$r = undef;
ok $ok7;
$ping7->up;
$thread7->join;
ok 1;

ok eval(q{
	my $sh = shash_open("$tmpdir/t0", "rwc");
	check_shash($sh);
	ref($sh) eq "Hash::SharedMem::Handle" or die;
	$r = \shash_get($sh, "a20");
1; });
is $$r, $a20;
our $ping8 = Thread::Semaphore->new(0);
our $pong8 = Thread::Semaphore->new(0);
my $ok8 :shared;
my $thread8 = threads->create(sub {
	my $ok = 1;
	$ping8->down;
	$ok &&= $$r eq $a20;
	$pong8->up;
	$ping8->down;
	$ok &&= $$r eq $a20;
	$r = undef;
	$ok8 = $ok;
	$pong8->up;
	$ping8->down;
});
is $$r, $a20;
$ping8->up;
$pong8->down;
is $$r, $a20;
$r = undef;
$ping8->up;
$pong8->down;
ok $ok8;
$ping8->up;
$thread8->join;
ok 1;

my $sh;
shash_set(shash_open("$tmpdir/t0", "rwc"), "b0", "c0");

$sh = shash_open("$tmpdir/t0", "rwc");
ok is_shash($sh);
is ref($sh),"Hash::SharedMem::Handle";
is shash_get($sh, "b0"), "c0";
our $ping9 = Thread::Semaphore->new(0);
our $pong9 = Thread::Semaphore->new(0);
my $ok9 :shared;
my $thread9 = threads->create(sub {
	my $ok = 1;
	$ping9->down;
	eval(q{
		shash_get($sh, "b0") eq "c0" or die;
		1;
	}) or $ok = 0;
	$sh = undef;
	$ok9 = $ok;
	$pong9->up;
	$ping9->down;
});
is shash_get($sh, "b0"), "c0";
$ping9->up;
$pong9->down;
is shash_get($sh, "b0"), "c0";
$sh = undef;
ok $ok9;
$ping9->up;
$thread9->join;
ok 1;

$sh = shash_open("$tmpdir/t0", "rwc");
ok is_shash($sh);
is ref($sh),"Hash::SharedMem::Handle";
is shash_get($sh, "b0"), "c0";
our $ping0 = Thread::Semaphore->new(0);
our $pong0 = Thread::Semaphore->new(0);
my $ok0 :shared;
my $thread0 = threads->create(sub {
	my $ok = 1;
	$ping0->down;
	eval(q{
		shash_get($sh, "b0") eq "c0" or die;
		1;
	}) or $ok = 0;
	$pong0->up;
	$ping0->down;
	eval(q{
		shash_get($sh, "b0") eq "c0" or die;
		1;
	}) or $ok = 0;
	$sh = undef;
	$ok0 = $ok;
	$pong0->up;
	$ping0->down;
});
is shash_get($sh, "b0"), "c0";
$ping0->up;
$pong0->down;
is shash_get($sh, "b0"), "c0";
$sh = undef;
$ping0->up;
$pong0->down;
ok $ok0;
$ping0->up;
$thread0->join;
ok 1;

$sh = shash_open("$tmpdir/t1", "rwc");
ok is_shash($sh);
is ref($sh),"Hash::SharedMem::Handle";
is shash_get($sh, "d0"), undef;
our $ping10 = Thread::Semaphore->new(0);
our $pong10 = Thread::Semaphore->new(0);
my $ok10 :shared;
my $thread10 = threads->create(sub {
	my $ok = 1;
	$ping10->down;
	eval(q{
		!defined(shash_get($sh, "d0")) or die;
		1;
	}) or $ok = 0;
	$pong10->up;
	$ping10->down;
	eval(q{
		!defined(shash_get($sh, "d0")) or die;
		1;
	}) or $ok = 0;
	$sh = undef;
	$ok10 = $ok;
	$pong10->up;
	$ping10->down;
});
is shash_get($sh, "d0"), undef;
$ping10->up;
$pong10->down;
is shash_get($sh, "d0"), undef;
$sh = undef;
my @z = ("b" x 200) x 10;   # to overwrite space that held synthetic data file
$ping10->up;
$pong10->down;
ok $ok10;
$ping10->up;
$thread10->join;
ok 1;

}

1;
