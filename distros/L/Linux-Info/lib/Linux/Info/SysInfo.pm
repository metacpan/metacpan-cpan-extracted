package Linux::Info::SysInfo;
use strict;
use warnings;
use Carp qw(confess);
use POSIX 1.15;
use Hash::Util qw(lock_keys);
use Class::XSAccessor getters => {
    get_raw_time   => 'raw_time',
    get_hostname   => 'hostname',
    get_domain     => 'domain',
    get_kernel     => 'kernel',
    get_release    => 'release',
    get_version    => 'version',
    get_mem        => 'mem',
    get_swap       => 'swap',
    get_interfaces => 'interfaces',
    get_uptime     => 'uptime',
    get_idletime   => 'idletime',
    get_cpu        => 'cpu',
};

use Linux::Info::KernelFactory;
use Linux::Info::SysInfo::CPU::Intel;
use Linux::Info::SysInfo::CPU::Arm;
use Linux::Info::SysInfo::CPU::AMD;
use Linux::Info::SysInfo::CPU::S390;

our $VERSION = '2.17'; # VERSION

my @_attribs = (
    'raw_time',   'hostname', 'domain', 'kernel',
    'release',    'version',  'mem',    'swap',
    'interfaces', 'arch',     'uptime', 'idletime',
    'model',      'mainline_version',
);

# ABSTRACT: Collect linux system information.


sub new {
    my $class    = shift;
    my $opts_ref = shift;

    my $raw_time;

    (         ( ref($opts_ref) eq 'HASH' )
          and ( exists( $opts_ref->{raw_time} ) )
          and ( $opts_ref->{raw_time} =~ /^[01]$/ ) )
      ? ( $raw_time = $opts_ref->{raw_time} )
      : ( $raw_time = 0 );

    my %self = (
        arch     => ( uname() )[4],    # TODO: useless?
        raw_time => $raw_time,
        files    => {},
    );

    my $default_root  = '/proc';
    my %default_files = (
        meminfo  => 'meminfo',
        sysinfo  => 'sysinfo',
        cpuinfo  => 'cpuinfo',
        uptime   => 'uptime',
        hostname => 'sys/kernel/hostname',
        domain   => 'sys/kernel/domainname',
        kernel   => 'sys/kernel/ostype',
        release  => 'sys/kernel/osrelease',
        version  => 'version',
        netdev   => 'net/dev',
    );

    foreach my $info ( keys %default_files ) {
        if ( ( exists $opts_ref->{$info} ) and defined( $opts_ref->{$info} ) ) {
            $self{files}->{$info} = $opts_ref->{$info};
        }
        else {
            $self{files}->{$info} = $default_root . '/' . $default_files{$info};
        }
    }

    my $self = bless \%self, $class;

    $self->_set();
    lock_keys( %{$self} );

    return $self;
}


sub get_proc_arch {
    return shift->{cpu}->get_arch;
}

sub has_multithread {
    return shift->{cpu}->has_multithread;
}

sub get_pcpucount {
    return shift->{cpu}->get_cores;
}

sub get_tcpucount {
    return shift->{cpu}->get_threads;
}

sub get_model {
    return shift->{cpu}->get_model;
}

sub get_cpu_flags {
    return shift->{cpu}->get_flags;
}

sub _set {
    my $self  = shift;
    my $class = ref $self;
    my $file  = $self->{files};

    foreach my $attrib (@_attribs) {
        $self->{$attrib} = undef unless ( exists( $self->{$attrib} ) );
    }

    $self->_set_common;
    $self->_set_meminfo;
    $self->_set_time;
    $self->_set_interfaces;
    $self->_set_cpuinfo;

    foreach my $attrib (@_attribs) {
        if ( defined( $self->{attrib} ) ) {
            $self->{$attrib} =~ s/\t+/ /g;
            $self->{$attrib} =~ s/\s+/ /g;
        }
    }
}


sub is_multithread {
    warn 'This method will be deprecated, see the documentation';
    return shift->{multithread};
}


sub get_detailed_kernel {
    my $self = shift;
    return Linux::Info::KernelFactory->create;
}

sub _set_common {
    my $self     = shift;
    my $class    = ref($self);
    my $file_ref = $self->{files};

    for my $attrib (qw(hostname domain kernel release version)) {
        my $filename = $file_ref->{$attrib};
        open my $fh, '<', $filename
          or confess "Unable to read $filename: $!";
        $self->{$attrib} = <$fh>;
        chomp $self->{$attrib};
        close($fh);
    }

}

sub _set_meminfo {
    my $self  = shift;
    my $class = ref($self);
    my $file  = $self->{files};

    my $filename = $file->{meminfo};
    open my $fh, '<', $filename
      or confess "$class: unable to open $filename ($!)";
    my $mem_regex  = qr/^MemTotal:\s+(\d+ \w+)/;
    my $swap_regex = qr/^SwapTotal:\s+(\d+ \w+)/;

    while ( my $line = <$fh> ) {
        if ( $line =~ $mem_regex ) {
            $self->{mem} = $1;
            next;
        }

        if ( $line =~ $swap_regex ) {
            $self->{swap} = $1;
        }
    }

    close($fh);
}

sub _set_cpuinfo {
    my $self     = shift;
    my $class    = ref($self);
    my $file_ref = $self->{files};
    my $filename = $file_ref->{cpuinfo};

    open my $fh, '<', $filename
      or confess "Unable to read $filename: $!";

    # default value for hyper threading
    $self->{multithread} = 0;

    my $intel_regex = Linux::Info::SysInfo::CPU::Intel->processor_regex;
    my $arm_regex   = Linux::Info::SysInfo::CPU::Arm->processor_regex;
    my $s390_regex  = Linux::Info::SysInfo::CPU::S390->processor_regex;
    my $amd_regex   = Linux::Info::SysInfo::CPU::AMD->processor_regex;
    my $model;

  LINE: while ( my $line = <$fh> ) {
        chomp($line);

        if ( $line =~ $intel_regex ) {
            if ( $1 eq 'GenuineIntel' ) {
                $model = 'Intel';
                last LINE;
            }
        }

        if ( $line =~ $arm_regex ) {
            $model = 'Arm';
            last LINE;
        }

        if ( $line =~ $s390_regex ) {
            if ( $1 eq 'IBM/S390' ) {
                $model = 'S390';
                last LINE;
            }
        }

        if ( $line =~ $amd_regex ) {
            if ( $1 eq 'AuthenticAMD' ) {
                $model = 'AMD';
            }
        }
    }

    close($fh);

    unless ( defined($model) ) {
        open my $fh, '<', $filename or confess "Unable to read $filename: $!";
        local $/ = undef;
        my $data = <$fh>;
        close($fh);

        confess
"Failed to recognize the processor, submit the /proc/cpuinfo to this project as an issue.\n$data";
    }

    $self->{cpu} = "Linux::Info::SysInfo::CPU::$model"->new($filename);
}

sub _set_interfaces {
    my $self  = shift;
    my $class = ref($self);
    my $file  = $self->{files};
    my @iface = ();

    my $filename = $file->{netdev};
    open my $fh, '<', $filename
      or confess "$class: unable to open $filename ($!)";
    { my $head = <$fh>; }

    while ( my $line = <$fh> ) {
        if ( $line =~ /^\s*(\w+):/ ) {
            push @iface, $1;
        }
    }

    close $fh;
    $self->{interfaces} = \@iface;
}

sub _set_time {
    my $self  = shift;
    my $class = ref($self);
    my $file  = $self->{files};

    my $filename = $file->{uptime};
    open my $fh, '<', $filename
      or confess "$class: unable to open $filename ($!)";
    ( $self->{uptime}, $self->{idletime} ) = split /\s+/, <$fh>;
    close $fh;

    unless ( $self->get_raw_time() ) {
        foreach my $time (qw/uptime idletime/) {
            my ( $d, $h, $m, $s ) =
              $self->_calsec( sprintf( '%li', $self->{$time} ) );
            $self->{$time} = "${d}d ${h}h ${m}m ${s}s";
        }
    }
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

Linux::Info::SysInfo - Collect linux system information.

=head1 VERSION

version 2.17

=head1 SYNOPSIS

    use Linux::Info::SysInfo;

    my $lxs  = Linux::Info::SysInfo->new;
    print $lxs->get_release(), "\n";

=head1 DESCRIPTION

Linux::Info::SysInfo gathers system information from the virtual F</proc> filesystem (procfs).

For more information read the documentation of the front-end module L<Linux::Info>.

This class interface is B<incompatible> with L<Sys::Statistics::Linux::SysInfo>.

=head1 ATTRIBUTES

Generated by F</proc/sys/kernel/{hostname,domainname,ostype,osrelease,version}>
and F</proc/cpuinfo>, F</proc/meminfo>, F</proc/uptime>, F</proc/net/dev>.

=head1 METHODS

=head2 new()

Call C<new()> to create a new object.

    my $lxs = Linux::Info::SysInfo->new();

Without any parameters.

If you want to get C<uptime> and C<idletime> as raw value, then pass the following hash reference as parameter:

    my $lxs = Linux::Info::SysInfo->new({ raw_time => 1});

By default the C<raw_time> attribute is false.

=head2 get_hostname

Returns the host name.

=head2 get_domain

Returns the host domain name.

=head2 get_kernel

Returns the kernel name (just a string).

See C<get_detailed_kernel> for a instance of L<Linux::Info::KernelRelease> or
subclasses of it.

=head2 get_release

Returns the kernel release.

=head2 get_version

Returns the kernel version details.

=head2 get_mem

Returns the total size of memory.

=head2 get_swap

Returns the total size of swap space.

=head2 get_uptime

Returns the uptime of the system.

=head2 get_idletime

Returns the idle time of the system.

=head2 get_pcpucount

Returns the total number of physical CPUs.

=head2 get_tcpucount

Returns the total number of CPUs (cores, hyper threading).

=head2 get_interfaces

Returns the interfaces of the system.

=head2 get_proc_arch

Returns the processor architecture (like C<uname -m>).

=head2 has_multithread

Returns "true" (1) or "false" (0) indicating if the process has hyper threading
enabled or not.

=head2 get_model

Returns the processor name and model.

=head2 get_raw_time

Returns "true" (1) or "false" (0) if the instance is enabled to present time
attributes with their original (raw) format, or formatted ones.

=head2 get_cpu

Returns a instance of L<Linux::Info::SysInfo::CPU> sub classes.

=head2 is_multithread

A deprecated getter for the C<multithread> attribute.

Use C<has_multithread> method instead.

=head2 get_proc_arch

This method will return an integer as the architecture of the CPUs: 32 or 64
bits, depending on the flags retrieve for one CPU.

It is assumed that all CPUs will have the same flags, so this method will
consider only the flags returned by the CPU with "core id" equal to 0 (in
other words, the first CPU found).

=head2 get_cpu_flags

Returns an array reference with all flags retrieve from C</proc/cpuinfo> using the same logic described in
C<get_proc_arch> documentation.

=head2 get_model

A getter for the C<model> attribute.

=head2 get_detailed_kernel

Returns an instance of L<Linux::Info::KernelRelease> with all possible
information that is available.

=head1 EXPORTS

Nothing.

=head1 KNOWN ISSUES

Linux running on ARM processors have a different interface on F</proc/cpuinfo>.

That means that the methods C<get_proc_arch> and C<get_cpu_flags> will not
return their respective information. Tests for this module may fail as well.

=head1 SEE ALSO

=over

=item *

B<proc(5)>

=item *

L<Linux::Info>

=item *

L<POSIX>

=item *

L<Hash::Util>

=back

=head1 AUTHOR

Alceu Rodrigues de Freitas Junior <glasswalk3r@yahoo.com.br>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2015 by Alceu Rodrigues de Freitas Junior.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
