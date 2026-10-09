use strict;
use warnings;
use Test::More;
use Test::RedisServer;
use POSIX ();

my $redis_server;
eval {
    $redis_server = Test::RedisServer->new;
} or plan skip_all => 'redis-server is required to this test';

my %connect_info = $redis_server->connect_info;

use EV;
use EV::Redis;

$SIG{PIPE} = 'IGNORE';

sub run_for {
    my ($secs) = @_;
    EV::now_update;
    my $g = EV::timer $secs, 0, sub { EV::break };
    EV::run;
}

# A crash in the child must fail the test, not the harness: each destructive
# case runs in a fork whose raw exit status must be zero.
sub child_runs {
    my ($name, $code) = @_;
    my $pid = fork;
    die "fork: $!" unless defined $pid;
    if (0 == $pid) {
        eval { $code->(); 1 } or POSIX::_exit(2);
        POSIX::_exit(0);
    }
    waitpid $pid, 0;
    is $?, 0, $name;
}

sub connected {
    my $r = EV::Redis->new(path => $connect_info{sock}, on_error => sub {});
    my $pong;
    $r->ping(sub { $pong = $_[0] });
    run_for(1);
    die 'no connection' unless defined $pong && $pong eq 'PONG';
    return $r;
}

child_runs 'undef arg with a hook dropping the last reference', sub {
    my $r = connected();
    local $SIG{__WARN__} = sub { $r = undef };
    $r->command('ping', undef, sub {});
    run_for(0.5);
};

child_runs 'non-coderef handler with a hook dropping the last reference', sub {
    my $r = connected();
    local $SIG{__WARN__} = sub { $r = undef };
    $r->on_error('not a coderef');
};

our $Victim;

{
    package DestroyingFetch;
    sub TIESCALAR { bless { value => $_[1] } }
    sub FETCH { $main::Victim = undef; $_[0]->{value} }
    sub STORE { $_[0]->{value} = $_[1] }
}

child_runs 'tied hostname destroying the object in FETCH', sub {
    $Victim = EV::Redis->new(on_error => sub {});
    tie my $host, 'DestroyingFetch', '127.0.0.1';
    $Victim->connect($host, 6379);
    run_for(0.5);
};

child_runs 'tied setter value destroying the object in FETCH', sub {
    tie my $timeout, 'DestroyingFetch', 5000;
    my $prime = $timeout;
    $Victim = connected();
    $Victim->waiting_timeout($timeout);
};

{
    my $r = connected();
    my @logged;
    local $SIG{__WARN__} = sub { push @logged, @_ };
    my ($res, $err);
    $r->command('ping', undef, sub { ($res, $err) = @_; });
    run_for(1);
    ok scalar(@logged), 'the undef-arg warning still reaches the hook';
    is $err, undef, '... and the command still runs';
    is $res, '', 'ping with an empty arg answers it';
    $r->disconnect;
}

{
    my $r = connected();
    local $SIG{__WARN__} = sub { die "fatal: $_[0]" };
    eval { $r->command('ping', undef, sub {}) };
    like $@, qr/^fatal:/, 'a dying hook unwinds through command()';
    my $pong;
    $r->ping(sub { $pong = $_[0]; EV::break });
    run_for(1);
    is $pong, 'PONG', 'the object survives it';
    $r->disconnect;
}

done_testing;
