#!/usr/local/bin/perl -w -I../../lib -I/SRC/sf/pmilter/pmilter/lib
# $Id: milter.pl,v 1.30 2006/03/22 15:42:27 tvierling Exp $
#
# Copyright (c) 2002 Todd Vierling <tv@pobox.com> <tv@duh.org>.
# This file is hereby released to the public and is free for any use.
#
# This is the actual Mail::Milter instance running in production on the
# duh.org mail server as of the RCS datestamp above.  This may be useful
# to you as a template or suggestion for your own milter installation.
#

use strict;
use warnings;

use DB_File;
use Fcntl;
use Carp qw{verbose};
use Mail::Milter::Chain;
use Mail::Milter::Module::AccessDB;
use Mail::Milter::Module::ConnectASNBL;
use Mail::Milter::Module::ConnectDNSBL;
use Mail::Milter::Module::ConnectMatchesHostname;
use Mail::Milter::Module::ConnectRegex;
use Mail::Milter::Module::HeaderFromMissing;
use Mail::Milter::Module::HeaderRegex;
use Mail::Milter::Module::HeaderValidateMIME;
use Mail::Milter::Module::HeloRawLiteral;
use Mail::Milter::Module::HeloRegex;
use Mail::Milter::Module::HeloUnqualified;
use Mail::Milter::Module::MailBogusNull;
use Mail::Milter::Module::MailDomainDNSBL 0.04;
use Mail::Milter::Module::MailDomainDotMX;
use Mail::Milter::Module::SPF;
use Mail::Milter::Module::VirusBounceSpew;
use Mail::Milter::Wrapper::DecodeSRS;
use Mail::Milter::Wrapper::DeferToRCPT;
use Mail::Milter::Wrapper::RejectMsgEditor;
use Sendmail::Milter 0.18;
use Socket;

# temporary flag to turn on 6to4-to-IPv4 translation
use Sendmail::PMilter::Context;
$Sendmail::PMilter::Context::Map6to4 = 1;

#
# This file is arranged in top-down order.  Objects constructed
# closer to the top have deeper nesting into the milter tree,
# and will be reached last; conversely, objects at the bottom are
# reached first.
#

##### External data
#
# So let's try pretending we know how to do access_db here.
# Unfortunately there isn't yet auto-reopen logic, so my script
# used to regenerate access.db also restarts this milter (for now).
#

$Mail::Milter::Module::AccessDB::DEBUGLEVEL = 0;

my %access;
tie(%access, 'DB_File', '/etc/mail/access_milter.db', O_RDONLY, 0644, $DB_BTREE)
	|| die "can't open accessdb: $!";

my $access_db_full = &AccessDB(\%access)->ignore_tempfail(1);

# here's an instance to wrap in DecodeSRS, so remove "connect" and "helo"
my $access_db_noconnect = &AccessDB(\%access)->ignore_tempfail(1);
delete $access_db_noconnect->{connect};
delete $access_db_noconnect->{helo};

##### Bad headers
#
# It would be nice if we rejected before DATA, but alas, that's not
# always possible.  However, there are some distinct spamsigns
# present in mail headers.  YMMV.
#

my $spam_headers = &HeaderRegex(
	# known spamware
	'^X-(?:AD2000-Serial|Advertisement):',
	'^X-Mailer: (?:Mail Bomber|Accucast)',

	# older Pegasus does this, but *lots* of spamware does too
	'^Comments: Authenticated sender is',

	# the law says you must tag, and my sanity says I must block
	'^Subject: (ADV|SEXUALLY-EXPLICIT) ?:',

	# current bad eggs
	'^Subject:\s+YUKOS OIL\s*$',

	# Suresh Ramasubramanian <mallet@BLACKEHLO.CLUESTICK.ORG> claimed this is OK
	'^Received:.*\.mr\.outblaze\.com',
)->set_message(
	'NO UCE means NO SPAM (no kidding!)'
);

##### Dynamic pool rDNS, with exceptions.
# 
# "Good" ISPs partition their dynamic pools into easy-to-identify
# subdomains.  But some don't, so here we go....
#

my $dynamic_rdns = new Mail::Milter::Chain(
	# Grrr.  I shouldn't have to do this.  GET REAL rDNS, PEOPLE!
	&ConnectRegex(
		'\.(?:biz\.rr\.com|ipxserver\.de|knology\.net|netrox\.net|dq1sn\.easystreet\.com|(?:scrm01|snfc21)\.pacbell\.net)$',
		'^wsip-[\d-]+\..*\.cox\.net$',
		'^UNKNOWN-[\d-]+\.yahoo\.com$',
		'64.201.182.287', # hpeyerl@netbsd.org (20051005)
	)->accept_match(1),

	&ConnectRegex(
		'^cablelink[\d-]+\.intercable\.net$',
	)->set_message(
		'Dynamic pool:  Connecting hostname %H is a dynamic address.  If this mail has been rejected in error'
	),
	&ConnectMatchesHostname->set_message(
		'Dynamic pool:  Connecting hostname %H contains IP address %A.  If this mail has been rejected in error'
	),
)->accept_break(1);

##### Custom milter modules
#
# Don't ask and don't use.  These are duh.org site-specific, and are likely
# of zero usefulness to anyone else.
#

# (empty)

##### Per-country restrictions
#
# The following special hack has existed in the duh.org mail config in some
# form for a very long time.  It requires a proper /usr/share/misc/country
# file (originally from *BSD) to map the two-letter country codes back to
# their ISO numeric equivalents used in zz.countries.nerd.dk.
#

# on parole: CO JO MY PK TH TW
my @ccs = qw(AR BR CL CN KR MX NG SG TM);
my %ccs = map { $_ => 1 } @ccs;

my @zzccs;

open(CC, '</usr/share/misc/country') || die $!;
while (<CC>) {
	s/#.*$//;
	s/\s+$//; # also strips newlines

	my @entry = split(/\t/);
	next unless @entry;

	if ($ccs{$entry[1]}) {
		$entry[3] =~ s/^0+//;
		push(@zzccs, inet_ntoa(pack('N', 0x7f000000 + $entry[3])));
	}
}
close(CC);

##### DNSBL checks
#
# There's quite a few used here, not all of which are appropriate for all
# sites.  My site is somewhere between "lenient" and "strict", but YMMV.
# Use with caution.
#

# ordering rationale: in each set, zones queried in an earlier set are
# queried first in subsequent sets so as to reuse named-cached values

my $country_msg = 'Access denied to %A: Due to excessive spam, we do not normally accept mail from your country';
my @country_dnsbls = (
	&ConnectDNSBL('zz.countries.nerd.dk', @zzccs)->set_message($country_msg),
);

my $relay_msg = 'Access denied to %A: This address is vulnerable to open-relay/open-proxy attacks (listed in %L)';
my @relayinput_dnsbls = (
	&ConnectDNSBL('combined.njabl.org', '127.0.0.2', '127.0.0.9')->set_message($relay_msg),
	&ConnectDNSBL('dnsbl.sorbs.net', (map "127.0.0.$_", (2,3,4,5,9)))->set_message($relay_msg),
	&ConnectDNSBL('list.dsbl.org')->set_message($relay_msg),
);

my $dynamic_msg = 'Dynamic pool:  Connecting address %A is a dynamic address (listed in %L).  If this mail has been rejected in error';
my @dynamic_dnsbls = (
	&ConnectDNSBL('pdl.spamhosts.duh.org', '127.0.0.3')->set_message($dynamic_msg),
	&ConnectDNSBL('combined.njabl.org', '127.0.0.3')->set_message($dynamic_msg),
	&ConnectDNSBL('dnsbl.sorbs.net', '127.0.0.10')->set_message($dynamic_msg),
);

# ...and these use the default message.
my @generic_dnsbls = (
	&ConnectDNSBL('sbl-xbl.spamhaus.org'),
	&ConnectDNSBL('combined.njabl.org', '127.0.0.4'),
	&ConnectDNSBL('l1.spews.dnsbl.sorbs.net'),
#	&ConnectDNSBL('spews.blackholes.us'), # alternate for SPEWS
);

my @rhsbls = (
	&MailDomainDNSBL('multi.surbl.org', sub {
		if (inet_ntoa(shift) =~ /^127\.0\.0\.(\d+)$/) {
			# ws + ob + ab + jp.surbl.org
			return ($1 & (4|16|32|64));
		}
		undef;
	})->check_superdomains(-2),
	&MailDomainDNSBL('multi.uribl.com', '127.0.0.2')->check_superdomains(-2),
	&MailDomainDNSBL('rhsbl.ahbl.org'),
);

##### Sender Policy Framework (http://spf.pobox.com/)
#
# This looks a little strange at first, but what it's actually doing
# is providing a chain of checks, sarting with SPF, but which will
# discard the results of all other checks if the SPF "pass"es.
#

my $spf_whitelisted_chain = new Mail::Milter::Chain(
#	&SPF	->local_rules('ip4:216.240.140.0/26 mx:hostofhosts.com')
#		->local_rules('include:sourceforge.net')
#		->set_message('SPF check for %M failed')
#		->whitelist_pass(1),
	&DeferToRCPT(new Mail::Milter::Chain(
		$dynamic_rdns,
		@dynamic_dnsbls,
		@country_dnsbls,
#		require('greylist.pl'),
	))
)->accept_break(1);

##### Inner chain: main collection of checks
#
# As well as the more complicated checks above, I've added some
# simpler ones directly in-line below.
#

# This chain is needed both normally and after SRS decoding:
my $envfrom_checks = new Mail::Milter::Chain(
	&MailDomainDotMX->ignore_tempfail(1),
	@rhsbls,
);

my $inner_chain = new Mail::Milter::Chain(
	$access_db_full,
	$spf_whitelisted_chain,
	@relayinput_dnsbls,
	@generic_dnsbls,
	&HeloUnqualified,
	&HeloRawLiteral,
	&DecodeSRS($access_db_noconnect),
	&DecodeSRS($envfrom_checks),
	$envfrom_checks,
	&HeaderFromMissing,
	&HeaderValidateMIME,
	$spam_headers,
	&MailBogusNull,
	&VirusBounceSpew,
	{
		connect => sub {
			my $ctx = shift;
			my $host = shift;

			$ctx->set_key(host => $host);

			# temporarily forgive IPv6 rDNS failures
			if ($host =~ /^\[/ && $host !~ /:/) {
				$ctx->setreply(451, '4.7.0', "Cannot find the reverse DNS for $host; see http://postmaster.info.aol.com/info/rdns.html for more information, or e-mail postmaster\@duh.org for assistance.");
				return SMFIS_TEMPFAIL;
			}
			SMFIS_CONTINUE;
		},
		helo => sub {
			my $ctx = shift;
			my $helo = shift;

			# current zombieware issue: 8 hex digits
			if ($helo =~ /^\x{8}$/) {
				$ctx->setreply(554, '5.7.0', "Bad HELO value '" + $helo + "'");
				return SMFIS_REJECT;
			}
			SMFIS_CONTINUE;
		},
		envfrom => sub {
			my $ctx = shift;
			my $envfrom = shift;
			my $fromattrs = +{ map { split(/=/, lc) } @_ };

			$ctx->set_key(envfrom => $envfrom);
			$ctx->set_key(fromattrs => $fromattrs);

			SMFIS_CONTINUE;
		},
		envrcpt => sub {
			my $ctx = shift;
			my $envrcpt = shift;
			my $envfrom = $ctx->get_key('envfrom');
			my $fromattrs = $ctx->get_key('fromattrs');
			my $host = $ctx->get_key('host');

			if ($host !~ /\.rollernet\.us/ && $envrcpt =~ /\@(duh\.org|smargon\.net)/) {
				# for domains we know to have a secondary MX,
				# kick back to the secondary for known high-bw mail:
				if (defined($fromattrs->{size}) && $fromattrs->{size} > 150000) {
					$ctx->setreply(452, '4.3.0', "Bandwidth load is currently too high for this message; please try my secondary MXs");
					return SMFIS_TEMPFAIL;
				}
			}

			SMFIS_CONTINUE;
		},
	},
);

##### Error message rewriter: point user to postmaster@duh.org
#
# Since postmaster@duh.org is exempted below, prompting the user
# to send mail there is an in-band way to receive messages about
# blocking errors from legit users.  This is much more desirable
# then redirecting to a URL.
#

my $rewritten_chain = &RejectMsgEditor($inner_chain, sub {
	s,$, -- Please e-mail postmaster\@duh.org for assistance.,;
});

##### Outer chain: "postmaster" recipients get everything; exempt hosts.
#
# This is accomplished by using a chain in "accept_break" mode,
# where connect from particular hosts (like localhost) and envrcpt
# on "postmaster@" returns SMFIS_ACCEPT and thus skips any other
# return value pending.
#
# For the postmaster@ check to work, this requires funneling errors
# through "DeferToRCPT" in order to ensure that the RCPT TO: phase
# is reached.
#

# First fetch the /etc/mail/relay-domains list.
# Note that I already put "localhost" in that file, so it's not
# specified again in the call to ConnectRegex below.

my @relay_domain_regexes = ( 'kasserver\.com$', '216.168.47.180' );
open(I, '</etc/mail/relay-domains');
while (<I>) {
	chomp;
	s/#.*$//;
	s/^\s+//;
	s/\s+$//;
	next if /^$/;

	# Dots are escaped to make them valid in REs.
	s/\./\\\./g;
	if (/^[0-9\\\.]+$/) {
		# IP address; match a literal.

		s/$/\]/ unless /\\\.$/; # if not ending in a dot, match exactly
		push(@relay_domain_regexes, qr/^\[$_/i);
	} else {
		# Domain/host name; match string as-is.

		s/^/\^/ unless /^\\\./; # if not starting with a dot, match exactly
		push(@relay_domain_regexes, qr/$_$/i);
	}
}
close(I);

my $outer_chain = new Mail::Milter::Chain(
	&ConnectRegex(
		@relay_domain_regexes,
	)->accept_match(1),
#	{
#		# add delays to certain parts of transactions to trip ratware
#		# (this requires setting T=R:4m or so in sendmail.mc)
#		connect => sub {
#			my $ctx = shift;
#			my $host = shift;
#			$ctx->setpriv(1) if ($host =~ /^\[/); # flag no rDNS
#			SMFIS_CONTINUE;
#		},
#		envfrom => sub {
#			my $ctx = shift;
#			sleep 120 if $ctx->getpriv(); # no rDNS
#			SMFIS_CONTINUE;
#		},
#		envrcpt => sub {
#			my $ctx = shift;
#			sleep 30 if $ctx->getpriv(); # no rDNS
#			SMFIS_CONTINUE;
#		},
#	},

	# always allow anything to abuse/postmaster
	{
		envrcpt => sub {
			shift; # $ctx
			(shift =~ /^<?(?:abuse|postmaster)\@/i) ?
				SMFIS_ACCEPT : SMFIS_CONTINUE;
		},
	},
	&DeferToRCPT($rewritten_chain),
)->accept_break(1);

##### The milter itself.
#
# I personally use Sendmail::PMilter under the covers, but I'm
# deliberately using the Sendmail::Milter API below to make this
# example work outside my installation.
#

Sendmail::Milter::auto_setconn('pmilter');
Sendmail::Milter::register('pmilter', $outer_chain, SMFI_CURR_ACTS);
Sendmail::Milter::main(25, 50);
