package TestHelper;
use strict;
use warnings;
use EV;
use EV::Pg;
use Test::More;
use Exporter 'import';
use POSIX ':sys_wait_h';

our @EXPORT = qw(with_pg require_pg $conninfo);
our @EXPORT_OK = qw(run_isolated);
our $conninfo = $ENV{TEST_PG_CONNINFO};

sub require_pg {
    plan skip_all => "set TEST_PG_CONNINFO to run" unless $conninfo;
    my $ok = 0;
    my $pg = EV::Pg->new(
        conninfo   => $conninfo,
        on_connect => sub { $ok = 1; EV::break },
        on_error   => sub { EV::break },
    );
    my $t = EV::timer(3, 0, sub { EV::break });
    EV::run;
    $pg->finish if $pg->is_connected;
    plan skip_all => "PostgreSQL not reachable at '$conninfo'"
        unless $ok;
}

sub with_pg {
    my (%opts) = @_;
    my $cb      = delete $opts{cb};
    my $timeout = delete $opts{timeout} || 5;
    my $pg;
    $pg = EV::Pg->new(
        conninfo   => $conninfo,
        on_connect => sub { $cb->($pg) },
        on_error   => sub { diag("Error: $_[0]"); EV::break },
        %opts,
    );
    EV::now_update;
    my $t = EV::timer($timeout, 0, sub { diag("TIMEOUT after ${timeout}s"); EV::break });
    EV::run;
    $pg->finish if $pg && $pg->is_connected;
}

sub run_isolated {
    my ($code, $timeout) = @_;
    pipe(my $rd, my $wr) or die "pipe: $!";
    my $pid = fork();
    die "fork: $!" unless defined $pid;
    if ($pid == 0) {
        close $rd;
        EV::now_update;
        my $rc = eval { $code->($wr); 0 };
        if (!defined $rc) { warn "child error: $@"; $rc = 3; }
        close $wr;
        POSIX::_exit($rc);
    }
    close $wr;
    my $deadline = time + $timeout;
    my $status;
    while (1) {
        my $kid = waitpid($pid, WNOHANG);
        if ($kid == $pid) { $status = $?; last; }
        if (time >= $deadline) {
            kill 'KILL', $pid;
            waitpid($pid, 0);
            close $rd;
            return ('timeout', '');
        }
        select(undef, undef, undef, 0.05);
    }
    my $out;
    {
        local $/;
        $out = <$rd>;
    }
    close $rd;
    $out = '' unless defined $out;
    chomp $out;
    if (my $sig = $status & 127) { return ("signal:$sig", $out) }
    my $exit = $status >> 8;
    return ($exit == 0 ? 'ok' : "exit:$exit", $out);
}

1;
