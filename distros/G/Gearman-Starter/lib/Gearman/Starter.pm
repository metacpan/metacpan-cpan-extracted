package Gearman::Starter;
use 5.008001;
use strict;
use warnings;

our $VERSION = "0.03";

use Gearman::Starter::Util;

use Getopt::Long;
use Pod::Usage qw/pod2usage/;

use Class::Inspector;
use Filesys::Notify::Simple;
use Gearman::Worker;
use Hash::Rename qw/hash_rename/;
use Module::Load ();
use IO::Socket::INET;
use Parallel::Prefork;
use Parallel::Scoreboard;

use Class::Accessor::Lite (
    new => 1,
    ro => [qw/prefix port listen max_workers max_requests_per_child scoreboard_dir on_fail/],
    rw => [qw/start_time scoreboard jobs/],
);

sub reload {
    my $self = shift;
    @{$self->{Reload} || []};
}

sub servers {
    my $self = shift;
    @{ ref $self->{server} ? $self->{server} : [$self->{server} || ()] };
}

sub modules {
    my $self = shift;
    @{ ref $self->{module} ? $self->{module} : [$self->{module} || ()] };
}

sub pid {shift->{pid} ||= []}

sub parse_options {
    my ($class, @argv) = @_;

    my $p = Getopt::Long::Parser->new(
        config => [qw/default posix_default no_ignore_case auto_help pass_through/]
    );
    my %opt = (
        'max-workers'            => 10,
        'max-requests-per-child' => 100,
        'listen'                 => '0.0.0.0',
    );
    $p->getoptionsfromarray(\@argv, \%opt, qw/
        server|s=s@
        prefix=s
        max-workers=i
        max-requests-per-child=i
        scoreboard-dir=s
        listen=s
        port=i
        Reload|R=s@
    /) or pod2usage;
    pod2usage unless $opt{server} && @{$opt{server}};

    while (@argv) {
        my $mod = shift @argv;
        last if $mod eq '--';
        push @{ $opt{module} }, $mod;
    }
    hash_rename %opt, code => sub {tr/-/_/};

    (\%opt, \@argv);
}

sub new_with_options {
    my ($class, @argv) = @_;
    my ($opt,) = $class->parse_options(@argv);
    $class->new($opt);
}

sub run {
    my $self = shift;

    if ($self->reload) {
        $self->_launch_watcher;
    }

    $self->start_time(time);

    if ( $self->scoreboard_dir ) {
        $self->scoreboard(Parallel::Scoreboard->new(
            base_dir => $self->scoreboard_dir,
        ));
    }

    if ( defined $self->port ) {
        my $pid = $self->_launch_monitor_socket;
        push @{$self->pid}, $pid;
    }
    $self->jobs($self->_load_jobs);

    $self->_run;
}

sub _load_jobs {
    my $self = shift;
    my %jobs;
    for my $klass ($self->modules) {
        Module::Load::load($klass);
        my @jobs = grep /^job_/, @{Class::Inspector->functions($klass)};
        for my $job (@jobs) {
            (my $job_name = $job) =~ s/^job_//; # Sledgeish dispatching
            $jobs{$job_name} = $klass->can($job);
        }
    }
    \%jobs;
}

sub _run {
    my $self = shift;

    my $pm = Parallel::Prefork->new({
        max_workers  => $self->max_workers,
        trap_signals => {
            TERM => 'TERM',
            HUP  => 'TERM',
            USR1 => undef,
        }
    });

    while ( $pm->signal_received ne 'TERM' ) {
        $pm->start and next;

        $0 = "$0 (worker)";
        my $counter = 0;
        $SIG{TERM} = sub { $counter = $self->max_requests_per_child };

        # Gearman::Worker isn't fork-safe
        my $worker = Gearman::Worker->new;
        $worker->job_servers($self->servers);
        $worker->prefix($self->prefix) if $self->prefix;
        my %jobs = %{$self->jobs};
        for my $job_name (keys %jobs) {
            $worker->register_function($job_name, $jobs{$job_name});
        }

        if ( $self->scoreboard ) {
            $self->scoreboard->update('. 0');
        }

        $worker->work(
            on_start => sub {
                $counter++;
                $self->scoreboard && $self->scoreboard->update( sprintf "%s %s %s", 'A',  $counter, shift);
            },
            on_complete => sub {
                $self->scoreboard && $self->scoreboard->update( sprintf "%s %s", '_', $counter );
            },
            ($self->on_fail ? (on_fail => $self->on_fail) : ()),
            stop_if => sub {
                $counter >= $self->max_requests_per_child;
            }
        );
        $pm->finish;
    }

    $pm->wait_all_children;

    for my $pid ( @{ $self->pid } ) {
        next unless $pid;
        kill 'TERM', $pid;
        waitpid( $pid, 0 );
    }
}

sub _launch_watcher {
    my $self = shift;
    while ( 1 ) {
        my $pid = fork;
        die "fork failed: $!" unless defined $pid;
        if ( $pid ) {
            #main process
            my $watcher = Filesys::Notify::Simple->new([$self->reload, $0]);
            warn "Watching @{[$self->reload]} for file updates.\n";
            NOTIFY: while ( 1 ) {
                my @restart;
                # this is blocking
                $watcher->wait(sub {
                    my @events = @_;
                    @events = grep {
                        $_->{path} !~ m![/\\][\._]|\.bak$|~$!
                    } @events;
                    return unless @events;
                    @restart = @events;
                });
                next NOTIFY unless @restart;
                for my $ev (@restart) {
                    warn "-- $ev->{path} updated.\n";
                }
                warn "Killing the existing worker (pid:$pid)\n";
                kill 'TERM', $pid;
                waitpid( $pid, 0 );
                warn "Successfully killed! Restarting the new worker process.\n";
                last NOTIFY;
            }
        }
        else {
            # child process
            return;
        }
    }
}

sub _launch_monitor_socket {
    my $self = shift;

    my $sock = IO::Socket::INET->new(
        Listen => 5,
        LocalAddr => $self->listen,
        LocalPort => $self->port,
        Proto  => 'tcp',
        Reuse  => 1,
    );
    die $! unless $sock;

    my $pid = fork;
    die "fork failed: $!" unless defined $pid;

    if ( $pid ) {
        #main process
        return $pid;
    }
    else {
        # status worker
        $0 = "$0 (status worker)";
        local $SIG{TERM} = sub { exit(0) };
        while ( 1 ) {
            my $client = $sock->accept();
            my $system_info = 'gearman_servers: ' . join ",", $self->servers;
            $system_info .= ' prefix: ' . $self->prefix if $self->prefix;
            $system_info .= ' class: ' . join ",", $self->modules;
            my $uptime = time - $self->start_time;
            print $client <<"EOF";
System: $system_info
Uptime: $uptime
EOF
            if ( $self->scoreboard ) {
                my $output = Gearman::Starter::Util::display_scoreboard($self->scoreboard);
                print $client $output;
            }
            else {
                print $client "ERROR: scoreboard is disabled\n";
            }
            $client->close;
        }
    }
}


1;
__END__

=encoding utf-8

=head1 NAME

Gearman::Starter - Gearman workers launcher with register functions

=head1 SYNOPSIS

    use Gearman::Starter;
    my $gearman_starter = Gearman::Starter->new(
        server                 => ['127.0.0.1:7003'],
        max_workers            => 3,
        max_requests_per_child => 10,
        module                 => ['MyWorker::Job'],
        scoreboard_dir         => $scoreboard_dir,         # optional
        port                   => 9999,                    # optional
        Reload                 => ['lib/MyWorker/Job.pm'], # optional
        on_fail                => sub { ... },             # optional
    );
    $gearman_starter->run;

=head1 DESCRIPTION

Gearman::Starter is Gearman worker launcher with register functions from specified modules.

This module is Objective backend of L<gearman-starter.pl>.

=head1 CONSTRUCTOR

C<new> is constructor method.

The following options are available:

=over

=item C<server>

Gearman server

=item C<max_workders>

=item C<max_requests_per_child>

=item C<module>

Modules with job definitions.

The functions whose name start with C</^job_/> in the modules are dealt with Gearman functions
and registered to workers automatically.

=item C<scoreboard_dir>

If you want to monitor status of workers, scoreboard is available.

=item C<port>

You can monitor status of workers through specified TCP port.
It is easily available by using Telnet or Netcat, etc.

=back

=head1 LICENSE

Copyright (C) Songmu.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHORS

Tokuhiro Matsuno E<lt>tokuhirom@gmail.comE<gt>

Masahiro Nagano E<lt>kazeburo@gmail.comE<gt>

Songmu E<lt>y.songmu@gmail.comE<gt>

=cut

