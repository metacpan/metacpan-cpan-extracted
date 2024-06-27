package Linux::Info::SysInfo::CPU::Arm;
use strict;
use warnings;
use Carp qw(confess);
use Class::XSAccessor getters => {
    get_variant      => 'variant',
    get_part         => 'part',
    get_revision     => 'revision',
    get_hardware     => 'hardware',
    get_serial       => 'serial',
    get_model_name   => 'model_name',
    get_cpu_revision => 'cpu_revision',
};

use base 'Linux::Info::SysInfo::CPU';

our $VERSION = '2.19'; # VERSION

# ABSTRACT: Collects Arm based CPU information from /proc/cpuinfo


# CPU architecture: 8
my $processor_regex = qr/^CPU\sarchitecture\:\s\d+$/;

sub processor_regex {
    return $processor_regex;
}

my %vendors = (
    '0x41' => 'ARM',
    '0x42' => 'Broadcom',
    '0x43' => 'Cavium',
    '0x44' => 'DEC',
    '0x4e' => 'Nvidia',
    '0x50' => 'APM',
    '0x51' => 'Qualcomm',
    '0x53' => 'Samsung',
    '0x56' => 'Marvell',
    '0x69' => 'Intel',
);

sub _parse {
    my $self               = shift;
    my $file               = $self->{source_file};
    my $flags_regex        = qr/^Features\t\:\s+(.*)/;
    my $flags_defined      = 0;
    my $vendor_regex       = qr/CPU\simplementer\t\:\s(0x\d+)/;
    my $bogo_regex         = qr/BogoMIPS\t\:\s(\d+\.\d+)/;
    my $processor_regex    = qr/^processor\t\:\s(\d)/;
    my $variant_regex      = qr/^CPU\svariant\t\:\s(0x\w+)/;
    my $part_regex         = qr/^CPU\spart\t\:\s(0x\w+)/;
    my $cpu_revision_regex = qr/^CPU\srevision\t\:\s(\d+)/;
    my $arch_regex         = qr/^CPU\sarchitecture\:\s(\d+)/;
    my $hardware_regex     = qr/^Hardware\s+\:\s(.*)/;
    my $serial_regex       = qr/^Serial\s+\:\s(.*)/;
    my $revision_regex     = qr/^Revision\s+\:\s(.*)/;
    my $model_regex        = qr/^Model\s+\:\s(.*)/;
    my $model_name_regex   = qr/^model\sname\s+\:\s(.*)/;
    my $processors         = 0;

    open( my $fh, '<', $file ) or confess "Cannot read $file: $!";

  LINE: while ( my $line = <$fh> ) {
        chomp($line);
        next LINE if ( $line eq '' );

        if ( $line =~ $serial_regex ) {
            next LINE if ( defined $self->{serial} );
            $self->{serial} = $1;
            next LINE;
        }

        if ( $line =~ $hardware_regex ) {
            next LINE if ( defined $self->{hardware} );
            $self->{hardware} = $1;
            next LINE;
        }

        if ( $line =~ $model_name_regex ) {
            next LINE if ( defined $self->{model_name} );
            $self->{model_name} = $1;
            next LINE;
        }

        if ( $line =~ $model_regex ) {
            next LINE if ( defined $self->{model} );
            $self->{model} = $1;
            next LINE;
        }

        if ( $line =~ $cpu_revision_regex ) {
            next LINE if ( defined $self->{cpu_revision} );
            $self->{cpu_revision} = $1;
            next LINE;
        }

        if ( $line =~ $revision_regex ) {
            next LINE if ( defined $self->{revision} );
            $self->{revision} = $1;
            next LINE;
        }

        if ( $line =~ $part_regex ) {
            next LINE if ( defined $self->{part} );
            $self->{part} = $1;
            next LINE;
        }

        if ( $line =~ $variant_regex ) {
            next LINE if ( defined $self->{variant} );
            $self->{variant} = $1;
            next LINE;
        }

        if ( $line =~ $model_regex ) {
            next LINE if ( defined $self->{model} );
            $self->{model} = $2;
            next LINE;
        }

        if ( $line =~ $arch_regex ) {
            next LINE if ( defined $self->{architecture} );

            # WORKAROUND: this is not the appropriate value, see _set_proc_bits
            $self->{architecture} = $1 + 0;
            next LINE;
        }

        if ( $line =~ $bogo_regex ) {
            next LINE if ( $self->{bogomips} != 0 );
            $self->{bogomips} = $1 + 0;
            next LINE;
        }

        if ( $line =~ $vendor_regex ) {
            next LINE if ( defined $self->{vendor} );

            if ( exists $vendors{$1} ) {
                $self->{vendor} = $vendors{$1};
            }
            else {
                my $message = "Unknown vendor '$1'. Known vendors are: ";
                $message .= join( ', ', values(%vendors) );
                warn $message;
                $self->{vendor} = $1;
            }
            next LINE;
        }

        if ( $line =~ $processor_regex ) {
            $processors++;
            next LINE;
        }

        if ( $line =~ $flags_regex ) {
            next LINE if ($flags_defined);
            $self->_parse_flags($line);
            $flags_defined = 1;
        }
    }

    close($fh);
    $self->{processors} = $processors;

    unless ( defined $self->{model} ) {
        $self->{model} = join(
            ' ',
            (
                $self->{vendor}, $self->{variant},
                $self->{part},   $self->{cpu_revision}
            )
        );
    }
}

sub _set_proc_bits {
    my $self = shift;

    if ( $self->{architecture} >= 8 ) {
        $self->{architecture} = 64;
    }
    else {
        $self->{architecture} = 32;
    }
}

sub _custom_attribs {
    my $self    = shift;
    my @attribs = (
        'variant',  'part',   'revision', 'model_name',
        'hardware', 'serial', 'cpu_revision'
    );
    map { $self->{$_} = undef } @attribs;
}

sub _set_hyperthread { }


sub get_cores {
    return 0;
}

# get_hardware     => 'hardware',
# get_serial       => 'serial',
# get_model_name   => 'model_name',
# get_cpu_revision => 'cpu_revision',


sub get_threads {
    return 0;
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Linux::Info::SysInfo::CPU::Arm - Collects Arm based CPU information from /proc/cpuinfo

=head1 VERSION

version 2.19

=head1 SYNOPSIS

See L<Linux::Info::SysInfo> C<get_cpu> method.

=head1 DESCRIPTION

This is a subclass of L<Linux::Info::SysInfo::CPU>, with specific code to parse
ARM format of L</proc/cpuinfo>.

ARM processor information parsing is a pain in the ass. Manufactures basically
add whatever information they want, and there are several manufactures.

Finding information about a ARM processor can also be quite difficult. Not all
vendors have model information available on the L</proc/cpuinfo> file, and
sometimes is required to even search specifications for a processor using the
following attributes in this class:

=over

=item *

C<vendor> (or "CPU implementer" in the original source file)

=item *

C<variant>

=item *

C<part>

=item *

C<revision>

=back

Most probably those values will be only hexadecimals that you will need to
search for.

This module does it best to correlate the C<vendor> with a human readable text,
but this is limited, and in cases it fails, C<vendor> will filled with original
hexadecimal for "CPU implementer" and a C<warn> will be generated.

One good source to search for more information is the
L<OpenBenchmarking|https://openbenchmarking.org/> website.

=head1 METHODS

=head2 processor_regex

Returns a regular expression that identifies the processor that is being read.

=head2 get_cores

Returns the number of cores of the processor.

=head2 get_hardware

Returns the content of C<Hardware> field on F</proc/cpuinfo> if available.

Otherwise returns C<undef>.

=head2 get_serial

Returns the content of C<Serial> field on F</proc/cpuinfo> if available.

Otherwise returns C<undef>.

=head2 get_model_name

Returns the content of C<model name> field on F</proc/cpuinfo> if available.

Otherwise returns C<undef>.

=head2 get_cpu_revision

Returns the content of C<cpu revision> field on F</proc/cpuinfo> if available.

Otherwise returns C<undef>.

=head2 get_part

Return an hexadecimal of the CPU part.

=head2 get_revision

Return an hexadecimal of the CPU revision.

=head2 get_variant

Return an hexadecimal of the CPU variant.

=head2 get_threads

Returns the number of threads of the processor.

=head1 SEE ALSO

=over

=item *

https://developer.arm.com/documentation

=item *

L<lscpu patch|https://github.com/util-linux/util-linux/pull/564/files> that
defines the translation of hexadecimal values to ARM processor implementer.

=item *

L<https://openbenchmarking.org/>

=back

=head1 AUTHOR

Alceu Rodrigues de Freitas Junior <glasswalk3r@yahoo.com.br>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2015 by Alceu Rodrigues de Freitas Junior.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
