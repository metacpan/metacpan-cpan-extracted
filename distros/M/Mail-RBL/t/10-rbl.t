#!/usr/bin/perl

use Test::More;
use Net::DNS::Resolver;

@prefixes = qw(
	       bl.spamcop.net
	       dnsbl.sorbs.net
	       list.dsbl.org
	       multihop.dsbl.org
	       unconfirmed.dsbl.org
	       );	

@rhsbls = qw(
	     postmaster.rfc-ignorant.org
	     dsn.rfc-ignorant.org
	     abuse.rfc-ignorant.org
	     bogusmx.rfc-ignorant.org
	     );	

SKIP: 
{

    if ($ENV{SKIP_RBL_TESTS})
    {
	plan tests => 2;
	diag ('');
	diag ('');
	diag('You have set $SKIP_RBL_TESTS to true, thus skipping');
	diag('testing that involves DNS queries.');
	diag ('');
	use_ok('Mail::RBL');
	skip 'User requested skipping of query tests', 1;
	diag ('');
    }

    plan  tests => @prefixes*4 + (grep {/spamcop/} @prefixes)*10 + 
	@rhsbls*16 + 1;

    diag('');
    diag('');
    diag('The following tests perform queries to some known RBLs.');
    diag('Failures do not necesarily mean that the code is broken');
    diag('If failures are seen, please insure that the relevant RBL');
    diag('Can be queried from this machine.');
    diag('');
    diag('You can skip this test by setting the environment variable');
    diag('$SKIP_RBL_TESTS to true');
    diag('');

    use_ok('Mail::RBL');

    for (@prefixes)
    {
	my $rbl_i = new Mail::RBL $_;
	my $rbl_e = new Mail::RBL $_, Net::DNS::Resolver->new;
	isa_ok($rbl_i, 'Mail::RBL');
	isa_ok($rbl_e, 'Mail::RBL');

	ok(!$rbl_i->check('127.0.0.1'), 
	   "Check localhost (unblocked) against $_");
	ok($rbl_i->check('127.0.0.2'), 
	   "Check 127.0.0.2 (blocked) against $_");
    }

    for (grep { $_ =~ /spamcop/ } @prefixes)
    {
	my $rbl_i = new Mail::RBL $_;
	my $rbl_e = new Mail::RBL $_, Net::DNS::Resolver->new;
	isa_ok($rbl_i, 'Mail::RBL');
	isa_ok($rbl_e, 'Mail::RBL');

	my @r_i = $rbl_i->check('127.0.0.1');
	my @r_e = $rbl_e->check('127.0.0.1');
	ok(!@r_i, "Localhost in array context against $_ (int res)");
	ok(!@r_e, "Localhost in array context against $_ (ext res)");
	@r_i = $rbl_i->check('127.0.0.2');
	@r_e = $rbl_i->check('127.0.0.2');
	ok(@r_i == 2, "127.0.0.2 in array context against $_ (int res)");
	ok(@r_e == 2, "127.0.0.2 in array context against $_ (ext res)");
	ok($r_i[0], "True block result (int res)");
	ok($r_e[0], "True block result (ext res)");
	ok($r_i[1], "Non-empty message returned (int res)");
	ok($r_e[1], "Non-empty message returned (ext res)");
    }

    for (@rhsbls)
    {
	my $rbl_i = new Mail::RBL $_;
	my $rbl_e = new Mail::RBL $_, Net::DNS::Resolver->new;

	isa_ok($rbl_i, 'Mail::RBL');
	isa_ok($rbl_e, 'Mail::RBL');

	ok(!$rbl_i->check_rhsbl('127.0.0.1'), 
	   "Check localhost rhsbl $_ (int res)");
	ok(!$rbl_e->check_rhsbl('127.0.0.1'), 
	   "Check localhost rhsbl $_ (ext res)");
	ok($rbl_i->check_rhsbl('example.tld'),
	   "Check example.tld rhsbl $_ (int res)");
	ok($rbl_e->check_rhsbl('example.tld'),
	   "Check example.tld rhsbl $_ (ext res)");

	my @r_i = $rbl_i->check_rhsbl('127.0.0.1');
	ok(!@r_i, "Localhost in array context is false: $_ (int res)");
	my @r_e = $rbl_e->check_rhsbl('127.0.0.1');
	ok(!@r_e, "Localhost in array context is false: $_ (ext res)");
	@r_i = $rbl_i->check_rhsbl('example.tld');
	@r_e = $rbl_i->check_rhsbl('example.tld');
	ok(@r_i, "Listed domain in array context is true: $_ (int res)");
	ok(@r_e, "Listed domain in array context is true: $_ (ext res)");
	ok(@r_i == 2, "Listed domain in array context count: $_ (int res)");
	ok(@r_e == 2, "Listed domain in array context count: $_ (ext res)");
	ok($r_i[0], "Domain in array context has value: $_ (int res)");
	ok($r_i[1], "Domain in array context non-empty message: $_ (int res)");
	ok($r_e[0], "Domain in array context has true value: $_ (ext res)");
	ok($r_e[1], "Domain in array context non-empty message: $_ (ext res)");
    }
}
