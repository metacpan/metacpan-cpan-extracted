package Linux::Info::Processes;
use strict;
use warnings;
use Carp qw(confess);
use Time::HiRes 1.9725;

use constant NUMBER => qr/^-{0,1}\d+(?:\.\d+){0,1}\z/;

our $VERSION = '2.18'; # VERSION

# ABSTRACT:  Collect Linux process statistics.


our $PAGES_TO_BYTES = 0;

sub new {
    my $class = shift;
    my $opts  = ref( $_[0] ) ? shift : {@_};

    my %self = (
        files => {
            path    => '/proc',
            uptime  => 'uptime',
            stat    => 'stat',
            statm   => 'statm',
            status  => 'status',
            cmdline => 'cmdline',
            wchan   => 'wchan',
            fd      => 'fd',
            io      => 'io',
            limits  => 'limits',
        },
        enabled => {
            io     => 0,
            limits => 0,
        }
    );

    if ( exists $opts->{enabled} ) {
        map { $self{enabled}->{$_} = $opts->{enabled}->{$_} }
          keys( %{ $opts->{enabled} } );
    }

    if ( defined $opts->{pids} ) {
        if ( ref( $opts->{pids} ) ne 'ARRAY' ) {
            confess 'The PIDs must be passed as a array reference to new()';
        }

        my $integer_regex = qr/^\d+\z/;

        foreach my $pid ( @{ $opts->{pids} } ) {
            confess "PID '$pid' is not a integer"
              unless ( $pid =~ $integer_regex );
        }

        $self{pids} = $opts->{pids};
    }

    if ( exists $opts->{files} ) {
        map { $self{files}->{$_} = $opts->{files}->{$_} }
          keys( %{ $opts->{files} } );
    }

    if ( $opts->{pages_to_bytes} ) {
        $self{pages_to_bytes} = $opts->{pages_to_bytes};
    }

    return bless \%self, $class;
}

sub get {
    my $self = shift;

    confess 'There are no initial statistics defined'
      unless ( exists $self->{init} );

    $self->{stats} = $self->_load;
    $self->_deltas;
    return $self->{stats};
}

sub raw {
    my $self = shift;
    my $stat = $self->_load;
    return $stat;
}

sub init {
    my $self  = shift;
    my $file  = $self->{files};
    my $pids  = $self->_get_pids;
    my $stats = {};

    $stats->{time} = Time::HiRes::gettimeofday();

    my @keys =
      qw (minflt cminflt mayflt cmayflt utime stime cutime cstime sttime);

    foreach my $pid (@$pids) {
        my $stat = $self->_get_stat($pid);

        if ( defined $stat ) {
            foreach my $key (@keys) {
                $stats->{$pid}->{$key} = $stat->{$key};
            }
            $stats->{$pid}->{io} = $self->_get_io($pid);

            foreach my $data (qw(io limits)) {
                if ( $self->{enabled}->{$data} ) {
                    my $method = "_get_$data";
                    $stats->{$pid}->{$data} = $self->$method($pid);
                }
            }
        }
    }
    $self->{init} = $stats;
}

sub _load {
    my $self   = shift;
    my $uptime = $self->_uptime;
    my $pids   = $self->_get_pids;
    my %stats;
    $stats{time} = Time::HiRes::gettimeofday();

    my @keys = qw(statm stat owner cmdline wchan fd);

    foreach my $data (qw(io limits)) {
        if ( $self->{enabled}->{$data} ) {
            push( @keys, $data );
        }
    }

  PID: foreach my $pid ( @{$pids} ) {
        foreach my $key (@keys) {
            my $method = "_get_$key";
            my $data   = $self->$method($pid);

            unless ( defined $data ) {
                delete $stats{$pid};
                next PID;
            }

            if ( ( $key eq 'statm' ) or ( $key eq 'stat' ) ) {
                for my $x ( keys %$data ) {
                    $stats{$pid}->{$x} = $data->{$x};
                }
            }
            else {
                $stats{$pid}->{$key} = $data;
            }
        }
    }

    return \%stats;
}

sub _get_limits {
    my ( $self, $pid ) = @_;
    my $file = $self->{files};
    my %stat;
    my ( $line, $limit );

    if ( open my $fh, '<', "$file->{path}/$pid/$file->{limits}" ) {
        while ( $line = <$fh> ) {
            if ( $line =~
                /^([Ma-z ]+[a-z]) +(\d+|unlimited) +(\d+|unlimited) +([a-z]*)/ )
            {
                $limit = $1;
                $limit =~ tr/M /m_/;
                $stat{$limit} = [ $2, $3, $4 ];    #soft hard units
            }
        }

        close($fh);
    }

    return \%stat;
}

sub _deltas {
    my $self   = shift;
    my $istat  = $self->{init};
    my $lstat  = $self->{stats};
    my $uptime = $self->_uptime;

    confess "not defined key found 'time'"
      unless ( ( defined $istat->{time} ) or ( defined $lstat->{time} ) );

    if ( $istat->{time} !~ NUMBER || $lstat->{time} !~ NUMBER ) {
        confess "invalid value for key 'time'";
    }

    my $time = $lstat->{time} - $istat->{time};
    $istat->{time} = $lstat->{time};
    delete $lstat->{time};

    for my $pid ( keys %{$lstat} ) {
        my $ipid = $istat->{$pid};
        my $lpid = $lstat->{$pid};

    # yeah, what happens if the start time is different... it seems that a new
    # process with the same process-id were created... for this reason I have to
    # check if the start time is equal!
        if ( $ipid && $ipid->{sttime} == $lpid->{sttime} ) {
            for my $k (
                qw(minflt cminflt mayflt cmayflt utime stime cutime cstime))
            {
                if ( !defined $ipid->{$k} ) {
                    confess "not defined key found '$k'";
                }
                if ( $ipid->{$k} !~ NUMBER || $lpid->{$k} !~ NUMBER ) {
                    confess "invalid value for key '$k'";
                }

                $lpid->{$k} -= $ipid->{$k};
                $ipid->{$k} += $lpid->{$k};

                if ( $lpid->{$k} > 0 && $time > 0 ) {
                    $lpid->{$k} = sprintf( '%.2f', $lpid->{$k} / $time );
                }
                else {
                    $lpid->{$k} = sprintf( '%.2f', $lpid->{$k} );
                }
            }

            $lpid->{ttime} = sprintf( '%.2f', $lpid->{stime} + $lpid->{utime} );

            for my $k (
                qw(rchar wchar syscr syscw read_bytes write_bytes cancelled_write_bytes)
              )
            {
                if ( defined $ipid->{io}->{$k} && defined $lpid->{io}->{$k} ) {
                    if (   $ipid->{io}->{$k} !~ NUMBER
                        || $lpid->{io}->{$k} !~ NUMBER )
                    {
                        confess "invalid value for io key '$k'";
                    }
                    $lpid->{io}->{$k} -= $ipid->{io}->{$k};
                    $ipid->{io}->{$k} += $lpid->{io}->{$k};
                    if ( $lpid->{io}->{$k} > 0 && $time > 0 ) {
                        $lpid->{io}->{$k} =
                          sprintf( '%.2f', $lpid->{io}->{$k} / $time );
                    }
                    else {
                        $lpid->{io}->{$k} =
                          sprintf( '%.2f', $lpid->{io}->{$k} );
                    }
                }
            }
        }
        else {
            # calculate the statistics since process creation
            for my $k (
                qw(minflt cminflt mayflt cmayflt utime stime cutime cstime))
            {
                my $p_uptime = $uptime - $lpid->{sttime} / 100;
                $istat->{$pid}->{$k} = $lpid->{$k};

                if ( $p_uptime > 0 ) {
                    $lpid->{$k} = sprintf( '%.2f', $lpid->{$k} / $p_uptime );
                }
                else {
                    $lpid->{$k} = sprintf( '%.2f', $lpid->{$k} );
                }
            }

            for my $k (
                qw(rchar wchar syscr syscw read_bytes write_bytes cancelled_write_bytes)
              )
            {
                my $p_uptime = $uptime - $lpid->{sttime} / 100;
                $lpid->{io}->{$k} ||= 0;
                $istat->{$pid}->{io}->{$k} = $lpid->{io}->{$k};

                if ( $p_uptime > 0 ) {
                    $lpid->{io}->{$k} =
                      sprintf( '%.2f', $lpid->{io}->{$k} / $p_uptime );
                }
                else {
                    $lpid->{io}->{$k} = sprintf( '%.2f', $lpid->{io}->{$k} );
                }
            }

            $lpid->{ttime} = sprintf( '%.2f', $lpid->{stime} + $lpid->{utime} );
            $istat->{$pid}->{sttime} = $lpid->{sttime};
        }
    }
}

sub _get_statm {
    my ( $self, $pid ) = @_;
    my $file = $self->{files};
    my %stat = ();

    open my $fh, '<', "$file->{path}/$pid/$file->{statm}"
      or return;

    my @line = split /\s+/, <$fh>;

    if ( @line < 7 ) {
        return;
    }

    my $ptb = $self->{pages_to_bytes} || $PAGES_TO_BYTES;

    if ($ptb) {
        @stat{qw(size resident share trs lrs drs dtp)} =
          map { $_ * $ptb } @line;
    }
    else {
        @stat{qw(size resident share trs lrs drs dtp)} = @line;
    }

    close($fh);
    return \%stat;
}

sub _get_stat {
    my ( $self, $pid ) = @_;
    my $file = $self->{files};
    my %stat = ();

    open my $fh, '<', "$file->{path}/$pid/$file->{stat}"
      or return;

    my @line = split /\s+/, <$fh>;

    if ( @line < 38 ) {
        return;
    }

    @stat{
        qw(
          cmd     state   ppid    pgrp    session ttynr   minflt
          cminflt mayflt  cmayflt utime   stime   cutime  cstime
          prior   nice    nlwp    sttime  vsize   nswap   cnswap
          cpu
        )
    } = @line[ 1 .. 6, 9 .. 19, 21 .. 22, 35 .. 36, 38 ];

    my $uptime = $self->_uptime;
    my ( $d, $h, $m, $s ) =
      $self->_calsec( sprintf( '%li', $uptime - $stat{sttime} / 100 ) );
    $stat{actime} = "$d:" . sprintf( '%02d:%02d:%02d', $h, $m, $s );

    close($fh);
    return \%stat;
}

sub _get_owner {
    my ( $self, $pid ) = @_;
    my $file  = $self->{files};
    my $owner = "N/a";

    open my $fh, '<', "$file->{path}/$pid/$file->{status}"
      or return;

    while ( my $line = <$fh> ) {
        if ( $line =~ /^Uid:(?:\s+|\t+)(\d+)/ ) {
            $owner = getpwuid($1) || "N/a";
            last;
        }
    }

    close($fh);
    return $owner;
}

sub _get_cmdline {
    my ( $self, $pid ) = @_;
    my $file = $self->{files};

    open my $fh, '<', "$file->{path}/$pid/$file->{cmdline}"
      or return;

    my $cmdline = <$fh>;
    close $fh;

    if ( !defined $cmdline ) {
        $cmdline = "N/a";
    }

    $cmdline =~ s/\0/ /g;
    $cmdline =~ s/^\s+//;
    $cmdline =~ s/\s+$//;
    chomp $cmdline;
    return $cmdline;
}

sub _get_wchan {
    my ( $self, $pid ) = @_;
    my $file = $self->{files};

    open my $fh, '<', "$file->{path}/$pid/$file->{wchan}"
      or return;

    my $wchan = <$fh>;
    close $fh;

    $wchan = defined unless ( defined $wchan );
    chomp $wchan;
    return $wchan;
}

sub _get_io {
    my ( $self, $pid ) = @_;
    my $file = $self->{files};
    my %stat = ();

    my $regex = qr/^([a-z_]+):\s+(\d+)/;

    if ( open my $fh, '<', "$file->{path}/$pid/$file->{io}" ) {

        while ( my $line = <$fh> ) {
            chomp $line;

            if ( $line =~ $regex ) {
                $stat{$1} = $2;
            }
        }

        close($fh);
    }

    return \%stat;
}

sub _get_fd {
    my ( $self, $pid ) = @_;
    my $file = $self->{files};
    my %stat = ();

    if ( opendir my $dh, "$file->{path}/$pid/$file->{fd}" ) {
        foreach my $link ( grep !/^\.+\z/, readdir($dh) ) {
            if ( my $target = readlink("$file->{path}/$pid/$file->{fd}/$link") )
            {
                $stat{$pid}{fd}{$link} = $target;
            }
        }
    }

    return \%stat;
}

sub _get_pids {
    my $self = shift;
    my $file = $self->{files};

    return $self->{pids} if ( $self->{pids} );

    opendir my $dh, $file->{path}
      or confess "unable to open directory $file->{path} ($!)";
    my @pids = grep /^\d+\z/, readdir $dh;
    closedir $dh;
    return \@pids;
}

sub _uptime {
    my $self = shift;
    my $file = $self->{files};

    my $filename =
      $file->{path} ? "$file->{path}/$file->{uptime}" : $file->{uptime};
    open my $fh, '<', $filename or confess "Unable to read $filename: $!";
    my ( $up, $idle ) = split /\s+/, <$fh>;
    close($fh) or confess "Unable to close $filename: $!";
    return $up;
}

sub _calsec {
    my $self = shift;
    my ( $s, $m, $h, $d ) = ( shift, 0, 0, 0 );
    $s >= 86400 and $d = sprintf( '%i', $s / 86400 ) and $s = $s % 86400;
    $s >= 3600  and $h = sprintf( '%i', $s / 3600 )  and $s = $s % 3600;
    $s >= 60    and $m = sprintf( '%i', $s / 60 )    and $s = $s % 60;
    return ( $d, $h, $m, $s );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Linux::Info::Processes - Collect Linux process statistics.

=head1 VERSION

version 2.18

=head1 SYNOPSIS

    use Linux::Info::Processes;

    my $lxs = Linux::Info::Processes->new;
    # or Linux::Info::Processes->new(pids => \@pids)

    $lxs->init;
    sleep 1;
    my $stat = $lxs->get;

=head1 PROCESS STATISTICS

Generated by F</proc/E<lt>pidE<gt>/stat>, F</proc/E<lt>pidE<gt>/status>,
F</proc/E<lt>pidE<gt>/cmdline> and F<getpwuid()>.

Note that if F</etc/passwd> isn't readable, the key owner is set to F<N/a>.

    ppid      -  The parent process ID of the process.
    nlwp      -  The number of light weight processes that runs by this process.
    owner     -  The owner name of the process.
    pgrp      -  The group ID of the process.
    state     -  The status of the process.
    session   -  The session ID of the process.
    ttynr     -  The tty the process use.
    minflt    -  The number of minor faults the process made.
    cminflt   -  The number of minor faults the child process made.
    mayflt    -  The number of mayor faults the process made.
    cmayflt   -  The number of mayor faults the child process made.
    stime     -  The number of jiffies the process have beed scheduled in kernel mode.
    utime     -  The number of jiffies the process have beed scheduled in user mode.
    ttime     -  The number of jiffies the process have beed scheduled (user + kernel).
    cstime    -  The number of jiffies the process waited for childrens have been scheduled in kernel mode.
    cutime    -  The number of jiffies the process waited for childrens have been scheduled in user mode.
    prior     -  The priority of the process (+15).
    nice      -  The nice level of the process.
    sttime    -  The time in jiffies the process started after system boot.
    actime    -  The time in D:H:M:S (days, hours, minutes, seconds) the process is active.
    vsize     -  The size of virtual memory of the process.
    nswap     -  The size of swap space of the process.
    cnswap    -  The size of swap space of the childrens of the process.
    cpu       -  The CPU number the process was last executed on.
    wchan     -  The "channel" in which the process is waiting.
    fd        -  This is a subhash containing each file which the process has open, named by its file descriptor.
                 0 is standard input, 1 standard output, 2 standard error, etc. Because only the owner or root
                 can read /proc/<pid>/fd this hash could be empty.
    cmd       -  Command of the process.
    cmdline   -  Command line of the process.

=head2 statm

Generated by F</proc/E<lt>pidE<gt>/statm>. All statistics provides information
about memory in pages:

    size      -  The total program size of the process.
    resident  -  Number of resident set size, this includes the text, data and stack space.
    share     -  Total size of shared pages of the process.
    trs       -  Total text size of the process.
    drs       -  Total data/stack size of the process.
    lrs       -  Total library size of the process.
    dtp       -  Total size of dirty pages of the process (unused since kernel 2.6).

It's possible to convert pages to bytes or kilobytes. For example, if the
pagesize of your system is 4kb:

    $Linux::Info::Processes::PAGES_TO_BYTES =    0; # pages (default)
    $Linux::Info::Processes::PAGES_TO_BYTES =    4; # convert to kilobytes
    $Linux::Info::Processes::PAGES_TO_BYTES = 4096; # convert to bytes

    # or with
    Linux::Info::Processes->new(pages_to_bytes => 4096);

=head2 io

Generated by F</proc/E<lt>pidE<gt>/io>.

Permissions on this file have changed with versions of the kernel, opt out from
trying to read the file by setting the file to a false value, like:

    files => { io => q{} }

=over

=item *

rchar: bytes read from storage (might have been from pagecache).

=item *

wchar: bytes written.

=item *

syscr: number of read syscalls.

=item *

syscw: number of write syscalls.

=item *

read_bytes: bytes really fetched from storage layer.

=item *

write_bytes: bytes sent to the storage layer.

=item *

cancelled_write_bytes: refer to docs.

=back

=head2 limits

Generated by F</proc/E<lt>pidE<gt>/limits>.

Often readable only by self and root, opt in to trying to read the file by
setting the file to C<limits>, like:

    files => { limits => 'limits' }

An array with (soft_limit, hard_limit, units) is provided for the limits listed.

This may vary between kernels. Some examples are:

=over

=item *

C<max_address_space>: the maximum amount of virtual memory available to the shell.

=item *

C<max_core_file_size>: the maximum size of core files created.

=item *

C<max_processes>: the maximum number of processes available to a single user.

=item *

C<max_open_files>: the maximum number of open file descriptors.

=item *

=back

See Documentation/filesystems/proc.txt for more information.

=head1 METHODS

=head2 new()

Call C<new()> to create a new object.

    my $lxs = Linux::Info::Processes->new;

It's possible to handoff an array reference with a PID list.

    my $lxs = Linux::Info::Processes->new(pids => [ 1, 2, 3 ]);

It's also possible to set the path to the F<proc> filesystem:

    my $lxs = Linux::Info::Processes->new(
        files => {
            # This is the default
            path    => '/proc',
            uptime  => 'uptime',
            stat    => 'stat',
            statm   => 'statm',
            status  => 'status',
            cmdline => 'cmdline',
            wchan   => 'wchan',
            fd      => 'fd',
            io      => 'io',
            limits  => 'limits',
        }
    );

If you want to enable C<io> and C<limits> information about the
processes, you need to enabled it explicity:

    my $lxs = Linux::Info::Processes->new(enabled => {
        io => 1, limits => 1
    });

Remember that the process executing C<Linux::Info::Processes> requires rights
to read C<io> and C<limits>.

=head2 init()

Call C<init()> to initialize the statistics.

    $lxs->init;

=head2 get()

Call C<get()> to get the statistics. C<get()> returns the statistics as a hash
reference.

    my $stat = $lxs->get;

B<Note>: processes that were created between the call of init() and get() are
returned as well, but the keys minflt, cminflt, mayflt, cmayflt, utime, stime,
cutime, and cstime are set to the value 0.00 because there are no inititial
values to calculate the deltas.

=head2 raw()

Get raw values.

=head1 EXPORTS

Nothing.

=head1 SEE ALSO

=over

=item *

B<proc(5)>

=item *

B<perldoc -f getpwuid>

=item *

L<Linux::Info>

=back

=head1 AUTHOR

Alceu Rodrigues de Freitas Junior <glasswalk3r@yahoo.com.br>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2015 by Alceu Rodrigues de Freitas Junior.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
