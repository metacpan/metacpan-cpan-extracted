#!/usr/bin/perl

use strict;
use warnings;

use FindBin;
use Net::SSLeay;
use Scalar::Util 'refaddr';
Net::SSLeay::OpenSSL_add_all_digests();

use Time::HiRes qw(CLOCK_PROCESS_CPUTIME_ID clock_gettime);

my ($ALGO) = $FindBin::Bin =~ m</([^/]+)\z>;
my @features;

BEGIN {
	use ISAL::Crypto qw(:all);
	@features = ISAL::Crypto::get_cpu_features;
}

use Test::More tests => scalar @features;

my $LOOPS = 10000;
my $TLEN =  10000;

my $data = "x" x $TLEN;
my $MAX_LANES = eval "ISAL::Crypto::${ALGO}_MAX_LANES";
diag "START BENCHMARK FOR $ALGO"; # more readable

for my $f (@features) {
	diag ""; # more readable
	
	my (@digest_refs, @digests_res);
	my @ctx = (undef);
	
	my $init = "init_$f";
	my $mgr = "ISAL::Crypto::Mgr::$ALGO"->$init();
	
	my $submit = "submit_$f";
	my $flush = "flush_$f";
	for my $lanes (1 .. $MAX_LANES) {
		my $isa_start = clock_gettime(CLOCK_PROCESS_CPUTIME_ID);
		for my $loop (1 .. $LOOPS) {
			@ctx = (undef);
			for (1 .. $lanes) {
				push @ctx, "ISAL::Crypto::Ctx::$ALGO"->init();
				$mgr->$submit($ctx[$_], $data, ENTIRE);
			}
			
			while ($mgr->$flush()){};
			
			for (1..$lanes) {
				push @digests_res, $ctx[$_]->get_digest();
			}
		}
		
		my $isa_end = clock_gettime(CLOCK_PROCESS_CPUTIME_ID);
		my $datalen = ($lanes * $LOOPS * $TLEN / 1024 / 1024);
		my $time = ($isa_end - $isa_start);
		diag(
			sprintf "%d LOOPS FOR %s ON %2s LANES TOOK %.5f: %4s <=> %4sMb/s",
			$LOOPS, uc $f, $lanes, $time, int($datalen), int($datalen/$time)
		);
	}
	
	######################## START REFERENCE BENCH ########################
	
	my $ref_start = clock_gettime(CLOCK_PROCESS_CPUTIME_ID);
	
	for (1 .. $LOOPS) {
		# run reference test
		my $hash = Net::SSLeay::EVP_MD_CTX_create();
		Net::SSLeay::EVP_DigestInit(
			$hash,
			Net::SSLeay::EVP_get_digestbyname($ALGO)
		);
		Net::SSLeay::EVP_DigestUpdate($hash, $data);
		push @digest_refs, Net::SSLeay::EVP_DigestFinal($hash);
	}
	my $ref_end = clock_gettime(CLOCK_PROCESS_CPUTIME_ID);
	
	my $time = ($ref_end - $ref_start);
	my $datalen = ($LOOPS * $TLEN/ 1024 /1024);
	diag(
		sprintf "REF TOOK %5f: %4s <=> %4sMb/s",
		$time, $datalen, int($datalen/$time)
	);
	
	my $fails = 0;
	for my $lanes (1 .. $MAX_LANES) {
		my @tmp_digest_refs = @digest_refs;
		for my $loop (1 .. $LOOPS) {
			my $ref_res = shift @tmp_digest_refs;
			for (1 .. $lanes) {
				my $res = shift @digests_res;
				if ($ref_res ne $res) {
					$fails++;
					my $err = sprintf "#Fail: $fails #RES: %s\n#REF: %s\n",
						unpack("H*", $res), unpack("H*", $ref_res);
					$err .= "#AT LOOP:$loop, num_lanes:$lanes, lane:$_\n";
					warn $err;
				}
			}
		}
	}
	ok(!$fails, uc($f).": on $LOOPS loops");
}
