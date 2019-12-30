#!/usr/bin/perl

use strict;
use warnings;

use Cwd;
use FindBin;
use lib "lib",
	"$FindBin::Bin/../blib/lib/",
	"$FindBin::Bin/../blib/arch/",
;

my ($ALGO) = $FindBin::Bin =~ m</([^/]+)\z>;
my @features;
BEGIN {
	use ISAL::Crypto qw(:all);
	@features = ISAL::Crypto::get_cpu_features;
}

use Test::More tests => 2 * @features;

my $TLEN = 64 * 1024;
my $str = "x" x $TLEN;

for my $f (@features) {
	my $init = "init_$f";
	my $mgr = "ISAL::Crypto::Mgr::$ALGO"->$init();
	
	my $submit = "submit_$f";
	do {
		my $ctx = \("ISAL::Crypto::Ctx::$ALGO"->init());
		$mgr->$submit($$ctx, '', FIRST);
		$mgr->$submit($$ctx, $str, UPDATE);
		# now sv_ctx cleared;
	};
	
	my $flush = "flush_$f";
	# get old ctx (from C) but Sv for it does not exist now
	while ($mgr->$flush()){};
	pass "Clear mgr-$f lane with reference";
	
	# Else case
	$mgr = "ISAL::Crypto::Mgr::$ALGO"->$init();
	do {
		my $ctx = "ISAL::Crypto::Ctx::$ALGO"->init();
		$mgr->$submit($ctx, '', FIRST);
		$mgr->$submit($ctx, $str, UPDATE);
		# now sv_ctx cleared;
	};
	
	# get old ctx (from C) but Sv for it does not exist now
	while ($mgr->$flush()){};
	pass "Clear mgr-$f without reference";
}
