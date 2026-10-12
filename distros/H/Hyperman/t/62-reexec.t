#!perl
use strict;
use warnings;
use lib "t/lib";
use Test::More;
use HMTest qw(free_ports quiet_child);
use IO::Socket::INET;
use Time::HiRes ();
use File::Temp ();

# USR2 re-execs the supervisor: a fresh perl compiles the application again,
# adopts the bound listener and the named arena, forks its pool, and only then
# asks the old supervisor to drain. No connection is refused across the
# handoff; a successor that dies before taking over changes nothing.

plan skip_all => 'the re-exec needs fork(2) and exec; Windows runs a single worker'
    if $^O eq 'MSWin32';
my ($port) = free_ports(1);
plan skip_all => "no free loopback port" unless $port;

my $dir     = File::Temp::tempdir(CLEANUP => 1);
my $err     = "$dir/stderr.log";
my $pidfile = "$dir/server.pid";
my $script  = "$dir/server.pl";
my $arena   = "hmrx$$";                     # within the 31-byte macOS limit

sub set_version { open my $f, '>', "$dir/version" or die $!; print $f "$_[0]\n"; close $f }
sub write_script {
    my ($die) = @_;
    open my $f, '>', $script or die $!;
    print $f "die \"boom\\n\";\n" if $die;
    print $f <<"PL";
use strict; use warnings;
use Hyperman;
my \$v = do { open my \$fh, '<', '$dir/version' or die \$!; local \$/; <\$fh> };
chomp \$v;
Hyperman->run(
    app => sub {
        my \$env = shift;
        if (\$env->{PATH_INFO} eq '/arena') {
            my \$a = Hyperman->arena;
            return [ 200, [], [ \$a ? (\$a->created ? 'created' : 'attached') : 'none' ] ];
        }
        [ 200, [], [ "v=\$v pid=\$\$" ] ];
    },
    host => '127.0.0.1', port => $port, workers => 2,
    arena_name => '$arena', pid_file => '$pidfile', shutdown_grace => 2,
);
PL
    close $f;
}
set_version(1);
write_script(0);

my $first = fork // die "fork: $!";
if (!$first) {
    quiet_child(stderr => $err);
    exec $^X, (map { "-I$_" } @INC), $script or die "exec: $!";
}

sub get {
    my ($path) = @_;
    my $s = IO::Socket::INET->new(PeerAddr => '127.0.0.1', PeerPort => $port,
                                  Proto => 'tcp', Timeout => 2) or return undef;
    $s->syswrite("GET $path HTTP/1.0\r\n\r\n");
    my $buf = '';
    eval { local $SIG{ALRM} = sub { die "timeout\n" }; alarm 5;
           while (my $n = $s->sysread(my $c, 4096)) { $buf .= $c } alarm 0 };
    close $s;
    return $buf =~ /\r\n\r\n(.*)\z/s ? $1 : undef;
}
sub pidfile { open my $f, '<', $pidfile or return undef; my $p = <$f>; chomp $p if defined $p; return $p }
sub wait_for { my ($cond, $secs) = @_; my $t = Time::HiRes::time() + $secs; while (Time::HiRes::time() < $t) { return 1 if $cond->(); Time::HiRes::sleep(0.1) } return 0 }
sub stderr_log { open my $f, '<', $err or return ''; local $/; return scalar <$f> // '' }

ok wait_for(sub { (get('/') // '') =~ /^v=1/ }, 15), 'the first generation serves v=1';
is pidfile(), $first, 'the pid file holds the first supervisor';
is get('/arena'), 'created', 'the first supervisor created the arena';

# ---- USR2: a new version takes over with no refused connection ------------
set_version(2);
kill 'USR2', $first or die "kill: $!";
my ($lost, $seen2) = (0, 0);
my $took = wait_for(sub {
    my $b = get('/');
    if (!defined $b) { $lost++; return 0 }
    $seen2 = 1 if $b =~ /^v=2/;
    return $seen2 && (pidfile() // '') ne $first;
}, 30);
ok $took, 'a successor serves v=2 and the pid file names it';
is $lost, 0, 'no request failed across the handoff';
my $second = pidfile();
isnt $second, $first, 'the supervisor pid changed';
waitpid $first, 0;
is $? >> 8, 0, 'the first supervisor drained and exited cleanly';
# Only now: until the old supervisor has drained, its workers still accept
# on the shared listen socket and would answer 'created' (seen on Linux).
is get('/arena'), 'attached', 'the successor attached the same arena by name';
ok wait_for(sub { (get('/') // '') =~ /^v=2/ }, 5), 'v=2 still serving after the old pool went';
like stderr_log(), qr/successor \d+ started/, 'the old supervisor logged the successor';
like stderr_log(), qr/sockets adopted from supervisor $first/, 'the successor logged the adoption';

# ---- again, from a supervisor that is not our child -----------------------
set_version(3);
kill 'USR2', $second or die "kill: $!";
ok wait_for(sub { (get('/') // '') =~ /^v=3/ && (pidfile() // '') ne $second }, 30),
    'a second USR2 hands over again';
my $third = pidfile();
ok wait_for(sub { !kill(0, $second) }, 15), 'the second supervisor is gone';

# ---- a successor that dies before taking over changes nothing -------------
write_script(1);
kill 'USR2', $third or die "kill: $!";
ok wait_for(sub { stderr_log() =~ /before taking over; still serving/ }, 15),
    'the failed successor was reported';
is pidfile(), $third, 'the pid file still names the serving supervisor';
like get('/') // '', qr/^v=3/, '...and it still serves v=3';

kill 'TERM', $third;
ok wait_for(sub { !kill(0, $third) }, 15), 'TERM takes the last supervisor down';
ok !-e $pidfile, 'and its pid file is gone';
done_testing;
