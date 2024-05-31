package Linux::Info;
use strict;
use warnings;
use Carp  qw(confess);
use POSIX qw(strftime);
use UNIVERSAL;
use Linux::Info::Compilation;

our $VERSION = '2.16'; # VERSION

# ABSTRACT: API in Perl to recover information about the running Linux OS


sub new {
    my $class = shift;
    my $self  = bless { obj => {} }, $class;

    my @options = qw(
      CpuStats  ProcStats
      MemStats  PgSwStats NetStats
      SockStats DiskStats DiskUsage
      LoadAVG   FileStats Processes
    );

    foreach my $opt (@options) {

        # backward compatibility
        $self->{opts}->{$opt} = 0;
        $self->{maps}->{$opt} = $opt;

        # new style
        my $lcopt = lc($opt);
        $self->{opts}->{$lcopt} = 0;
        $self->{maps}->{$lcopt} = $opt;
    }

    $self->set(@_) if @_;
    return $self;
}


sub set {
    my $self  = shift;
    my $class = ref $self;
    my $args  = ref( $_[0] ) eq 'HASH' ? shift : {@_};
    my $opts  = $self->{opts};
    my $obj   = $self->{obj};
    my $maps  = $self->{maps};

    confess 'Linux::Info::SysInfo cannot be instantiated from Linux::Info'
      if ( exists( $args->{sysinfo} ) );

    foreach my $opt ( keys( %{$args} ) ) {

        confess "invalid delta option '$opt'"
          unless ( exists( $opts->{$opt} ) );

        if ( ref( $args->{$opt} ) ) {
            $opts->{$opt} = delete $args->{$opt}->{init} || 1;
        }
        elsif ( $args->{$opt} !~ qr/^[012]\z/ ) {
            confess "invalid value for '$opt'";
        }
        else {
            $opts->{$opt} = $args->{$opt};
        }

        if ( $opts->{$opt} ) {
            my $package = $class . '::' . $maps->{$opt};

            # require module - require know which modules are loaded
            # and doesn't load a module twice.
            my $require = $package;
            $require =~ s/::/\//g;
            $require .= '.pm';
            require $require;

            if ( !$obj->{$opt} ) {
                if ( ref( $args->{$opt} ) ) {
                    $obj->{$opt} = $package->new( %{ $args->{$opt} } );
                }
                else {
                    $obj->{$opt} = $package->new();
                }
            }

            # get initial statistics if the function init() exists
            # and the option is set to 1
            if ( $opts->{$opt} == 1 && UNIVERSAL::can( $package, 'init' ) ) {
                $obj->{$opt}->init();
            }

        }
        elsif ( exists $obj->{$opt} ) {
            delete $obj->{$opt};
        }
    }
}


sub get {
    my ( $self, $time ) = @_;
    sleep $time if $time;
    my %stat = ();

    foreach my $opt ( keys %{ $self->{opts} } ) {
        if ( $self->{opts}->{$opt} ) {
            $stat{$opt} = $self->{obj}->{$opt}->get();
            if ( $opt eq 'netstats' ) {
                $stat{netinfo} = $self->{obj}->{$opt}->get_raw();
            }
        }
    }

    return Linux::Info::Compilation->new( \%stat );
}


sub init {
    my $self  = shift;
    my $class = ref $self;

    foreach my $opt ( keys %{ $self->{opts} } ) {
        if ( $self->{opts}->{$opt} > 0
            && UNIVERSAL::can( ref( $self->{obj}->{$opt} ), 'init' ) )
        {
            $self->{obj}->{$opt}->init();
        }
    }
}


sub settime {
    my $self   = shift;
    my $format = @_ ? shift : '%Y-%m-%d %H:%M:%S';
    $self->{timeformat} = $format;
}


sub gettime {
    my $self = shift;
    $self->settime(@_) unless $self->{timeformat};
    my $tm = strftime( $self->{timeformat}, localtime );
    return wantarray ? split /\s+/, $tm : $tm;
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Linux::Info - API in Perl to recover information about the running Linux OS

=head1 VERSION

version 2.16

=head1 SYNOPSIS

    use Linux::Info;

    # you can't use sysinfo like that!
    my $lxs = Linux::Info->new(
        cpustats  => 1,
        procstats => 1,
        memstats  => 1,
        pgswstats => 1,
        netstats  => 1,
        sockstats => 1,
        diskstats => 1,
        diskusage => 1,
        loadavg   => 1,
        filestats => 1,
        processes => 1,
    );

    sleep 1;
    my $stat = $lxs->get;

=head1 DESCRIPTION

Linux::Info is a fork from L<Sys::Statistics::Linux> distribution.

L<Sys::Statistics::Linux> is a front-end module and gather different linux
system information like processor workload, memory usage, network and disk
statistics and a lot more. Refer the documentation of the distribution modules
to get more information about all possible statistics.

=head1 MOTIVATION

L<Sys::Statistics::Linux> is a great distribution (and I used it a lot), but it
was built to recover only Linux statistics when I was also looking for other
additional information about the OS.

Linux::Info will provide additional information not available in
L<Sys::Statistics::Linux>, as general processor information and hopefully apply
patches and suggestions not implemented in the original project.

L<Sys::Statistics::Linux> is also more forgiving regarding compatibility with
older perls interpreters, modules version that it depends on and even older OS.
If you find that C<Linux::Info> is not available to your old system, you should
try it.

=head2 What is different from Sys::Statistics::Linux?

Linux::Info has:

=over

=item *

a more modern Perl 5 code;

=item *

doesn't use C<exec> syscall to acquire information;

=item *

provides additional information about the processors;

=item *

higher Kwalitee;

=back

=head1 TECHNICAL NOTE

This distribution collects statistics by the virtual F</proc> filesystem (procfs) and is
developed on the default vanilla kernel. It is tested on x86 hardware with the distributions
RHEL, Fedora, Debian, Ubuntu, Asianux, Slackware, Mandriva and openSuSE (SLES on zSeries as
well but a long time ago) on kernel versions 2.4 and/or 2.6. It's possible that it doesn't
run on all linux distributions if some procfs features are deactivated or too much modified.
As example the Linux kernel 2.4 can compiled with the option C<CONFIG_BLK_STATS> what turn
on or off block statistics for devices.

=head1 VIRTUAL MACHINES

Note that if you try to install or run C<Linux::Info> under virtual machines
on guest systems that some statistics are not available, such as C<SockStats>, C<PgSwStats>
and C<DiskStats>. The reason is that not all F</proc> data are passed to the guests.

If the installation fails then try to force the installation with

    cpan> force install Linux::Info

and notice which tests fails, because these statistics maybe not available on the virtual machine - sorry.

=head1 DELTAS

The statistics for C<CpuStats>, C<ProcStats>, C<PgSwStats>, C<NetStats>, C<DiskStats> and C<Processes>
are deltas, for this reason it's necessary to initialize the statistics before the data can be
prepared by C<get()>. These statistics can be initialized with the methods C<new()>, C<set()> and
C<init()>. For any option that is set to 1, the statistics will be initialized by the call of
C<new()> or C<set()>. The call of init() re-initialize all statistics that are set to 1 or 2.
By the call of C<get()> the initial statistics will be updated automatically. Please refer the
section L</METHODS> to get more information about the usage of C<new()>, C<set()>, C<init()>
and C<get()>.

Another exigence is to C<sleep> for a while - at least for one second - before the call of C<get()>
if you want to get useful statistics. The statistics for C<SysInfo>, C<MemStats>, C<SockStats>,
C<DiskUsage>, C<LoadAVG> and C<FileStats> are no deltas. If you need only one of these information
you don't need to sleep before the call of C<get()>.

The method C<get()> prepares all requested statistics and returns the statistics as a
L<Linux::Info::Compilation> object. The initial statistics will be updated.

=head1 MANUAL PROC(5)

The Linux Programmer's Manual

L<http://www.kernel.org/doc/man-pages/online/pages/man5/proc.5.html>

If you have questions or don't understand the sense of some statistics then take a look
into this awesome documentation.

=head1 OPTIONS FOR NEW INSTANCES

During the creation of new instances of L<Linux::Info>, you can pass as parameters to the C<new> method different statistics to
collect. The statistics available are those listed on L</DELTAS>.

You can use the L</DELTAS> by using their respective package names in lowercase. To activate the gathering of statistics you have to set the options by the call of C<new()> or C<set()>.
In addition you can deactivate statistics with C<set()>.

The options must be set with one of the following values:

    0 - deactivate statistics
    1 - activate and init statistics
    2 - activate statistics but don't init

In addition it's possible to pass a hash reference with options.

    my $lxs = Linux::Info->new(
        processes => {
            init => 1,
            pids => [ 1, 2, 3 ]
        },
        netstats => {
            init => 1,
            initfile => $file,
        },
    );

Option C<initfile> is useful if you want to store initial statistics on the filesystem.

    my $lxs = Linux::Info->new(
        cpustats => {
            init     => 1,
            initfile => '/tmp/cpustats.yml',
        },
        diskstats => {
            init     => 1,
            initfile => '/tmp/diskstats.yml',
        },
        netstats => {
            init     => 1,
            initfile => '/tmp/netstats.yml',
        },
        pgswstats => {
            init     => 1,
            initfile => '/tmp/pgswstats.yml',
        },
        procstats => {
            init     => 1,
            initfile => '/tmp/procstats.yml',
        },
    );

Example:

    use strict;
    use warnings;
    use Linux::Info;

    my $lxs = Linux::Info->new(
        pgswstats => {
            init => 1,
            initfile => '/tmp/pgswstats.yml'
        }
    );

    $lxs->get(); # without to sleep

The initial statistics are stored to the temporary file:

    #> cat /tmp/pgswstats.yml
    ---
    pgfault: 397040955
    pgmajfault: 4611
    pgpgin: 21531693
    pgpgout: 49511043
    pswpin: 8
    pswpout: 272
    time: 1236783534.9328

Every time you call the script the initial statistics are loaded/stored from/to the file.
This could be helpful if you doesn't run it as daemon and if you want to calculate the
average load of your system since the last call.

To get more information about the statistics refer the different modules of the distribution.

    cpustats    -  Collect cpu statistics                  with Linux::Info::CpuStats.
    procstats   -  Collect process statistics              with Linux::Info::ProcStats.
    memstats    -  Collect memory statistics               with Linux::Info::MemStats.
    pgswstats   -  Collect paging and swapping statistics  with Linux::Info::PgSwStats.
    netstats    -  Collect net statistics                  with Linux::Info::NetStats.
    sockstats   -  Collect socket statistics               with Linux::Info::SockStats.
    diskstats   -  Collect disk statistics                 with Linux::Info::DiskStats.
    diskusage   -  Collect the disk usage                  with Linux::Info::DiskUsage.
    loadavg     -  Collect the load average                with Linux::Info::LoadAVG.
    filestats   -  Collect inode statistics                with Linux::Info::FileStats.
    processes   -  Collect process statistics              with Linux::Info::Processes.

The options just described don't apply to L<Linux::Info::SysInfo> since this module doesn't hold statistics from the OS.
If you try to use it C<Linux::Info> will C<die> with an error message. In order to use L<Linux::Info::SysInfo>, just
create an instance of it directly. See L<Linux::Info::SysInfo> for information on that.

=head1 METHODS

=head2 new()

Call C<new()> to create a new Linux::Info object. You can call C<new()> with options.
This options would be passed to the method C<set()>.

Without options

    my $lxs = Linux::Info->new();

Or with options

    my $lxs = Linux::Info->new( cpustats => 1 );

Would do nothing

    my $lxs = Linux::Info->new( cpustats => 0 );

It's possible to call C<new()> with a hash reference of options.

    my %options = (
        cpustats => 1,
        memstats => 1
    );

    my $lxs = Linux::Info->new(\%options);

=head2 set()

Call C<set()> to activate or deactivate options.

The following example would call C<new()> and initialize C<Linux::Info::CpuStats>
and delete the object of C<Linux::Info::SysInfo>.

    $lxs->set(
        processes =>  0, # deactivate this statistic
        pgswstats =>  1, # activate the statistic and calls new() and init() if necessary
        netstats  =>  2, # activate the statistic and call new() if necessary but not init()
    );

It's possible to call C<set()> with a hash reference of options.

    my %options = (
        cpustats => 2,
        memstats => 2
    );

    $lxs->set(\%options);

=head2 get()

Call C<get()> to get the collected statistics. C<get()> returns a
L<Linux::Info::Compilation> object.

    my $lxs  = Linux::Info->new(\%options);
    sleep(1);
    my $stat = $lxs->get();

Or you can pass the time to sleep with the call of C<get()>.

    my $stat = $lxs->get($time_to_sleep);

Now the statistcs are available with

    $stat->cpustats

    # or

    $stat->{cpustats}

Take a look to the documentation of L<Linux::Info::Compilation> for more information.

=head2 init()

The call of C<init()> initiate all activated statistics that are necessary for
deltas. That could be helpful if your script runs in a endless loop with a high
sleep interval. Don't forget that if you call C<get()> that the statistics are
deltas since the last time they were initiated.

The following example would calculate average statistics for 30 minutes:

    # initiate cpustats
    my $lxs = Linux::Info->new( cpustats => 1 );

    while ( 1 ) {
        sleep(1800);
        my $stat = $lxs->get;
    }

If you just want a current snapshot of the system each 30 minutes and not the
average then the following example would be better for you:

    # do not initiate cpustats
    my $lxs = Linux::Info->new( cpustats => 2 );

    while ( 1 ) {
        $lxs->init;              # init the statistics
        my $stat = $lxs->get(1); # get the statistics
        sleep(1800);             # sleep until the next run
    }

If you want to write a simple command line utility that prints the current
workload to the screen then you can use something like this:

    my @order = qw(user system iowait idle nice irq softirq total);
    printf "%-20s%8s%8s%8s%8s%8s%8s%8s%8s\n", 'time', @order;

    my $lxs = Linux::Info->new( cpustats => 1 );

    while ( 1 ){
        my $cpu  = $lxs->get(1)->cpustats;
        my $time = $lxs->gettime;
        printf "%-20s%8s%8s%8s%8s%8s%8s%8s%8s\n",
            $time, @{$cpu->{cpu}}{@order};
    }

=head2 settime()

Call C<settime()> to define a POSIX formatted time stamp, generated with
localtime().

    $lxs->settime('%Y/%m/%d %H:%M:%S');

To get more information about the formats take a look at C<strftime()> of
POSIX.pm or the manpage C<strftime(3)>.

=head2 gettime()

C<gettime()> returns a POSIX formatted time stamp, @foo in list and $bar in
scalar context. If the time format isn't set then the default format
"%Y-%m-%d %H:%M:%S" will be set automatically. You can also set a time format
with C<gettime()>.

    my $date_time = $lxs->gettime;

Or

    my ($date, $time) = $lxs->gettime();

Or

    my ($date, $time) = $lxs->gettime('%Y/%m/%d %H:%M:%S');

=head1 EXAMPLES

A very simple perl script could looks like this:

    use strict;
    use warnings;
    use Linux::Info;

    my $lxs = Linux::Info->new( cpustats => 1 );
    sleep(1);
    my $stat = $lxs->get;
    my $cpu  = $stat->cpustats->{cpu};

    print "Statistics for CpuStats (all)\n";
    print "  user      $cpu->{user}\n";
    print "  nice      $cpu->{nice}\n";
    print "  system    $cpu->{system}\n";
    print "  idle      $cpu->{idle}\n";
    print "  ioWait    $cpu->{iowait}\n";
    print "  total     $cpu->{total}\n";

Set and get a time stamp:

    use strict;
    use warnings;
    use Linux::Info;

    my $lxs = Linux::Info->new();
    $lxs->settime('%Y/%m/%d %H:%M:%S');
    print $lxs->gettime, "\n";

If you want to know how the data structure looks like you can use C<Data::Dumper> to check it:

    use strict;
    use warnings;
    use Linux::Info;
    use Data::Dumper;

    my $lxs = Linux::Info->new( cpustats => 1 );
    sleep(1);
    my $stat = $lxs->get;

    print Dumper($stat);

How to get the top 5 processes with the highest cpu workload:

    use strict;
    use warnings;
    use Linux::Info;

    my $lxs = Linux::Info->new( processes => 1 );
    sleep(1);
    my $stat = $lxs->get;
    my @top5 = $stat->pstop( ttime => 5 );

=head1 EXPORTS

Nothing.

=head1 SEE ALSO

=over

=item *

The L<Sys::Statistics::Linux> distribution, which is base of Linux::Info

=item *

The project website at L<https://github.com/glasswalk3r/Linux-Info>.

=back

=head1 AUTHOR

Alceu Rodrigues de Freitas Junior <glasswalk3r@yahoo.com.br>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2015 by Alceu Rodrigues de Freitas Junior.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
