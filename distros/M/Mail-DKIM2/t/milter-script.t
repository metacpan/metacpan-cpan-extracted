#!/usr/bin/perl
#
# bin/dkim2-milter -- the standalone Sendmail::PMilter daemon that is the
# LIVE outbound signer on mail.dkim2.com.
#
# t/milter.t covers the Mail::Milter::Authentication handlers; nothing covered
# this script, which is how the 2026-08-26 §11 unsigned-instance check shipped
# with its signing opt-out wired into Signer.pm and Reflector.pm but not into
# this script's pre-sign verify. Every list post whose upstream chain was
# signed then left mail.dkim2.com with an unsigned Message-Instance m=2 and no
# DKIM2-Signature i=2 (2026-09-10, the first day Fastmail signed).
#
# So this drives the real script, over a real milter socket, as the MTA would.
# Speaks just enough of the milter protocol (v6, one packet per reply, see
# Sendmail::PMilter::Context) to hand it one message and collect the headers
# it inserts at end-of-message.
use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/../lib", "$FindBin::Bin/lib";
use File::Temp qw(tempdir);
use Path::Tiny;
use IO::Socket::UNIX;
use Socket qw(SOCK_STREAM);
use Email::MIME;
use Mail::DKIM2::Signer;
use Mail::DKIM2::Verifier;
use Mail::DKIM2::MessageInstance;
use DKIM2TestKeys;

plan skip_all => 'Sendmail::PMilter 1.28 or later not installed (1.27 never answered MAIL FROM:<>)'
    unless eval { require Sendmail::PMilter; Sendmail::PMilter->VERSION(1.28); 1 };

my $SCRIPT   = "$FindBin::Bin/../bin/dkim2-milter";
my $LIB      = "$FindBin::Bin/../lib";
my $DNS_JSON = path("$FindBin::Bin/data/dns.json");
my $KEYS     = path("$FindBin::Bin/data/keys");
plan skip_all => 't/data keys and dns.json not available'
    unless $DNS_JSON->exists && $KEYS->child('sel1._domainkey.test2.dkim2.com.pem')->exists;

my $EOL = "\015\012";

# --- Spawn the milter: outbound mode, signing for test2.dkim2.com from a keydir ---

my $dir  = tempdir(CLEANUP => 1);
my $sock = "$dir/out.sock";
my $log  = "$dir/milter.log";
path("$dir/keys/test2.dkim2.com")->mkpath;
$KEYS->child('sel1._domainkey.test2.dkim2.com.pem')->copy("$dir/keys/test2.dkim2.com/sel1.key");
path("$dir/snap")->mkpath;

my $pid = fork();
die "fork: $!" unless defined $pid;
if ($pid == 0) {
    open STDERR, '>>', $log or die $!;
    open STDOUT, '>>', $log or die $!;
    exec $^X, "-I$LIB", $SCRIPT,
        '--mode', 'outbound',
        '--socket', "unix:$sock",
        '--keydir', "$dir/keys",
        '--dns-json', "$DNS_JSON",
        '--snapshot-dir', "$dir/snap"
        or die "exec: $!";
}
END { local $?; kill "TERM", $pid if $pid; waitpid($pid, 0) if $pid; }

for (1 .. 50) { last if -S $sock; select(undef, undef, undef, 0.2); }
ok(-S $sock, 'milter is listening') or BAIL_OUT("milter never came up:\n" . path($log)->slurp);

sub milter_log { path($log)->slurp }

# --- Minimal MTA side of the milter protocol ---

sub pkt {
    my ($s, $cmd, $data) = @_;
    $data //= '';
    defined syswrite($s, pack('N', 1 + length $data) . $cmd . $data) or die "write: $!";
}

sub read_n {
    my ($s, $n) = @_;
    my $buf = '';
    local $SIG{ALRM} = sub { die "timeout waiting for milter reply\n" };
    alarm(20);
    while (length($buf) < $n) {
        my $got = sysread($s, my $chunk, $n - length $buf);
        die "milter closed the connection\n" if defined $got && $got == 0;
        die "read: $!" unless defined $got;
        $buf .= $chunk;
    }
    alarm(0);
    return $buf;
}

sub read_pkt {
    my ($s) = @_;
    my $len = unpack('N', read_n($s, 4));
    my $body = read_n($s, $len);
    return (substr($body, 0, 1), substr($body, 1));
}

# Read until a final verdict, collecting header modifications on the way.
sub read_verdict {
    my ($s, $mods) = @_;
    while (1) {
        my ($code, $data) = read_pkt($s);
        if ($code eq 'i') {                # SMFIR_INSHEADER: idx, name\0value\0
            my ($idx, $rest) = (unpack('N', $data), substr($data, 4));
            my ($name, $value) = split /\0/, $rest;
            push @$mods, { op => 'insert', idx => $idx, name => $name, value => $value };
        } elsif ($code eq 'h') {           # SMFIR_ADDHEADER
            my ($name, $value) = split /\0/, $data;
            push @$mods, { op => 'add', name => $name, value => $value };
        } elsif ($code eq 'm') {           # SMFIR_CHGHEADER
            my ($idx, $rest) = (unpack('N', $data), substr($data, 4));
            my ($name, $value) = split /\0/, $rest;
            push @$mods, { op => 'change', idx => $idx, name => $name, value => $value // '' };
        } elsif ($code eq 'p') {           # progress
            next;
        } else {
            return $code;
        }
    }
}

# Hand one message to the milter; returns the verdict and the list of header
# modifications it asked for.
sub run_milter {
    my (%a) = @_;
    my $s = IO::Socket::UNIX->new(Peer => $sock, Type => SOCK_STREAM)
        or die "connect $sock: $!";
    $s->autoflush(1);

    pkt($s, 'O', pack('NNN', 6, 0x1FF, 0));
    my ($code) = read_pkt($s);
    die "bad OPTNEG reply $code" unless $code eq 'O';

    my @mods;
    pkt($s, 'M', "<$a{from}>\0");   die 'envfrom' unless read_verdict($s, \@mods) eq 'c';
    for my $r (@{$a{rcpt}}) {
        pkt($s, 'R', "<$r>\0");     die 'envrcpt' unless read_verdict($s, \@mods) eq 'c';
    }

    my ($hdr, $body) = split /$EOL$EOL/, $a{message}, 2;
    for my $line (split /$EOL(?!\s)/, $hdr) {
        my ($name, $value) = $line =~ /^([^:\s]+):[ \t]?(.*)$/s;
        pkt($s, 'L', "$name\0$value\0");
        die 'header' unless read_verdict($s, \@mods) eq 'c';
    }
    pkt($s, 'N');                    die 'eoh' unless read_verdict($s, \@mods) eq 'c';
    pkt($s, 'B', $body);             die 'body' unless read_verdict($s, \@mods) eq 'c';
    pkt($s, 'E');
    my $verdict = read_verdict($s, \@mods);
    pkt($s, 'Q');
    close $s;
    return ($verdict, \@mods);
}

# Apply the milter's insertions the way the MTA does (each insert at index 0
# goes above everything inserted before it) to get the message as it would
# leave the MTA.
sub assemble {
    my ($message, $mods) = @_;
    my $out = $message;
    for my $m (@$mods) {
        next unless $m->{op} eq 'insert';
        my $v = $m->{value};
        $v =~ s/\r?\n/$EOL/g;
        $out = "$m->{name}: $v$EOL" . $out;
    }
    return $out;
}

sub verify {
    my ($raw) = @_;
    my $v = Mail::DKIM2::Verifier->new;
    $v->set_pubkey_callback(DKIM2TestKeys::pubkey_callback());
    $v->PRINT($raw); $v->CLOSE;
    return $v;
}

sub inserted { my ($mods, $name) = @_; grep { $_->{op} eq 'insert' && lc($_->{name}) eq lc($name) } @$mods }

# --- Fixtures ---

# An originator's message, as it arrives from test1.dkim2.com: Message-Instance
# m=1 and DKIM2-Signature i=1. Signed now, because the milter's verifier
# applies the real timestamp window.
my $PLAIN = join($EOL,
    'MIME-Version: 1.0',
    'Message-Id: <post@test1.dkim2.com>',
    'Date: Thu, 10 Sep 2026 15:47:11 +1000',
    'From: Author <author@test1.dkim2.com>',
    'To: list@test2.dkim2.com',
    'Subject: a post',
    'Content-Type: text/plain',
    '',
    "Here's a test user!",
    '');

sub originator_signed {
    my $mi  = Mail::DKIM2::MessageInstance->calculate(Email::MIME->new($PLAIN));
    my $msg = "Message-Instance: " . $mi->as_string . $EOL . $PLAIN;
    my $signer = Mail::DKIM2::Signer->new(
        Domain => 'test1.dkim2.com', Selector => 'sel1',
        Key => DKIM2TestKeys::private_key('test1.dkim2.com', 'sel1'),
        MailFrom => 'author@test1.dkim2.com', RcptTo => ['list@test2.dkim2.com'],
        Timestamp => time());
    $signer->PRINT($msg); $signer->CLOSE;
    return $signer->as_string . $EOL . $msg;
}

# What a list manager (Mailman, Sympa) does before handing the message to the
# outbound MTA: tag the subject, add List-* fields, append a footer, and record
# the change as Message-Instance m=2 with a Recipe back to m=1. The m=2 is
# UNSIGNED at this point -- signing it is the milter's job.
sub list_modified {
    my ($signed) = @_;
    my $mod = $signed;
    $mod =~ s/^Subject: /Subject: [list] /m;
    $mod =~ s/^(Content-Type: text\/plain$EOL)/List-Id: <list.test2.dkim2.com>$EOL$1/m;
    $mod .= "--$EOL" . "list footer$EOL";
    my $mi = Mail::DKIM2::MessageInstance->calculate(
        Email::MIME->new($mod), Email::MIME->new($signed));
    return "Message-Instance: " . $mi->as_string . $EOL . $mod;
}

# --- 1. Baseline: no upstream chain at all -> originate m=1 / i=1 ---
{
    my ($verdict, $mods) = run_milter(
        from => 'list-bounces@test2.dkim2.com', rcpt => ['subscriber@example.org'],
        message => $PLAIN);
    is($verdict, 'c', 'plain: milter continues');
    my @sig = inserted($mods, 'DKIM2-Signature');
    is(scalar @sig, 1, 'plain: one DKIM2-Signature inserted');
    like($sig[0]{value}, qr/\bi=1;/, 'plain: signature is i=1');
    is(scalar(inserted($mods, 'Message-Instance')), 1, 'plain: Message-Instance m=1 added');
    # draft-gondwana-dkim2-debug-header-01: every tag ends in ";", and the
    # instance action is mi-m=<N>.
    # Unfold, then drop the whitespace a consumer is told to ignore next to
    # ";" and ",".
    my @info = map { $_->{value} =~ s/\n[ \t]/ /gr =~ s/([;,])[ \t]+/$1 /gr =~ s/,[ \t]+/,/gr } inserted($mods, 'X-DKIM2-Info');
    is(scalar @info, 2, 'plain: one X-DKIM2-Info per action (mi-m=1, sign)');
    like($_, qr/^draft=\S+; repo=\S+; date=\d{4}-\d\d-\d\d; sw=dkim2-milter; action=/, 'plain: provenance tags lead') for @info;
    like($_, qr/;\z/, 'plain: the last tag is followed by ";"') for @info;
    like("@info", qr/action=mi-m=1; hc=\d+; hn=\S+;/, 'plain: action=mi-m=1 with hc= and hn=');
    like("@info", qr/action=sign d=test2\.dkim2\.com a=rsa-sha256;/, 'plain: action=sign names d= and a=');
    my $v = verify(assemble($PLAIN, $mods));
    is($v->result, 'pass', 'plain: signed output verifies') or diag($v->result_detail);
}

# --- 2. THE BUG: signed upstream + list's unsigned m=2 -> must sign i=2 ---
#
# The unsigned m=2 is the instance the milter is about to sign; §11's "is not
# signed" PERMERROR is for a RECEIVER of such a message, not for the signer
# holding it. The milter's pre-sign verify has to opt out (allow_unsigned_mi).
{
    my $signed = originator_signed();
    is(verify($signed)->result, 'pass', 'fixture: originator chain verifies');

    my $list = list_modified($signed);
    like($list, qr/^Message-Instance: m=2;/m, 'fixture: list added unsigned m=2');
    is(verify($list)->result, 'permerror',
        'fixture: on the wire, an unsigned m=2 is the §11 PERMERROR');

    my ($verdict, $mods) = run_milter(
        from => 'list-bounces@test2.dkim2.com', rcpt => ['subscriber@example.org'],
        message => $list);
    is($verdict, 'c', 'list: milter continues');
    my @sig = inserted($mods, 'DKIM2-Signature');
    is(scalar @sig, 1, 'list: DKIM2-Signature i=2 inserted over the list\'s m=2')
        or diag(milter_log());
    like($sig[0]{value}, qr/\bi=2;/, 'list: signature is i=2');
    like($sig[0]{value}, qr/\bm=2;/, 'list: signature covers m=2');
    like($sig[0]{value}, qr/\bd=test2\.dkim2\.com;/, 'list: signed by the list domain');
    is(scalar(inserted($mods, 'Message-Instance')), 0,
        'list: no new Message-Instance (the list\'s m=2 already matches)');
    unlike(milter_log(), qr/not signing.*m=2 is not signed/,
        'list: the milter did not refuse on its own unsigned m=2');

    my $v = verify(assemble($list, $mods));
    is($v->result, 'pass', 'list: full chain verifies at a receiver') or diag($v->result_detail);
    like($v->result_detail, qr/i=1\.\.2/, 'list: both signatures verified');
}

# --- 3. The opt-out must not loosen the chain gate: broken upstream -> refuse ---
{
    my $signed = originator_signed();
    # Corrupt i=1's signature bytes: still parses, no longer verifies.
    $signed =~ s/^(DKIM2-Signature:.*?s=sel1:rsa-sha256:)([A-Za-z0-9+\/]{8})/$1 . ($2 =~ tr{A-Za-z0-9}{B-ZAb-za1-90}r)/mse
        or die "could not corrupt fixture";
    my $list = list_modified($signed);

    my ($verdict, $mods) = run_milter(
        from => 'list-bounces@test2.dkim2.com', rcpt => ['subscriber@example.org'],
        message => $list);
    is($verdict, 'c', 'broken: milter continues (delivers unsigned rather than blocking)');
    is(scalar(inserted($mods, 'DKIM2-Signature')), 0,
        'broken: refuses to extend a chain whose i=1 does not verify');
    like(milter_log(), qr/not signing <post\@test1\.dkim2\.com>: upstream DKIM2 chain result=fail/,
        'broken: refusal is logged with the upstream result');
}

# --- 4. An unreadable key directory must not hang the milter ---
# A reader who gets the permissions wrong on one domain's directory gets a
# message signed with the parent domain's key (or none), never a milter that
# spins forever while Postfix times out and ships the copy unsigned.
SKIP: {
    skip 'running as root, every directory is readable', 3 if $> == 0;
    path("$dir/keys/unreadable.test2.dkim2.com")->mkpath;
    chmod 0000, "$dir/keys/unreadable.test2.dkim2.com";
    my ($verdict, $mods) = run_milter(
        from => 'list-bounces@unreadable.test2.dkim2.com', rcpt => ['subscriber@example.org'],
        message => $PLAIN);
    is($verdict, 'c', 'unreadable: milter answers');
    my @sig = inserted($mods, 'DKIM2-Signature');
    is(scalar @sig, 1, 'unreadable: signed with the parent domain key');
    like($sig[0]{value}, qr/\bd=test2\.dkim2\.com;/, 'unreadable: d= is the readable parent');
    chmod 0700, "$dir/keys/unreadable.test2.dkim2.com";
}

done_testing;
