#!/usr/bin/env perl
# =============================================================================
# t/github_2.t  --  Regression tests for GitHub issue #2
#   https://github.com/nigelhorne/Email-Abuse-Investigator/issues/2
#
# Two bugs in _parallel_resolve_hosts when AnyEvent::DNS is installed:
#
#   Bug 1 — empty hash deadlock.
#     _parallel_resolve_hosts({},{}) created an AnyEvent condvar, set
#     $pending=0, never entered the for-loop, and called $cv->recv.
#     With no callbacks ever firing $cv->send, recv blocked forever.
#     Fix: return early when %$hostnames_ref is empty
#          (return unless $HAS_ANYEVENT_DNS && %$hostnames_ref).
#
#   Bug 2 — wrong AnyEvent::DNS API, fatal crash on multi-URL emails.
#     AnyEvent::DNS::resolve($host,'A',$cb) was called as a bare package
#     function.  AnyEvent::DNS::resolve is a method on resolver objects, so
#     $host was treated as the invocant ($self) and Perl died with:
#       Can't locate object method "wait_for_slot" via package "<hostname>"
#     This killed every test that called embedded_urls() with 2+ URL hosts.
#     Fix: AnyEvent::DNS::resolver->resolve($host,'a',$cb).
# =============================================================================

use strict;
use warnings;

use Test::Most;
use Test::Needs;
use FindBin qw( $Bin );
use lib "$Bin/../lib";
use Email::Abuse::Investigator;

# ---------------------------------------------------------------------------
# Email factory: two distinct URL hostnames in the body so the parallel
# resolver path is triggered ($scalar(keys %hostname_needed) > 1).
# ---------------------------------------------------------------------------
sub make_two_url_email {
	my ($u1, $u2) = @_;
	$u1 //= 'https://host-alpha.example/foo';
	$u2 //= 'https://host-beta.example/bar';
	return <<"END_EMAIL";
Received: from mail.example.com (91.198.174.42)
 by mx.test (Postfix); Mon, 01 Jan 2024 00:00:00 +0000
From: Sender <sender\@example.com>
To: victim\@bandsman.co.uk
Subject: Test
Date: Mon, 01 Jan 2024 00:00:00 +0000
Message-ID: <github2\@example.com>

$u1 $u2
END_EMAIL
}

# ---------------------------------------------------------------------------
# Fake AnyEvent::DNS resolver — NXDOMAIN simulation.
#
# Purpose: prove the module calls $resolver->resolve(...) (the correct OO
# form), not AnyEvent::DNS::resolve($host,...).
#
# Mechanics: replace AnyEvent::DNS::resolver() with a sub that returns one of
# these objects.  When _parallel_resolve_hosts calls $resolver->resolve(...),
# this package's resolve() is invoked with ($self,$host,$type,$cb).  It calls
# $cb->() synchronously with no answers, simulating NXDOMAIN.  $pending
# decrements to zero, $cv->send fires, and $cv->recv returns immediately.
#
# Detection: if the old bug were in place (AnyEvent::DNS::resolve($host,...)),
# Perl would call AnyEvent::DNS::resolve with the hostname as $self and die
# "Can't locate object method 'wait_for_slot' via package 'host-alpha.example'"
# — which is exactly the crash this test must not see.
# ---------------------------------------------------------------------------
{
	package t::FakeResolver::NXDOMAIN;
	sub new     { bless {}, shift }
	sub resolve {
		my ($self, $host, $type, $cb) = @_;
		$cb->();    # empty @answers = NXDOMAIN; decrements $pending in callback
	}
}

# ---------------------------------------------------------------------------
# Fake resolver that returns a single A record — lets us verify that
# _parallel_resolve_hosts actually populates %$cache_ref.
# ---------------------------------------------------------------------------
{
	package t::FakeResolver::WithIP;
	use Readonly;
	Readonly my $STUB_IP  => '9.9.9.9';
	Readonly my $STUB_TTL => 300;
	sub new     { bless {}, shift }
	sub resolve {
		my ($self, $host, $type, $cb) = @_;
		# RR format: [$name, $type, $class, $ttl, $address]
		$cb->([$host, 'a', 'in', $STUB_TTL, $STUB_IP]);
	}
}

# ---------------------------------------------------------------------------
# Helper: reload Email::Abuse::Investigator with AnyEvent::DNS blocked so
# $HAS_ANYEVENT_DNS is re-evaluated as false.  Mirrors the without_optionals()
# approach in t/integration.t.  Accepts a coderef to run in the blocked state
# and restores everything afterwards.
# ---------------------------------------------------------------------------
sub without_ae_dns {
	my ($code) = @_;

	unless (eval { require Test::Without::Module; 1 }) {
		Test::More::plan(skip_all => 'Test::Without::Module not installed');
		return;
	}

	# Flush the global CHI cache so stale url:/dom: entries from earlier
	# subtests do not shadow fresh stub data inside the reloaded module.
	eval {
		require CHI;
		CHI->new(driver => 'Memory', global => 1, expires_in => 3600)->clear();
	};

	# Save the AnyEvent::DNS %INC entry (may be undef if not installed).
	my %saved_inc;
	for my $mod (qw(AnyEvent::DNS)) {
		(my $key = "$mod.pm") =~ s{::}{/}g;
		$saved_inc{$key} = delete $INC{$key};
	}

	# Block the module and reload Email::Abuse::Investigator so its
	# $HAS_ANYEVENT_DNS flag is set to false.
	Test::Without::Module->import('AnyEvent::DNS');
	delete $INC{'Email/Abuse/Investigator.pm'};
	{ local $SIG{__WARN__} = sub { warn @_ unless $_[0] =~ /redefined/ }; require Email::Abuse::Investigator; }

	$code->();

	# Restore: unblock, reinstate %INC, reload with full dependencies.
	Test::Without::Module->unimport('AnyEvent::DNS');
	for my $key (keys %saved_inc) {
		$INC{$key} = $saved_inc{$key} if defined $saved_inc{$key};
	}
	delete $INC{'Email/Abuse/Investigator.pm'};
	{ local $SIG{__WARN__} = sub { warn @_ unless $_[0] =~ /redefined/ }; require Email::Abuse::Investigator; }
}

# =============================================================================
# SECTION 1: Tests WITH AnyEvent::DNS
# =============================================================================

subtest 'Bug 1 — empty hash returns immediately (WITH AnyEvent::DNS)' => sub {
	test_needs 'AnyEvent::DNS';

	# Strategy: call _parallel_resolve_hosts with an empty host hash.
	# Before the fix $pending==0, no callbacks were scheduled, and $cv->recv
	# blocked forever.  This test would hang — not fail — if the bug is present.
	my $inv = new_ok('Email::Abuse::Investigator');
	lives_ok { $inv->_parallel_resolve_hosts({}, {}) }
		'_parallel_resolve_hosts({},{}) returns without hanging';
};

subtest 'Bug 2 — correct OO resolver API does not crash (WITH AnyEvent::DNS)' => sub {
	test_needs 'AnyEvent::DNS';

	# Strategy: replace AnyEvent::DNS::resolver() with a sub returning our fake.
	# If the old API bug is still present, the module calls
	#   AnyEvent::DNS::resolve($host, 'a', $cb)
	# treating $host as the invocant and dying with "wait_for_slot".
	# With the correct fix ($resolver->resolve($host,'a',$cb)), the fake's
	# resolve() is called cleanly, $cb fires synchronously, and no crash occurs.
	no warnings 'redefine';
	local *AnyEvent::DNS::resolver                            = sub { t::FakeResolver::NXDOMAIN->new() };
	local *Email::Abuse::Investigator::_resolve_host          = sub { '1.2.3.4' };
	local *Email::Abuse::Investigator::_whois_ip              = sub { { org => 'TestOrg', abuse => 'a@b.example' } };
	local *Email::Abuse::Investigator::_domain_whois          = sub { undef };
	local *Email::Abuse::Investigator::_follow_redirect_chain = sub { undef };

	my $inv = new_ok('Email::Abuse::Investigator');
	$inv->parse_email(make_two_url_email());

	my @urls;
	lives_ok { @urls = $inv->embedded_urls() }
		'embedded_urls with 2 URL hosts does not crash';
	is scalar @urls, 2, 'both URLs returned (sequential fallback used after NXDOMAIN)';
};

subtest 'Bug 2 — parallel resolve populates host cache (WITH AnyEvent::DNS)' => sub {
	test_needs 'AnyEvent::DNS';

	# Strategy: use the WithIP fake so we can verify the cache is populated.
	# This also checks that the callback argument position is correct:
	# $answers[0][4] must be the IP address in the AnyEvent::DNS RR format.
	no warnings 'redefine';
	local *AnyEvent::DNS::resolver = sub { t::FakeResolver::WithIP->new() };

	my $inv   = new_ok('Email::Abuse::Investigator');
	my %hosts = ('cache-a.example' => 1, 'cache-b.example' => 1);
	my %cache;

	lives_ok { $inv->_parallel_resolve_hosts(\%hosts, \%cache) }
		'_parallel_resolve_hosts returns without dying';
	is $cache{'cache-a.example'}{ip}, '9.9.9.9', 'cache-a populated with fake IP';
	is $cache{'cache-b.example'}{ip}, '9.9.9.9', 'cache-b populated with fake IP';
};

# =============================================================================
# SECTION 2: Tests WITHOUT AnyEvent::DNS (sequential fallback)
# =============================================================================

subtest 'WITHOUT AnyEvent::DNS: embedded_urls works via sequential fallback' => sub {
	without_ae_dns(sub {
		# Strategy: with AnyEvent::DNS absent, $HAS_ANYEVENT_DNS=false and
		# _parallel_resolve_hosts returns immediately without touching the condvar.
		# embedded_urls() must fall back to the sequential _resolve_host loop.
		no warnings 'redefine';
		local *Email::Abuse::Investigator::_resolve_host          = sub { '5.6.7.8' };
		local *Email::Abuse::Investigator::_whois_ip              = sub { { org => 'Fallback ISP', abuse => 'c@d.example' } };
		local *Email::Abuse::Investigator::_domain_whois          = sub { undef };
		local *Email::Abuse::Investigator::_follow_redirect_chain = sub { undef };

		my $inv = new_ok('Email::Abuse::Investigator');
		$inv->parse_email(make_two_url_email());

		my @urls;
		lives_ok { @urls = $inv->embedded_urls() }
			'embedded_urls does not die without AnyEvent::DNS';
		is scalar @urls, 2,       'both URLs returned via sequential path';
		is $urls[0]{ip}, '5.6.7.8', 'sequential _resolve_host stub used for URL 1';
		is $urls[1]{ip}, '5.6.7.8', 'sequential _resolve_host stub used for URL 2';
	});
};

subtest 'WITHOUT AnyEvent::DNS: _parallel_resolve_hosts is a no-op' => sub {
	without_ae_dns(sub {
		# Strategy: call _parallel_resolve_hosts with a non-empty hash and verify
		# the cache is not touched — the function must return before creating a
		# condvar or making any AnyEvent calls.
		my $inv = new_ok('Email::Abuse::Investigator');
		my %cache;
		lives_ok { $inv->_parallel_resolve_hosts({'noop.example' => 1}, \%cache) }
			'_parallel_resolve_hosts does not die without AnyEvent::DNS';
		ok !%cache, 'cache remains empty (no-op without AnyEvent::DNS)';
	});
};

done_testing();
