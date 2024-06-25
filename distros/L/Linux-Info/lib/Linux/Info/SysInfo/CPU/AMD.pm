package Linux::Info::SysInfo::CPU::AMD;
use strict;
use warnings;
use Carp qw(confess);
use Class::XSAccessor getters => {
    get_cores     => 'cores',
    get_threads   => 'threads',
    get_frequency => 'frequency',
    get_cache     => 'cache',
};

use base 'Linux::Info::SysInfo::CPU';

our $VERSION = '2.18'; # VERSION

# ABSTRACT: Collects AMD based CPU information from /proc/cpuinfo


# vendor_id	: AuthenticAMD
my $vendor_regex = qr/^vendor_id\t\:\s(\w+)/;

sub processor_regex {
    return $vendor_regex;
}


sub get_bugs {
    my @bugs = shift->{bugs}->members;
    return \@bugs;
}

sub _custom_attribs {
    my $self = shift;
    $self->{multithread} = 0;
    $self->{cores}       = 0;
    $self->{threads}     = 0;
    $self->{bugs}        = Set::Tiny->new;
    $self->{frequency}   = 0;
    $self->{cache}       = undef;
}

sub _parse_bugs {
    my ( $self, $line ) = @_;
    $self->{line} = $line;
    my $value = $self->_parse_list;
    $self->{bugs}->insert( split( /\s/, $value ) );
    $self->{line} = undef;
}

sub _parse {
    my $self            = shift;
    my $file            = $self->{source_file};
    my $model_regex     = qr/^model\sname\t+\:\s(.*)/;
    my $processor_regex = qr/^physical\s+id\t+:\s*(\d+)/;
    my $core_regex      = qr/^core\s+id\t+:\s*(\d+)/;
    my $thread_regex    = qr/^processor\t+:\s*\d+/;
    my $flags_regex     = qr/^flags\s+\:/;
    my $bogo_regex      = qr/^bogomips\t+\:\s(\d+\.\d+)/;
    my $bugs_regex      = qr/^bugs\t+\:\s/;
    my $frequency_regex = qr/^cpu\s(\wHz)\t+\:\s(\d+\.\d+)/;
    my $cache_regex     = qr/^cache\ssize\t+\:\s(.*)/;

    my %processors;
    my $threads       = 0;
    my $flags_defined = 0;
    my $bugs_defined  = 0;
    my $phyid;
    open( my $fh, '<', $file ) or confess "Cannot read $file: $!";

  LINE: while ( my $line = <$fh> ) {
        chomp($line);

        if ( $line =~ $model_regex ) {
            next LINE if ( defined $self->{model} );
            $self->{model} = $1;
            next LINE;
        }

        if ( $line =~ $bogo_regex ) {
            $self->{bogomips} = $1;
            next LINE;
        }

        if ( $line =~ $vendor_regex ) {
            $self->{vendor} = $1;
            next LINE;
        }

        if ( $line =~ $cache_regex ) {
            $self->{cache} = $1;
            next LINE;
        }

        if ( $line =~ $processor_regex ) {

            # in order for this to work, it is expected that the physical line
            # comes first than the core
            $phyid = $1;
            $processors{$phyid}->{count}++;
            next LINE;
        }

        if ( $line =~ $core_regex ) {
            $processors{$phyid}->{cores}{$1}++;
            next LINE;
        }

        if ( $line =~ $thread_regex ) {
            $threads++;
            next LINE;
        }

        if ( $line =~ $frequency_regex ) {
            $self->{frequency}      = $2 if ( $2 > $self->{frequency} );
            $self->{frequency_unit} = $1;
            next LINE;
        }

        if ( $line =~ $bugs_regex ) {
            next LINE if ($bugs_defined);
            $self->_parse_bugs($line);
            $bugs_defined = 1;
        }

        if ( $line =~ $flags_regex ) {
            next LINE if ($flags_defined);
            $self->_parse_flags($line);
            $flags_defined = 1;
        }
    }

    close($fh);

    $self->{frequency} .= " $self->{frequency_unit}";
    delete $self->{frequency_unit};

    if ( ( scalar( keys %processors ) == 0 ) and ( $threads == 1 ) ) {
        $self->{processors} = 1;
        $self->{cores}      = 0;
        $self->{threads}    = 0;
    }
    else {
        $self->{processors} = scalar( keys(%processors) );
        $self->{cores}      = $processors{0}->{cores}->{0};
        $self->{threads}    = $threads;
    }

}

sub _set_proc_bits {
    my $self = shift;

    if ( $self->has_flag('lm') ) {
        $self->{architecture} = 64;
    }
    else {
        $self->{architecture} = 32;
    }
}

sub _set_hyperthread {
    my $self = shift;

    if ( $self->has_flag('ht') ) {
        $self->{multithread} = 1;
    }
    else {
        $self->{multithread} = 0;
    }
}


sub has_multithread {
    return shift->{multithread};
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Linux::Info::SysInfo::CPU::AMD - Collects AMD based CPU information from /proc/cpuinfo

=head1 VERSION

version 2.18

=head1 SYNOPSIS

See L<Linux::Info::SysInfo> C<get_cpu> method.

=head1 DESCRIPTION

This is a subclass of L<Linux::Info::SysInfo::CPU>, with specific code to parse
Intel format of L</proc/cpuinfo>.

=head1 METHODS

=head2 processor_regex

Returns a regular expression that identifies the processor that is being read.

=head2 get_bugs

Returns an array reference with all the bugs codes of this processor.

=head2 has_multithread

Returns "true" (1) or "false" (0) if the CPU has multithreading.

=head2 get_cores

Returns an integer of the number of cores available in the CPU.

=head2 get_threads

Returns an integer of the number of threads available per core in the CPU.

=head2 get_frequency

Returns a string with the maximum value of frequency of the CPU.

For some reason, the frequency in each one of the processors might be different
from each one.

In order to provide a single value, the highest found is considered.

=head2 get_cache

Returns a string with the value of the cache of the CPU.

=head1 AUTHOR

Alceu Rodrigues de Freitas Junior <glasswalk3r@yahoo.com.br>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2015 by Alceu Rodrigues de Freitas Junior.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
