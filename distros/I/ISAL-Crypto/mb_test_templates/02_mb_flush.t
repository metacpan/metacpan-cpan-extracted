#!/usr/bin/perl

use strict;
use warnings;

use FindBin;
use lib "lib",
	"$FindBin::Bin/../blib/lib/",
	"$FindBin::Bin/../blib/arch/",
;

use Net::SSLeay;
use Scalar::Util 'refaddr';
Net::SSLeay::OpenSSL_add_all_digests();

my ($ALGO) = $FindBin::Bin =~ m</([^/]+)\z>;
my @features;

my ($TEST_BUFS, $RANDOMS, $RAND_SEED, $rand_sum, $rand_small_jobs);
my (@RANDOMS, @JOBS);

BEGIN {
	$TEST_BUFS = $ENV{TEST_BUFS} || 100;
	$RANDOMS   = $ENV{RANDOMS}   || 10;
	$RAND_SEED = $ENV{RAND_SEED} || time;
	srand $RAND_SEED;
	
	use ISAL::Crypto qw(:all);
	@features = ISAL::Crypto::get_cpu_features;
	
	push @JOBS, int(rand($TEST_BUFS)) for (1..$RANDOMS);
	$rand_sum += $_ for @JOBS;
	$rand_small_jobs = int(rand($TEST_BUFS));
}

use Test::More tests => ($TEST_BUFS + $rand_sum + $rand_small_jobs) * @features;

my $TEST_LEN  = 1024 * 1024;

sub run_tests($$$) {
	my ($amount, $f, $test_prefix) = @_;
	my (@tbufs, @ctxpool, @digest_refs);
	my $init = "init_$f";
	my $mgr = "ISAL::Crypto::Mgr::$ALGO"->$init();
	
	my $submit = "submit_$f";
	
	for (0..$amount - 1) {
		# Fill test buffer and init ctxs
		my $cycles = int(rand($TEST_LEN)) / 8; # length(pack, "F", rand) == 8;
		my $str = "";
		$str .= pack "F", rand for (1..$cycles);
		# MUST to save str until flush
		push @tbufs, $str;
		push @ctxpool, "ISAL::Crypto::Ctx::$ALGO"->init();
		
		# run reference test
		my $hash = Net::SSLeay::EVP_MD_CTX_create();
		Net::SSLeay::EVP_DigestInit(
			$hash,
			Net::SSLeay::EVP_get_digestbyname($ALGO)
		);
		Net::SSLeay::EVP_DigestUpdate($hash, $str);
		push @digest_refs, Net::SSLeay::EVP_DigestFinal($hash);
		
		# submit sb job ($str) to mgr
		$mgr->$submit($ctxpool[$#ctxpool], $tbufs[$#tbufs], ENTIRE);
	}
	
	my $flush = "flush_$f";
	while ($mgr->$flush()){};
	
	my $fails;
	for (0..$amount - 1) {
		my $res = $ctxpool[$_]->get_digest();
		my $ref_res = $digest_refs[$_];
		if (!ok $res eq $ref_res, "$test_prefix-$f test-$_") {
			$fails++;
			my $err = sprintf "#SEED: %s\n#RES: %s\n#REF: %s\n",
				$RAND_SEED, unpack("H*", $res), unpack("H*", $ref_res);
			warn $err;
		}
	}
	
	die "Failed $fails tests!" if $fails;
}

for my $f (@features) {
	run_tests($TEST_BUFS, $f, "SB");
	
	for my $amount (@JOBS) {
		run_tests($amount, $f, "Rand SB");
	}
	
	my $tmp_buf = "";
	$tmp_buf .= pack "B", rand for (0..$rand_small_jobs - 1);
	
	my (@tbufs, @ctxpool, @digest_refs);
	my $init = "init_$f";
	my $mgr = "ISAL::Crypto::Mgr::$ALGO"->$init();
	
	my $submit = "submit_$f";
	
	for (0..$rand_small_jobs - 1) {
		# Fill test buffer and init ctxs
		my $str .= substr($tmp_buf, $_, length($tmp_buf) - $_);
		# MUST to save str until flush
		push @tbufs, $str;
		push @ctxpool, "ISAL::Crypto::Ctx::$ALGO"->init();
		
		# run reference test
		my $hash = Net::SSLeay::EVP_MD_CTX_create();
		Net::SSLeay::EVP_DigestInit(
			$hash,
			Net::SSLeay::EVP_get_digestbyname($ALGO)
		);
		Net::SSLeay::EVP_DigestUpdate($hash, $str);
		push @digest_refs, Net::SSLeay::EVP_DigestFinal($hash);
		
		# submit sb job ($str) to mgr
		$mgr->$submit($ctxpool[$#ctxpool], $tbufs[$#tbufs], ENTIRE);
	}
	
	my $flush = "flush_$f";
	while ($mgr->$flush()){};
	
	my $fails;
	for (0..$rand_small_jobs - 1) {
		my $res = $ctxpool[$_]->get_digest();
		my $ref_res = $digest_refs[$_];
		if (!ok $res eq $ref_res, "Small buffs-$f test-$_") {
			$fails++;
			my $err = sprintf "#SEED: %s\n#RES: %s\n#REF: %s\n",
				$RAND_SEED, unpack("H*", $res), unpack("H*", $ref_res);
			warn $err;
		}
	}
	
	die "Failed $fails tests!" if $fails;
}
