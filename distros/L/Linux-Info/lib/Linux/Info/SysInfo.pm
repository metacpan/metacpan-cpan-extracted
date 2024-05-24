package Linux::Info::SysInfo;
use strict;
use warnings;
use Carp qw(croak);
use POSIX 1.15;
use Hash::Util qw(lock_keys);
use Class::XSAccessor
  getters => {
    get_raw_time   => 'raw_time',
    get_hostname   => 'hostname',
    get_domain     => 'domain',
    get_kernel     => 'kernel',
    get_release    => 'release',
    get_version    => 'version',
    get_mem        => 'mem',
    get_swap       => 'swap',
    get_pcpucount  => 'pcpucount',
    get_tcpucount  => 'tcpucount',
    get_interfaces => 'interfaces',
    get_arch       => 'arch',
    get_proc_arch  => 'proc_arch',
    get_cpu_flags  => 'cpu_flags',
    get_uptime     => 'uptime',
    get_idletime   => 'idletime',
    get_model      => 'model',
  },
  exists_predicates => { has_multithread => 'multithread', };

use Linux::Info::KernelFactory;

our $VERSION = '2.12'; # VERSION

my @_attribs = (
    'raw_time',  'hostname',  'domain',     'kernel',
    'release',   'version',   'mem',        'swap',
    'pcpucount', 'tcpucount', 'interfaces', 'arch',
    'proc_arch', 'cpu_flags', 'uptime',     'idletime',
    'model',     'mainline_version',
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
        files => {
            path     => '/proc',
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
        },
        arch     => ( uname() )[4],
        raw_time => $raw_time,
    );

    my $self = bless \%self, $class;

    $self->_set();
    lock_keys( %{$self} );

    return $self;
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
    my $self  = shift;
    my $class = ref($self);
    my $file  = $self->{files};

    for my $attrib (qw(hostname domain kernel release version)) {
        my $filename =
          $file->{path} ? "$file->{path}/$file->{$attrib}" : $file->{$attrib};
        open my $fh, '<', $filename
          or croak "$class: unable to open $filename: $!";
        $self->{$attrib} = <$fh>;
        chomp( $self->{$attrib} );
        close($fh);
    }

}

sub _set_meminfo {
    my $self  = shift;
    my $class = ref($self);
    my $file  = $self->{files};

    my $filename =
      $file->{path} ? "$file->{path}/$file->{meminfo}" : $file->{meminfo};
    open my $fh, '<', $filename
      or croak "$class: unable to open $filename ($!)";

    while ( my $line = <$fh> ) {
        if ( $line =~ /^MemTotal:\s+(\d+ \w+)/ ) {
            $self->{mem} = $1;
        }
        elsif ( $line =~ /^SwapTotal:\s+(\d+ \w+)/ ) {
            $self->{swap} = $1;
        }
    }

    close($fh);
}

sub _set_cpuinfo {
    my $self  = shift;
    my $class = ref($self);
    my $file  = $self->{files};
    my ( %cpu, $phyid );

    $self->{tcpucount} = 0;

    my $filename =
      $file->{path} ? "$file->{path}/$file->{cpuinfo}" : $file->{cpuinfo};
    open my $fh, '<', $filename
      or croak "$class: unable to open $filename ($!)";

    # default value for hyper threading
    $self->{multithread} = 0;

    # model name      : Intel(R) Core(TM) i5-4300M CPU @ 2.60GHz
    my $model_regex = qr/^model\sname\s+\:\s(.*)/;

    # Processor	: ARMv7 Processor rev 4 (v7l)
    my $arm_regex = qr/^Processor\s+\:\s(.*)/;

    while ( my $line = <$fh> ) {
        chomp($line);

      CASE: {

            if ( ( $line =~ $model_regex ) or ( $line =~ $arm_regex ) ) {
                $self->{model} = $1;
            }

            if ( $line =~ /^physical\s+id\s*:\s*(\d+)/ ) {
                $phyid = $1;
                $cpu{$phyid}{count}++;
                last CASE;
            }

            if ( $line =~ /^core\s+id\s*:\s*(\d+)/ ) {
                $cpu{$phyid}{cores}{$1}++;
                last CASE;
            }

            if ( $line =~ /^processor\s*:\s*\d+/ ) {    # x86
                $self->{tcpucount}++;
                last CASE;
            }

            if ( $line =~ /^# processors\s*:\s*(\d+)/ ) {    # s390
                $self->{tcpucount} = $1;
                last CASE;
            }

            if ( $line =~ /^flags\s+\:/ ) {

                last CASE if ( $self->get_cpu_flags );   # no use to repeat this

                my ( $attribute, $value ) = split( /\s+:\s/, $line );
                my @flags = split( /\s/, $value );

                $self->{cpu_flags} = \@flags;

                #long mode
                if ( $value =~ /\slm\s/ ) {
                    $self->{proc_arch} = 64;
                }
                else {
                    $self->{proc_arch} = 32;
                }

                #hyper threading
                if ( $value =~ /\sht\s/ ) {
                    $self->{multithread} = 1;
                }

                last CASE;
            }
        }
    }

    close($fh);
    $self->{pcpucount} = scalar( keys(%cpu) ) || $self->{tcpucount};
}

sub _set_interfaces {
    my $self  = shift;
    my $class = ref($self);
    my $file  = $self->{files};
    my @iface = ();

    my $filename =
      $file->{path} ? "$file->{path}/$file->{netdev}" : $file->{netdev};
    open my $fh, '<', $filename
      or croak "$class: unable to open $filename ($!)";
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

    my $filename =
      $file->{path} ? "$file->{path}/$file->{uptime}" : $file->{uptime};
    open my $fh, '<', $filename
      or croak "$class: unable to open $filename ($!)";
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

version 2.12

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

=head2 get_arch

Returns the processor architecture (like C<uname -m>).

=head2 has_multithread

Returns "true" (1) or "false" (0) indicating if the process has hyper threading
enabled or not.

=head2 get_model

Returns the processor name and model.

=head2 get_raw_time

Returns "true" (1) or "false" (0) if the instance is enabled to present time
attributes with their original (raw) format, or formatted ones.

=head2 is_multithread

A deprecated getter for the C<multithread> attribute.

Use C<has_multithread> method instead.

=head2 get_proc_arch

This method will return an integer as the architecture of the CPUs: 32 or 64 bits, depending on the flags
retrieve for one CPU.

It is assumed that all CPUs will have the same flags, so this method will consider only the flags returned
by the CPU with "core id" equal to 0 (in other words, the first CPU found).

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
