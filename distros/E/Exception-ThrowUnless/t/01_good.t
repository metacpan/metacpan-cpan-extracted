use strict;
BEGIN { use lib "lib"; };
use Test::More;
package Tests;
our($tests,%tests,@tst_subs);

package main;

do {
	$SIG{__WARN__}=sub { diag @_; };
	my $match = do {
		local $_ = q(.);
		$_ = join("|",map { qq(($_)) } @ARGV) if @ARGV;
		qr($_);
	};

	@tst_subs = sort grep { s{^s}{t_s} } keys %Exception::ThrowUnless::;
	my @exp_subs = sort grep { m{^t_s}    } keys %Tests::;
	my $tst_subs = "@tst_subs";
	grep { /$match/ and $Tests::tests+=$tests{$_} } keys %tests;
	plan tests => $Tests::tests + 1;

	is( "@exp_subs", $tst_subs, "same subs" );

	for ( @tst_subs ) {
		local $\="\n";
		SKIP: {
			do {
				if ( /$match/ ) {
					&{$Tests::{$_}};
				} elsif (0) {
					skip("no match: $_\n",$tests{$_});
				};
			};
		}
	};
};
BEGIN {
	package Tests;
	require "t/must_die.pl" or die;
	require "t/setup.pl" or die;
	use	Exception::ThrowUnless qw(:all);
	use Test::More;
	ssymlink "xxx", "tmp/xxx";
	$Tests::tests{t_sexec}=2;
	sub t_sexec(@)
	{
		defined(my $pid = fork) || die "fork:$!";
		if ( !$pid ) {
			exec "/bin/true";
			exit 1;
		} else {
			is(wait, $pid, "pid $pid dead");
			is($?, 0, "exec returned true");
		};
	};
	$Tests::tests{t_ssocketpair}=3;
	sub t_ssocketpair
	{
		use Socket;
		no warnings "once";
		local (*I,*O);
		ok(ssocketpair(*I,*O,AF_UNIX,SOCK_STREAM,PF_UNSPEC),
			"socketpair");
		SKIP: {
			if(0) {
				must_die(sub {
						for ( 0 .. 10000 ) {
							no strict "refs";
							ssocketpair(*{"I$_"},*{"O$_"},AF_UNIX,SOCK_STREAM,PF_UNSPEC);
						};
					},qr{^socketpair:GLOB},"many pipes");
				for ( 0 .. 10000 ) {
					no strict "refs";
					no warnings;
					close(*{"I$_"});
					close(*{"O$_"});
				};
			} else {
				skip("kernel bug 2.6.21 -- no error returned",1);
			};
		};
		ok(ssocketpair(*I,*O,AF_UNIX,SOCK_STREAM,PF_UNSPEC),
			"socketpair");
	};
	$Tests::tests{t_sspit}=0;
	sub t_sspit
	{
	};
	$Tests::tests{t_ssuck}=0;
	sub t_ssuck
	{
	};
	$Tests::tests{t_sopen}=4;
	sub t_sopen # (*$)
	{
		local(*FILE);
		ok(defined(sopen(*FILE, ">tmp/testfile")),"open_test");
		ok(close(FILE), "file open");
		eval {
			sopen(*FILE,">tmp");
			fail("open>tmp should have failed.");	
		};
		like($@, qr/^open:GLOB\(0x[0-9a-zA-Z]*\),>tmp:./, "open dir failed");
		ok(!close(FILE), "!file open");
	};
	$Tests::tests{t_sopendir}=0;
	sub t_sopendir # (*$)
	{
	};
	$Tests::tests{t_sclose}=3;
	sub t_sclose # (*)
	{
		local *FILE;
		my $passed;
		must_die( sub { sclose(*FILE) }, qr/^close:/, "close unopened");
		sopen(*FILE,">tmp/sclose");
		$@="";
		ok(defined sclose(*FILE), "close open file");
		is($@, "", "no error");
	};
	$Tests::tests{t_schdir}=1;
	sub t_schdir # ($)
	{
		#
		# This is just here for coverage checks.  It is tested in
		# tg/01_good_chdir.t, since I don't want to change the pwd
		# during a long series of tests.
		#
		ok("Don't blame me, I voted Libertarian!");
	};
	$Tests::tests{t_spipe}=3;
	sub t_spipe # (@)
	{
		ok(spipe(local *I,local *O),"spipe piped");
		must_die(sub {
				for ( 0 .. 10000 ) {
					no strict "refs";
					spipe(*{"I$_"},*{"O$_"});
				};
			},qr{^pipe:GLOB},"many pipes");
		for ( 0 .. 10000 ) {
			no warnings;
			no strict "refs";
			close(*{"I$_"});
			close(*{"O$_"});
		};
		ok(spipe(local *I,local *O),"spipe piped");
	};
	$Tests::tests{t_schmod}=2;
	sub t_schmod # (@)
	{
		must_die(sub { schmod(0777,"tmp/schmod") },qr/^chmod:/,"chmod gone");

		smkdir("tmp/schmod",0700);
		is(schmod(0770,"tmp/schmod"),1,"chmod tmp/schmod");
	};
	$Tests::tests{t_srmdir}=5;
	sub t_srmdir # (@)
	{
		local $_ = "tmp/srmdir_1";
		must_die( sub { srmdir }, qr/^rmdir:/, "rmdir gone" );

		smkdir($_,0777);
		is(eval 'srmdir',1,"srmdir");
		is($@,"",'srmdir eval');

		smkdir($_,0777);
		is(eval 'srmdir($_)',1,"srmdir $_");
		is($@,"",'srmdir eval');

	};
	$Tests::tests{t_sunlink}=3;
	sub t_sunlink # (@)
	{
		local *FILE;
		sopen(*FILE,">tmp/sunlink");
		ok(sunlink("tmp/sunlink"),"unlink ok");
		ok(sunlink("tmp/sunlink"),"unlink ENOENT");
		SKIP: {
			if ( $< && $> ) {
				sopen(*FILE,">tmp/sunlink");
				schmod(0500, "tmp");
				must_die(sub {
						sunlink "tmp/sunlink"
					}, qr(^unlink:),"unlink EPERM");
			} else {
				skip "Running as root", 1;
			};
		};
	};
	$Tests::tests{t_slink}=0;
	sub t_slink # ($$)
	{
	};
	$Tests::tests{t_srename}=0;
	sub t_srename # ($$)
	{
	};
	$Tests::tests{t_srename_nc}=0;
	sub t_srename_nc # ($$)
	{
	};
	$Tests::tests{t_ssymlink}=1;
	sub t_ssymlink # ($$)
	{
		must_die(
			sub{
				ssymlink("tmp", ".")
			}, qr(^symlink:), "symlink is dir"
		);
	};
	$Tests::tests{t_smkdir}=0;
	sub t_smkdir # ($$)
	{
	};
	$Tests::tests{t_sfork}=1;
	sub t_sfork # (;$)
	{
		SKIP: {
			skip("how can you make fork fail in a cross platform way?",1);
		};
	};
	$Tests::tests{t_sreadlink}=1;
	sub t_sreadlink # ($)
	{
		ssymlink("test", "tmp/test");
		is(sreadlink("tmp/test"),"test","readlink eq 'test'");
	};
};
