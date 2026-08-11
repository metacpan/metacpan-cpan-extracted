package Local::DockerGuard;

use strict;
use warnings;

use Capture::Tiny qw(capture);
use Errno qw(EPERM ESRCH);

# The post-build guard names its container after the pid and epoch of the
# process that created it, so a container name carries its own provenance:
# who made it, and when.
my $NAME_PREFIX = 'dd-smart-router-two-stage';
my $NAME_RE     = qr/\A\Q$NAME_PREFIX\E-([0-9]+)-([0-9]+)\z/;

# How long a guard container may exist before it is stale no matter what its
# embedded pid says. The guard itself installs a distribution into a fresh
# container and makes a handful of HTTP requests: minutes, never an hour. The
# window exists only to backstop pid recycling, where a dead run's pid has been
# handed to an unrelated live process that would otherwise vouch for the leak
# forever.
our $DEFAULT_STALE_AFTER = 3600;

# Purpose: report whether a pid still has a process behind it, distinguishing a
#          process that is gone from one this uid merely may not signal. The
#          leaked containers this module reclaims run as root, so treating
#          "permission denied" as "gone" would be exactly backwards.
# Input:   $pid - a pid parsed out of a container name; may be undef or <= 0.
# Output:  1 when a process with that pid exists, 0 when it does not.
sub pid_alive {
    my ($pid) = @_;
    return 0 if !defined $pid;
    return 0 if $pid !~ /\A[0-9]+\z/;
    return 0 if $pid <= 0;
    return 1 if kill 0, $pid;
    return $! == EPERM ? 1 : 0;
}

# Purpose: decide which of the containers currently on the host are guard
#          containers leaked by an earlier run. A run that is SIGKILLed never
#          reaches its END block, and its container's name embeds a pid and an
#          epoch that no later run recognises as its own, so the only workable
#          rule is generational: each run collects its predecessors' leaks.
# Input:   a hash of options:
#            names       - array ref of container names as docker reports them
#            own         - the container name this run owns; never reclaimed
#            now         - epoch seconds to measure container age against
#            stale_after - seconds after which a guard container is stale
#                          regardless of its pid (defaults to $DEFAULT_STALE_AFTER)
#            pid_alive   - coderef taking a pid and returning true when it is
#                          still running (defaults to pid_alive above)
# Output:  the names to remove, in the order docker reported them. Names that
#          do not match this guard's own naming shape are never returned, so a
#          removal can only ever target a container this guard created.
sub stale_guard_containers {
    my (%args) = @_;

    my $names       = $args{names} || [];
    my $own         = $args{own};
    my $now         = $args{now};
    my $stale_after = defined $args{stale_after} ? $args{stale_after} : $DEFAULT_STALE_AFTER;
    my $alive       = $args{pid_alive} || \&pid_alive;

    die "stale_guard_containers requires a numeric now\n"
      if !defined $now || $now !~ /\A[0-9]+\z/;

    my @stale;
    for my $name ( @{$names} ) {
        next if !defined $name || $name eq q{};
        next if defined $own && $name eq $own;

        my ( $pid, $created ) = $name =~ $NAME_RE;
        next if !defined $pid;

        my $owner_gone = !$alive->($pid);
        my $aged_out   = ( $now - $created ) >= $stale_after;
        push @stale, $name if $owner_gone || $aged_out;
    }

    return @stale;
}

# Purpose: remove every guard container an earlier run leaked, and prove the
#          removal happened rather than trusting docker's exit status.
# Input:   a hash of options:
#            own         - the container name this run is about to create
#            now         - epoch seconds to measure container age against
#                          (defaults to the current time)
#            stale_after - see stale_guard_containers
#            pid_alive   - see stale_guard_containers
#            runner      - coderef taking a command and its arguments and
#                          returning ($stdout, $stderr, $exit); defaults to a
#                          Capture::Tiny wrapper around system()
# Output:  the container names actually reclaimed. Dies when the container
#          inventory cannot be read, or when a container identified as a leak is
#          still present after its removal was attempted.
sub reclaim_guard_containers {
    my (%args) = @_;

    my $runner = $args{runner} || \&_run;
    my $now    = defined $args{now} ? $args{now} : time;

    my @names = _container_names($runner);

    my @stale = stale_guard_containers(
        names       => \@names,
        own         => $args{own},
        now         => $now,
        stale_after => $args{stale_after},
        pid_alive   => $args{pid_alive},
    );
    return () if !@stale;

    # docker rm -f exits non-zero when the container had already gone, which is
    # a success for our purposes, so the exit status is recorded for the failure
    # message but the verdict comes from re-reading the inventory below.
    my %failure;
    for my $name (@stale) {
        my ( $stdout, $stderr, $exit ) = $runner->( 'docker', 'rm', '-f', $name );
        next if $exit == 0;
        $failure{$name} = _first_line( $stderr ne q{} ? $stderr : $stdout );
    }

    my %still_present = map { $_ => 1 } _container_names($runner);
    my @survivors = grep { $still_present{$_} } @stale;
    if (@survivors) {
        die sprintf "Unable to reclaim leaked guard container(s):\n%s",
          join q{}, map { sprintf "  %s: %s\n", $_, $failure{$_} || 'still present after docker rm -f' } @survivors;
    }

    return @stale;
}

# Purpose: read the host's container inventory by name only.
# Input:   $runner - the command runner described above.
# Output:  the container names as a list; dies when docker ps fails, so an
#          unreachable daemon can never be mistaken for a clean host.
sub _container_names {
    my ($runner) = @_;

    my ( $stdout, $stderr, $exit ) = $runner->( 'docker', 'ps', '-a', '--format', '{{.Names}}' );
    die sprintf "docker ps failed with exit %d: %s\n", $exit, _first_line( $stderr ne q{} ? $stderr : $stdout )
      if $exit != 0;

    return grep { $_ ne q{} } split /\n/, $stdout;
}

# Purpose: run a command, capturing its output so a reclaim sweep does not
#          scribble docker chatter across the TAP stream.
# Input:   the command and its arguments as a list.
# Output:  ($stdout, $stderr, $exit) with $exit as the shell-style exit code.
sub _run {
    my (@command) = @_;

    my ( $stdout, $stderr, $exit ) = capture {
        system(@command);
    };

    return ( $stdout, $stderr, $exit >> 8 );
}

# Purpose: reduce a captured error stream to one line for a failure message.
# Input:   $text - captured output, possibly empty or multi-line.
# Output:  the first non-empty line, or a fixed placeholder when there is none.
sub _first_line {
    my ($text) = @_;
    return 'no output' if !defined $text;
    for my $line ( split /\n/, $text ) {
        $line =~ s/\A\s+|\s+\z//g;
        return $line if $line ne q{};
    }
    return 'no output';
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Local::DockerGuard - reclaim docker containers leaked by hard-killed test runs

=head1 WHAT IT IS

A repository-only test helper, loaded from C<t/lib>, that decides which
C<dd-smart-router-two-stage-*> docker containers on the host are leaks from
earlier runs of the post-build smart-router guard, and removes them.

=head1 WHAT IT IS FOR

C<t/44-smart-router-two-stage.t> creates a long-lived container named after the
pid and epoch of the process that created it, and removes it from an C<END>
block. That teardown covers a normal exit and a trapped signal. It does not
cover C<SIGKILL>, and every automation round in this repository runs under a
C<timeout> that kills the process tree when its budget expires. Because the
container name embeds a pid and an epoch that are dead by then, no later run
recognises the container as something it may remove, so the leak is permanent.
This helper makes the cleanup generational instead: each run collects its
predecessors' leaks before creating its own container.

=head1 PURPOSE

Keep the post-build guard's docker footprint bounded by exactly one container,
however violently the run that created it was terminated, by moving the cleanup
decision from teardown time — which a killed run never reaches — to the start of
the next run, where a live process can still make it.

=head1 WHY IT EXISTS

DD-448 found eight leaked containers on the build host, the oldest three weeks
old. Each one holds a bound loopback port and a full dashboard process tree
whose in-container processes are root-owned, which puts them out of reach of
the documented host-side stray-collector cleanup. Left alone they accumulate at
roughly one every two to three days, and a growing set of long-lived loopback
port holders is what turns the guard's free-port search into an intermittent
failure that gets misread as flakiness.

Better teardown cannot fix this: C<SIGKILL> cannot be trapped, and the
container is long-lived and exec'd into, so C<docker run --rm> does not apply.
Reclaim-on-next-start is the only shape that works, which makes the staleness
decision the part worth isolating and testing — reclaiming too eagerly would
destroy a concurrent run's container, and reclaiming too timidly leaves the
leak in place.

=head1 WHEN TO USE

Use it from any repository test that creates a long-lived, uniquely named
docker container it cannot guarantee it will live long enough to remove.

Containers are judged stale when the pid embedded in their name no longer
resolves to a running process, or when they are older than C<stale_after>
seconds. The age window exists purely to backstop pid recycling, where a dead
run's pid has been reissued to an unrelated live process. Names that do not
match the guard's own C<< <prefix>-<pid>-<epoch> >> shape are never touched, so
a sweep can only ever remove a container this guard created.

=head1 HOW TO USE

Call C<reclaim_guard_containers> before creating the container, passing the
name this run is about to use so it is never swept. The default command runner
shells out to C<docker> through C<Capture::Tiny>; pass C<runner> and
C<pid_alive> to drive the decision from a test without a docker daemon.

=head1 WHAT USES IT

C<t/44-smart-router-two-stage.t> calls it before creating its container, and
C<t/141-smart-router-guard-container-reclaim.t> pins its decision rules.

=head1 EXAMPLES

Example 1 — reclaim before creating this run's container:

  use lib 't/lib';
  use Local::DockerGuard;

  my $container = sprintf 'dd-smart-router-two-stage-%d-%d', $$, time;
  Local::DockerGuard::reclaim_guard_containers( own => $container );

Example 2 — decide staleness without touching docker:

  my @stale = Local::DockerGuard::stale_guard_containers(
      names       => [ 'dd-smart-router-two-stage-111-1785000000' ],
      own         => $container,
      now         => time,
      stale_after => 3600,
      pid_alive   => sub { 0 },
  );

Example 3 — drive a whole sweep through an injected runner:

  my @removed = Local::DockerGuard::reclaim_guard_containers(
      own       => $container,
      pid_alive => sub { 0 },
      runner    => sub {
          my (@argv) = @_;
          return ( "dd-smart-router-two-stage-111-1785000000\n", q{}, 0 ) if $argv[1] eq 'ps';
          return ( q{}, q{}, 0 );
      },
  );

=head1 SEE ALSO

L<Capture::Tiny>

=cut
