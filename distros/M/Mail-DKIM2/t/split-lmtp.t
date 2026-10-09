#!/usr/bin/perl -w
use 5.020; use strict; use warnings;
use Test::More;
use IO::Socket::INET;
use File::Temp qw(tempdir);
use POSIX ':sys_wait_h';

# Integration test for bin/dkim2-split-lmtp: drive the real LMTP daemon,
# point its re-injection at a capture sink, and confirm it fans a message with
# a Bcc into per-copy re-injections (disclosed grouped, Bcc alone) and answers
# one LMTP status per recipient. Network test -> SKIP cleanly if it can't set up.

my $CAP_PORT  = 12611;   # capture sink (stands in for the signing listener)
my $LMTP_PORT = 12610;   # the split daemon
my $dir = tempdir(CLEANUP => 1);
my (@pids);

# Never hang or orphan the daemons: a dead test (SIGPIPE, SIGALRM, SIGTERM)
# must still run END and reap them, or the survivors hold prove's output pipe.
$SIG{PIPE} = 'IGNORE';
$SIG{ALRM} = $SIG{TERM} = $SIG{INT} = sub { die "split-lmtp.t: aborted by signal @_\n" };
alarm 60;

sub cleanup { alarm 0; kill 'TERM', @pids; waitpid($_, 0) for @pids; $? = 0; }
END { cleanup(); $? = 0 }   # don't let a reaped child's signal status leak into our exit code

# --- capture sink: one file per injected copy, recording its RCPTs ----------
my $sink = fork;
if (defined $sink && $sink == 0) {
    $SIG{$_} = 'DEFAULT' for qw(TERM INT ALRM); alarm 0;
    my $s = IO::Socket::INET->new(LocalAddr=>'127.0.0.1', LocalPort=>$CAP_PORT,
        Listen=>10, ReuseAddr=>1) or exit 1;
    $SIG{CHLD} = sub { while (waitpid(-1, WNOHANG) > 0) {} };
    while (my $c = $s->accept) {
        my $p = fork;
        if (defined $p && $p == 0) {
            $c->autoflush(1); print $c "220 sink\r\n";
            my ($from, @r, $in) = ('', (), 0);
            while (my $l = <$c>) {
                if ($in) { if ($l eq ".\r\n") { print $c "250 ok\r\n"; last } next }
                if    ($l =~ /^(EHLO|HELO|LHLO)/i) { print $c "250 sink\r\n" }
                elsif ($l =~ /^MAIL FROM:\s*(\S+)/i) { $from = $1; print $c "250 ok\r\n" }
                elsif ($l =~ /^RCPT TO:\s*(\S+)/i)   { push @r, $1; print $c "250 ok\r\n" }
                elsif ($l =~ /^DATA/i) { print $c "354 go\r\n"; $in = 1 }
                elsif ($l =~ /^QUIT/i) { print $c "221 b\r\n"; last }
                else  { print $c "250 ok\r\n" }
            }
            open my $f, '>', "$dir/copy.$$" or exit 0;
            print $f "FROM=$from RCPT=@r\n"; close $f;
            close $c; exit 0;
        }
        $c->close;
    }
    exit 0;
}
push @pids, $sink if $sink;

# --- the split daemon, re-injecting to the capture sink ---------------------
my $daemon = fork;
if (defined $daemon && $daemon == 0) {
    $SIG{PIPE} = 'DEFAULT'; $SIG{$_} = 'DEFAULT' for qw(TERM INT ALRM); alarm 0;   # as in production
    $ENV{DKIM2_SPLIT_HOST}  = '127.0.0.1'; $ENV{DKIM2_SPLIT_PORT}  = $LMTP_PORT;
    $ENV{DKIM2_INJECT_HOST} = '127.0.0.1'; $ENV{DKIM2_INJECT_PORT} = $CAP_PORT;
    exec($^X, '-Ilib', 'bin/dkim2-split-lmtp');
    exit 1;
}
push @pids, $daemon if $daemon;

# --- act as the LMTP client -------------------------------------------------
my $cli;
# On macOS/BSD, IO::Socket::INET's Timeout (non-blocking connect) can hand back
# an object for a refused connection if the daemon is not listening yet, so
# insist on a real peer before believing it.
for (1..50) {
    $cli = IO::Socket::INET->new(PeerAddr=>'127.0.0.1', PeerPort=>$LMTP_PORT, Timeout=>2);
    last if $cli && $cli->connected && defined $cli->peerport;
    undef $cli; select undef,undef,undef,0.2;
}
unless ($cli) { plan skip_all => "could not start/connect to split daemon"; }
$cli->autoflush(1);
sub expect { my ($re,$what)=@_; my $l=<$cli>; ok(defined $l && $l=~$re, "$what: ".($l//'(eof)')); }

expect(qr/^220 /, 'greeting');
print $cli "LHLO test\r\n";           expect(qr/^250 /, 'LHLO');
print $cli "MAIL FROM:<s\@ex.com>\r\n"; expect(qr/^250 /, 'MAIL FROM');
# alice + bob are in To:; eve is Bcc (envelope only)
print $cli "RCPT TO:<alice\@a.com>\r\n"; expect(qr/^250 /, 'RCPT alice');
print $cli "RCPT TO:<bob\@b.com>\r\n";   expect(qr/^250 /, 'RCPT bob');
print $cli "RCPT TO:<eve\@e.com>\r\n";   expect(qr/^250 /, 'RCPT eve (Bcc)');
print $cli "DATA\r\n";                   expect(qr/^354 /, 'DATA');
print $cli "From: s\@ex.com\r\nTo: Alice <alice\@a.com>, bob\@b.com\r\nSubject: hi\r\n\r\nbody\r\n.\r\n";
# LMTP: one reply per recipient, in order
expect(qr/^250 /, 'per-recipient reply 1 (alice)');
expect(qr/^250 /, 'per-recipient reply 2 (bob)');
expect(qr/^250 /, 'per-recipient reply 3 (eve)');
print $cli "QUIT\r\n"; close $cli;

# --- verify the injected copies: disclosed grouped, Bcc alone, no leak ------
my @copies;
for (1..30) { @copies = glob("$dir/copy.*"); last if @copies >= 2; select undef,undef,undef,0.2; }
my @sets = map { my $c = do { local $/; open my $f,'<',$_; <$f> }; $c } @copies;
is(scalar(@sets), 2, 'exactly two copies injected (disclosed group + Bcc)');
my ($disc) = grep { /alice\@a\.com/ && /bob\@b\.com/ } @sets;
my ($bcc)  = grep { /eve\@e\.com/ } @sets;
ok($disc, 'one copy carries both disclosed recipients (alice+bob)');
ok($bcc && $bcc !~ /alice|bob/, 'the Bcc copy carries ONLY eve (no leak)');
ok(!($disc && $disc =~ /eve/), 'the disclosed copy does NOT carry the Bcc address (no leak)');

done_testing;
