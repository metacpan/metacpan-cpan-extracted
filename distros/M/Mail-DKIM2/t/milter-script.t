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

my $dir = tempdir(CLEANUP => 1);
my $log  = "$dir/milter.log";
path("$dir/keys/test2.dkim2.com")->mkpath;
$KEYS->child('sel1._domainkey.test2.dkim2.com.pem')->copy("$dir/keys/test2.dkim2.com/sel1.key");
# test3.dkim2.com: a forwarder further down the chain (case 5b).
path("$dir/keys/test3.dkim2.com")->mkpath;
$KEYS->child('sel1._domainkey.test3.dkim2.com.pem')->copy("$dir/keys/test3.dkim2.com/sel1.key");
path("$dir/snap")->mkpath;

my @pids;
END { local $?; for my $p (@pids) { kill "TERM", $p; waitpid($p, 0) } }

# Start a milter on its own socket; extra => [...] adds command-line options,
# perl => [...] options for perl itself (e.g. -M to load a test fault).
sub spawn_milter {
    my (%o) = @_;
    my $n    = @pids;
    my $sock = $n ? "$dir/out$n.sock" : "$dir/out.sock";
    my $pid  = fork();
    die "fork: $!" unless defined $pid;
    if ($pid == 0) {
        open STDERR, '>>', $log or die $!;
        open STDOUT, '>>', $log or die $!;
        exec $^X, "-I$LIB", @{ $o{perl} || [] }, $SCRIPT,
            '--mode', 'outbound',
            '--socket', "unix:$sock",
            '--keydir', "$dir/keys",
            '--dns-json', "$DNS_JSON",
            '--snapshot-dir', "$dir/snap",
            @{ $o{extra} || [] }
            or die "exec: $!";
    }
    push @pids, $pid;
    for (1 .. 50) { last if -S $sock; select(undef, undef, undef, 0.2); }
    return ($pid, $sock);
}

my ($pid, $sock) = spawn_milter();
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
    my $peer = $a{sock} // $sock;
    my $s = IO::Socket::UNIX->new(Peer => $peer, Type => SOCK_STREAM)
        or die "connect $peer: $!";
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

# --- 5. A list's unsigned m=2 with a null body Recipe ---
#
# Built like the case in 2, but the list rewrote the body and said so ("b":
# null). Signing that is the host's choice: --allow-null-body-recipe, off by
# default. Either way the header history below the null is still checked.
sub null_list_post {
    my (%o) = @_;
    my $signed = originator_signed();
    my $mod = $signed;
    $mod =~ s/^Subject: /Subject: [list] /m;
    $mod =~ s/^To: .*$/To: tampered\@example.net/m if $o{forge};
    $mod .= "--$EOL" . "rewritten$EOL";
    my $mi = Mail::DKIM2::MessageInstance->calculate(
        Email::MIME->new($mod), Email::MIME->new($signed));
    $mi->set_null_body_recipe;
    if ($o{forge}) {
        # hide the To change from the header Recipe
        my $rh = $mi->{bits}{rh};
        delete $rh->{$_} for grep { lc($_) eq 'to' } keys %$rh;
    }
    return "Message-Instance: " . $mi->as_string . $EOL . $mod;
}

sub info_values {
    my ($mods) = @_;
    return map { $_->{value} } inserted($mods, 'X-DKIM2-Info');
}

{
    my ($verdict, $mods) = run_milter(
        from => 'list-bounces@test2.dkim2.com', rcpt => ['subscriber@example.org'],
        message => null_list_post());
    is($verdict, 'c', 'null body: milter continues');
    is(scalar(inserted($mods, 'DKIM2-Signature')), 0, 'option off: null body Recipe not signed');
    like(join("\n", info_values($mods)), qr/not-signed=null-body-recipe/,
        'option off: X-DKIM2-Info records not-signed=null-body-recipe');
    like(milter_log(), qr/not signing <post\@test1\.dkim2\.com>: unsigned top Message-Instance m=2 has a null body Recipe/,
        'option off: the log says the null top is unsigned');
}

# --- 5b. The same null m=2, but the list domain signed it (i=2, m=2) ---
# A forwarder (test3) relays the list post unchanged. The null was declared
# and signed upstream, so the default milter (option off) extends the chain,
# and X-DKIM2-Info still notes the null top it signed over.
{
    my $post = null_list_post();
    my $s = Mail::DKIM2::Signer->new(
        Domain => 'test2.dkim2.com', Selector => 'sel1',
        Key => DKIM2TestKeys::private_key('test2.dkim2.com', 'sel1'),
        MailFrom => 'list-bounces@test2.dkim2.com', RcptTo => ['subscriber@test3.dkim2.com'],
        Timestamp => time());
    $s->PRINT($post); $s->CLOSE;
    my $signed_post = $s->as_string . $EOL . $post;

    my ($verdict, $mods) = run_milter(
        from => 'fwd@test3.dkim2.com', rcpt => ['user@example.org'],
        message => $signed_post);
    is($verdict, 'c', 'signed null top: milter continues');
    my @sig = inserted($mods, 'DKIM2-Signature');
    is(scalar @sig, 1, 'signed null top: signed with the option off') or diag(milter_log());
    like($sig[0]{value} // '', qr/\bi=3;.*\bm=2;/s, 'signed null top: i=3 over the list\'s m=2');
    like($sig[0]{value} // '', qr/\bd=test3\.dkim2\.com;/, 'signed null top: by the forwarder');
    like(join("\n", info_values($mods)), qr/action=null-body-recipe/,
        'signed null top: X-DKIM2-Info notes the null top (informational)');
    unlike(join("\n", info_values($mods)), qr/not-signed=/,
        'signed null top: no not-signed= tag');
    my $v = verify(assemble($signed_post, $mods));
    is($v->result, 'pass', 'signed null top: full chain verifies at a receiver')
        or diag($v->result_detail);
}

{
    my ($pid2, $sock2) = spawn_milter(extra => ['--allow-null-body-recipe']);
    ok(-S $sock2, 'option-on milter is listening') or BAIL_OUT("milter never came up");
    my ($verdict, $mods) = run_milter(sock => $sock2,
        from => 'list-bounces@test2.dkim2.com', rcpt => ['subscriber@example.org'],
        message => null_list_post());
    is(scalar(inserted($mods, 'DKIM2-Signature')), 1, 'option on: signed') or diag(milter_log());
    like(join("\n", info_values($mods)), qr/action=null-body-recipe/,
        'option on: X-DKIM2-Info records null-body-recipe');

    # The list also changed To, and its header Recipe hides that: refused
    # even with the option on, by the header-history walk.
    ($verdict, $mods) = run_milter(sock => $sock2,
        from => 'list-bounces@test2.dkim2.com', rcpt => ['subscriber@example.org'],
        message => null_list_post(forge => 1));
    is(scalar(inserted($mods, 'DKIM2-Signature')), 0,
        'option on: forged header history not signed');
}

# --- 5. nd= bridge: sign when the top nd= names our d=, refuse otherwise ---
{
    my $nd_signed = sub {
        my ($nd) = @_;
        my $mi  = Mail::DKIM2::MessageInstance->calculate(Email::MIME->new($PLAIN));
        my $msg = "Message-Instance: " . $mi->as_string . $EOL . $PLAIN;
        my $signer = Mail::DKIM2::Signer->new(
            Domain => 'test1.dkim2.com', Selector => 'sel1',
            Key => DKIM2TestKeys::private_key('test1.dkim2.com', 'sel1'),
            NextDomain => $nd, Timestamp => time());
        $signer->PRINT($msg); $signer->CLOSE;
        return $signer->as_string . $EOL . $msg;
    };
    my ($verdict, $mods) = run_milter(
        from => 'list-bounces@test2.dkim2.com', rcpt => ['subscriber@example.org'],
        message => $nd_signed->('test2.dkim2.com'));
    my @sig = inserted($mods, 'DKIM2-Signature');
    is(scalar @sig, 1, 'nd=us: signed') or diag(milter_log());
    like($sig[0]{value}, qr/\bi=2;/, 'nd=us: signature is i=2') if @sig;

    ($verdict, $mods) = run_milter(
        from => 'list-bounces@test2.dkim2.com', rcpt => ['subscriber@example.org'],
        message => $nd_signed->('test3.dkim2.com'));
    is(scalar(inserted($mods, 'DKIM2-Signature')), 0, 'nd=other: not signed');
    like(milter_log(), qr/not signing .*top signature nd=test3\.dkim2\.com names another domain/,
        'nd=other: refusal is logged');
}

# --- 6. Malformed Content-Type: parsed quietly, same decision ---
{
    for my $ct ('text/plain; charset=Windows-1252;', 'text/plain; Windows-1252') {
        (my $m = $PLAIN) =~ s/^Content-Type: text\/plain(?=\r)/Content-Type: $ct/m;
        my $before = length milter_log();
        my ($verdict, $mods) = run_milter(
            from => 'list-bounces@test2.dkim2.com', rcpt => ['subscriber@example.org'],
            message => $m);
        is(scalar(inserted($mods, 'DKIM2-Signature')), 1, "Content-Type '$ct': signed");
        my $new = substr(milter_log(), $before);
        unlike($new, qr/Extra semicolon|Illegal parameter/, "Content-Type '$ct': no Email::MIME warning in log");
    }
}

# --- 7. An out-of-range i= upstream: refused, and the milter survives ---
# i=99999999999999999999 used to kill the Verifier ("Range iterator outside
# integer range") inside cb_eom, and with it the callback. Every i= and m= is
# bounded by MAX_CHAIN_LENGTH now, so it is an ordinary PERMERROR refusal.
{
    my $msg = "DKIM2-Signature: i=99999999999999999999; m=1; d=evil.example$EOL"
            . originator_signed();
    my ($verdict, $mods) = eval { run_milter(
        from => 'list-bounces@test2.dkim2.com', rcpt => ['subscriber@example.org'],
        message => $msg) };
    is($@, '', 'huge i=: the milter answers');
    is($verdict, 'c', 'huge i=: milter continues');
    is(scalar(inserted($mods || [], 'DKIM2-Signature')), 0, 'huge i=: not signed');
    like(milter_log(), qr/not signing <post\@test1\.dkim2\.com>: .*exceeds the maximum chain number of 100/,
        'huge i=: refusal is logged with the reason');
}

# --- 8. An exception in the gate or the verifier fails closed ---
# A die inside the verify/sign path must not kill the callback: the milter
# logs a refusal and does not sign. Faults are injected with a -M module.
{
    path("$dir/inject")->mkpath;
    path("$dir/inject/DKIM2TestDieGate.pm")->spew(
        "package DKIM2TestDieGate; require Mail::DKIM2::Gate;\n"
      . "no warnings 'redefine';\n"
      . "*Mail::DKIM2::Gate::check = sub { die \"injected gate fault\\n\" };\n1;\n");
    path("$dir/inject/DKIM2TestDieVerifier.pm")->spew(
        "package DKIM2TestDieVerifier; require Mail::DKIM2::Verifier;\n"
      . "no warnings 'redefine';\n"
      . "*Mail::DKIM2::Verifier::CLOSE = sub { die \"injected verifier fault\\n\" };\n1;\n");

    my (undef, $sock_g) = spawn_milter(perl => ["-I$dir/inject", '-MDKIM2TestDieGate']);
    my ($verdict, $mods) = eval { run_milter(sock => $sock_g,
        from => 'list-bounces@test2.dkim2.com', rcpt => ['subscriber@example.org'],
        message => list_modified(originator_signed())) };
    is($@, '', 'gate fault: the milter answers');
    is($verdict, 'c', 'gate fault: milter continues');
    is(scalar(inserted($mods || [], 'DKIM2-Signature')), 0, 'gate fault: not signed');
    like(milter_log(), qr/not signing <post\@test1\.dkim2\.com>: .*injected gate fault/,
        'gate fault: refusal is logged');

    my (undef, $sock_v) = spawn_milter(perl => ["-I$dir/inject", '-MDKIM2TestDieVerifier'],
                                      extra => ['--mode', 'inbound']);
    ($verdict, $mods) = eval { run_milter(sock => $sock_v,
        from => 'author@test1.dkim2.com', rcpt => ['list@test2.dkim2.com'],
        message => originator_signed()) };
    is($@, '', 'verifier fault: the milter answers');
    is($verdict, 'c', 'verifier fault: milter continues');
    my ($ar) = inserted($mods || [], 'Authentication-Results');
    like($ar ? $ar->{value} : '', qr/dkim2=temperror/, 'verifier fault: A-R says temperror, not pass');
    like(milter_log(), qr/verify .*injected verifier fault/, 'verifier fault: logged');
}

# --- 9. An out-of-range Message-Instance m= at the inbound MI step ---
# Inbound, the milter computes a Message-Instance against its stored
# snapshot, and used to strip the instances above the snapshot's top as the
# range snap_max_v+1 .. max_v: m=99999999999999999999 died ("Range iterator
# outside integer range") and m=4294967297 built a four-billion-element list.
# Now the m= is bounded first: no Message-Instance is added, the message
# passes with its Authentication-Results, and the milter keeps answering.
# A fault inside the MI computation fails closed the same way (inbound: no
# MI; outbound: not signed).
{
    my (undef, $sock_in) = spawn_milter(extra => ['--mode', 'inbound']);
    ok(-S $sock_in, 'inbound milter is listening') or BAIL_OUT("milter never came up");
    my $n = 0;
    my $base = sub {
        my ($id) = @_;
        (my $m = $PLAIN) =~ s/^Message-Id: <post\@/Message-Id: <$id\@/m;
        return $m;
    };
    for my $big ('99999999999999999999', '4294967297', '33') {
        my $id = 'bigm' . $n++;
        my ($verdict, $mods) = run_milter(sock => $sock_in,
            from => 'author@test1.dkim2.com', rcpt => ['list@test2.dkim2.com'],
            message => $base->($id));
        my ($mi1) = inserted($mods, 'Message-Instance');
        ok($mi1, "m=$big: first pass adds m=1 and stores a snapshot") or next;
        my $first = assemble($base->($id), $mods);
        # Only the headers the snapshot was taken over: drop the second info line.
        (my $v1 = $mi1->{value}) =~ s/\r?\n/$EOL/g;
        my ($ar)   = inserted($mods, 'Authentication-Results');
        my @info   = inserted($mods, 'X-DKIM2-Info');
        (my $i0 = $info[0]{value}) =~ s/\r?\n/$EOL/g;
        my $msg2 = "Message-Instance: m=$big; h=sha256:AAAA:AAAA$EOL"
                 . "Message-Instance: $v1$EOL"
                 . "X-DKIM2-Info: $i0$EOL"
                 . "Authentication-Results: $ar->{value}$EOL"
                 . $base->($id);
        $msg2 =~ s/Here's a test user!/a changed body/;
        my $before = length milter_log();
        my $t0 = time;
        ($verdict, $mods) = eval { run_milter(sock => $sock_in,
            from => 'author@test1.dkim2.com', rcpt => ['list@test2.dkim2.com'],
            message => $msg2) };
        is($@, '', "m=$big: the milter answers");
        is($verdict, 'c', "m=$big: milter continues");
        ok(time - $t0 < 15, "m=$big: promptly");
        is(scalar(inserted($mods || [], 'Message-Instance')), 0, "m=$big: no Message-Instance added");
        my $new = substr(milter_log(), $before);
        unlike($new, qr/stripping broken MI/, "m=$big: m= never used as a range");
        unlike($new, qr/Range iterator|Out of memory/, "m=$big: no exception");
        is(scalar(inserted($mods || [], 'Authentication-Results')), 1,
            "m=$big: the message passes with its Authentication-Results");
    }

    path("$dir/inject/DKIM2TestDieMI.pm")->spew(
        "package DKIM2TestDieMI; require Mail::DKIM2::MessageInstance;\n"
      . "no warnings 'redefine';\n"
      . "*Mail::DKIM2::MessageInstance::calculate = sub { die \"injected MI fault\\n\" };\n1;\n");
    for my $mode ('inbound', 'outbound') {
        my (undef, $sock_m) = spawn_milter(perl => ["-I$dir/inject", '-MDKIM2TestDieMI'],
                                          extra => ['--mode', $mode]);
        my ($verdict, $mods) = eval { run_milter(sock => $sock_m,
            from => 'list-bounces@test2.dkim2.com', rcpt => ['subscriber@example.org'],
            message => $PLAIN) };
        is($@, '', "MI fault ($mode): the milter answers");
        is($verdict, 'c', "MI fault ($mode): milter continues");
        is(scalar(inserted($mods || [], 'Message-Instance')), 0, "MI fault ($mode): no Message-Instance");
        is(scalar(inserted($mods || [], 'DKIM2-Signature')), 0, "MI fault ($mode): not signed");
        like(milter_log(), $mode eq 'inbound'
                ? qr/dkim2-milter: no Message-Instance for <post\@test1\.dkim2\.com>: internal error: injected MI fault/
                : qr/dkim2-milter: not signing <post\@test1\.dkim2\.com>: internal error computing the Message-Instance: injected MI fault/,
            "MI fault ($mode): logged as a refusal");
    }
}

done_testing;
