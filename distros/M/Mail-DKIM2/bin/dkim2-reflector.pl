#!/usr/bin/perl
use 5.020; use strict; use warnings;
use FindBin;
use lib "$FindBin::Bin/../lib";
use Mail::DKIM2::Reflector;
use Net::SMTP;
use Sys::Syslog qw(:standard :macros);

# Usage:
#   Postfix pipe(8):  dkim2-reflect ${user} ${sender}   (preferred; see SERVER.md)
#   legacy alias:     dkim2-reflect <mode>              (sender from $ENV{SENDER})
# Reads the message on stdin.
#
# Verifies the incoming message, applies the per-mode transformation, signs as
# dkim2.com (when the incoming DKIM2 chain verified, or as a DKIM1 bridge), and
# submits the reply to the milter-free injection service so it is not re-signed.
#
# The reflector never bounces; problems are logged to syslog (LOG_MAIL) so they
# are not silently lost (postfix discards a piped command's stderr on exit 0).

openlog('dkim2-reflector', 'pid', LOG_MAIL);
sub logmsg { my $m = shift; warn "dkim2-reflector: $m\n"; syslog(LOG_WARNING, '%s', $m); }

# Postfix pipe(8) passes the recipient localpart and envelope sender as argv
# macros (${user} ${sender}); the legacy local(8) alias passed a bare <mode>
# with the sender in $ENV{SENDER}. Accept both. pipe(8) is preferred because,
# unlike local(8), it does NOT prepend a Delivered-To: header — which would be
# hashed into our Message-Instance and make it unverifiable. See
# docs/dkim2-implementer-guide.md.
my %VALID_MODE = map { $_ => 1 } qw(raw subject body both redacted damage fresh brand brand-nd dsn);
my $arg0 = $ARGV[0] // '';
# Modes may contain hyphens (e.g. brand-nd), so match [\w-]+ not just \w+.
my $mode = ($arg0 =~ /^reflector-([\w-]+)$/) ? $1 : $arg0;
unless ($VALID_MODE{$mode}) {
    logmsg("unknown mode " . ($arg0 ne '' ? "'$arg0'" : '(none)') . ", dropping");
    exit 0;
}

my $sender = defined $ARGV[1] ? $ARGV[1] : ($ENV{SENDER} // '');

# Null return-path (a bounce) -> nothing to reflect; drop quietly. pipe(8)
# expands ${sender} for the null sender to $null_sender (default
# "MAILER-DAEMON"), so treat that as null too.
if ($sender eq '' || $sender eq '<>' || $sender =~ /^mailer-daemon(?:[@>]|$)/i) {
    logmsg("empty/null sender ($sender), dropping");
    exit 0;
}

my $message = do { local $/; <STDIN> };

my $result = eval {
    if ($mode eq 'fresh') {
        # Originate a brand-new message rather than reflecting the incoming one.
        my $msg = Mail::DKIM2::Reflector::generate(
            sender   => $sender,
            domain   => 'dkim2.com',
            selector => 'sel1',
            keyfile  => '/etc/dkim2/reflector/sel1.key',
            mailfrom => 'reflector-bounces@dkim2.com',
        );
        { message => $msg, signed => 1, basis => 'origin', mode => 'fresh' };
    } elsif ($mode eq 'brand' || $mode eq 'brand-nd') {
        # Brand demo: if the sender delegated a key via a dkim2test._domainkey
        # CNAME, originate a two-signature message; otherwise fresh + error body.
        # brand-nd uses the nd= "imaginary hop" encoding on the i=1 brand hop
        # instead of mf=/rt= (draft-06 §9.3).
        my $bd = $sender; $bd =~ s/.*\@//;
        my $delegated = Mail::DKIM2::Reflector::_dkim2test_cname_ok($bd);
        my $msg = Mail::DKIM2::Reflector::generate_brand(
            sender   => $sender,
            domain   => 'dkim2.com',
            selector => 'sel1',
            keyfile  => '/etc/dkim2/reflector/sel1.key',
            mailfrom => 'reflector-bounces@dkim2.com',
            delegated      => $delegated,
            brand_selector => 'dkim2test',
            brand_keyfile  => '/etc/dkim2/reflector/dkim2test.key',
            nd             => ($mode eq 'brand-nd' ? 1 : 0),
        );
        { message => $msg, signed => 1, basis => ($delegated ? 'brand' : 'origin'), mode => $mode };
    } elsif ($mode eq 'dsn') {
        # Return a DKIM2-signed Delivery Status Notification to the sender,
        # regardless of whether the incoming message was DKIM2-signed.
        my $msg = Mail::DKIM2::Reflector::generate_dsn(
            sender   => $sender,
            message  => $message,
            domain   => 'dkim2.com',
            selector => 'sel1',
            keyfile  => '/etc/dkim2/reflector/sel1.key',
        );
        { message => $msg, signed => 1, basis => 'origin', mode => 'dsn' };
    } else {
        Mail::DKIM2::Reflector::reflect(
            message  => $message,
            mode     => $mode,
            sender   => $sender,
            domain   => 'dkim2.com',
            selector => 'sel1',
            keyfile  => '/etc/dkim2/reflector/sel1.key',
            mailfrom => 'reflector-bounces@dkim2.com',
            authserv_id => 'mail.dkim2.com',
        );
    }
};
if (my $err = $@) {
    chomp(my $e = $err);
    logmsg("reflect failed for sender=$sender mode=$mode: $e");
    # Keep the offending message for debugging (single overwritten file).
    if (open my $fh, '>', '/var/tmp/dkim2-reflector-lasterror.eml') {
        print $fh $message; close $fh;
        logmsg("wrote failing message to /var/tmp/dkim2-reflector-lasterror.eml");
    }
    exit 0;   # never bounce
}

# Add classic DKIM1 signatures so the reply looks like real-world mail. Always
# sign as dkim2.com; for a delegated brand reply also sign as the brand domain
# with the delegated key (this is what DMARC-aligns From: dkim2demo@<brand>).
my @dkim1 = ({ domain => 'dkim2.com', selector => 'sel1',
               keyfile => '/etc/dkim2/reflector/sel1.key' });
if (($mode eq 'brand' || $mode eq 'brand-nd') && $result->{basis} eq 'brand') {
    my $bd = $sender; $bd =~ s/.*\@//;
    unshift @dkim1, { domain => $bd, selector => 'dkim2test',
                      keyfile => '/etc/dkim2/reflector/dkim2test.key' };
}
my $signed1 = eval { Mail::DKIM2::Reflector::sign_dkim1($result->{message}, @dkim1) };
if ($signed1) { $result->{message} = $signed1; } else { logmsg("dkim1 sign failed: $@"); }

# Inject to the milter-free postfix service (see deploy/SERVER.md) so we do not
# get re-signed by the outbound milter.
my $smtp = Net::SMTP->new('127.0.0.1', Port => 10588, Timeout => 30)
    or do { logmsg("cannot connect to injector on 127.0.0.1:10588"); exit 0; };
$smtp->mail('reflector-bounces@dkim2.com');
$smtp->recipient($sender);
$smtp->data();
$smtp->datasend($result->{message});
$smtp->dataend();
$smtp->quit;
logmsg("reflected mode=$mode sender=$sender signed=$result->{signed} basis=$result->{basis}");
exit 0;
