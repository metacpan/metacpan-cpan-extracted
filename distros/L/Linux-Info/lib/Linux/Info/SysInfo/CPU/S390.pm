package Linux::Info::SysInfo::CPU::S390;
use strict;
use warnings;
use Carp qw(confess);
use Class::XSAccessor getters => {
    get_threads   => 'threads',
    get_frequency => 'frequency',
    get_cache     => 'cache'
};

use base 'Linux::Info::SysInfo::CPU';

our $VERSION = '2.19'; # VERSION

# ABSTRACT: Collects s390 based CPU information from /proc/cpuinfo


# vendor_id       : IBM/S390
my $vendor_regex = qr/^vendor_id\s+\:\s(.*)/;

sub processor_regex {
    return $vendor_regex;
}

sub _set_proc_bits {
    my $self = shift;

    if ( $self->has_flag('64bit') ) {
        $self->{architecture} = 64;
    }
    else {
        $self->{architecture} = 32;
    }
}

sub _set_hyperthread {
    my $self = shift;

    if ( $self->{threads} > 0 ) {
        $self->{multithread} = 1;
    }
    else {
        $self->{multithread} = 0;
    }
}


sub has_multithread {
    return shift->{multithread};
}


sub get_cores {
    return 0;
}


sub get_facilities {
    my $self       = shift;
    my @facilities = sort { $a <=> $b } $self->{facilities}->members;
    return \@facilities;
}

sub _custom_attribs {
    my $self = shift;
    $self->{multithread} = 0;
    $self->{cores}       = 0;
    $self->{threads}     = 0;
    $self->{facilities}  = Set::Tiny->new;
    $self->{frequency}   = undef;
    $self->{cache}       = undef;
}

sub _parse_facilities {
    my $self  = shift;
    my $value = $self->_parse_list;
    $self->{facilities}->insert( split( /\s/, $value ) );
    $self->{line} = undef;
}

sub _parse_cache {
    my ( $self, $line ) = @_;
    $self->{cache} = {} unless ( defined $self->{cache} );
    my @line       = split( /\s\:\s/, $line );
    my $cache_name = $line[0];
    my @values     = split( /\s/, $line[1] );
    $self->{cache}->{$cache_name} = {};

    foreach my $attribute (@values) {
        my ( $k, $v ) = split( '=', $attribute );
        $self->{cache}->{$cache_name}->{$k} = $v;
    }
}

sub _parse {
    my $self = shift;
    my $file = $self->{source_file};

    # bogomips per cpu: 3033.00
    my $bogo_regex = qr/^bogomips\sper\scpu\:\s(\d+\.\d+)/;

# features : esan3 zarch stfle msa ldisp eimm dfp edat etf3eh highgprs te vx sie
    my $flags_regex = qr/^features\s\:\s(.*)/;

    # processors    : 4
    my $processors_regex = qr/^processors\s+\:\s(\d+)/;

    # cpu MHz static : 5000
    my $cpu_mhz_regex = qr/^cpu\sMHz\sstatic\s\:\s(\d+)/;

    # max thread id : 0
    my $threads_regex = qr/^max\sthread\sid\s:\s(\d+)/;

    # cpu MHz static : 5000
    my $frequency_regex = qr/^cpu\s(\wHz)\sstatic\s\:\s(\d+)/;

    # facilities : 0 1 2 3 4
    my $facilities_regex = qr/^facilities\s\:\s/;
    my $cache_regex      = qr/cache\d\s\:\slevel/;

    # processor 0: version = FF, identification = 0133E8, machine = 2964
    my $model_regex  = qr/^processor\s\d\:\s(.*)/;
    my $flags_parsed = 0;
    open( my $fh, '<', $file ) or confess "Cannot read $file: $!";

  LINE: while ( my $line = <$fh> ) {
        chomp($line);
        next LINE if ( $line eq '' );

        if ( $line =~ $model_regex ) {
            next LINE if ( defined $self->{model} );
            $self->{model} = $1;
            $self->{model} =~ tr/=//d;
            $self->{model} =~ s/\s{2,}/ /g;
            next LINE;
        }

        if ( $line =~ $cache_regex ) {
            $self->_parse_cache($line);
        }

        if ( $line =~ $flags_regex ) {
            next LINE if ($flags_parsed);
            $self->_parse_flags($line);
            $flags_parsed = 1;
        }

        if ( $line =~ $vendor_regex ) {
            $self->{vendor} = $1;
            next LINE;
        }

        if ( $line =~ $bogo_regex ) {
            $self->{bogomips} = $1 + 0;
            next LINE;
        }

        if ( $line =~ $processors_regex ) {
            $self->{processors} = $1;
            next LINE;
        }

        if ( $line =~ $threads_regex ) {
            $self->{threads} = $1;
            next LINE;
        }

        if ( $line =~ $facilities_regex ) {
            $self->{line} = $line;
            $self->_parse_facilities;
            next LINE;
        }

        if ( $line =~ $frequency_regex ) {
            $self->{frequency} = "$2 $1";
            last LINE;
        }
    }

    close($fh);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Linux::Info::SysInfo::CPU::S390 - Collects s390 based CPU information from /proc/cpuinfo

=head1 VERSION

version 2.19

=head1 SYNOPSIS

See L<Linux::Info::SysInfo> C<get_cpu> method.

=head1 DESCRIPTION

This is a subclass of L<Linux::Info::SysInfo::CPU>, with specific code to parse
the IBM s390 processor format of L</proc/cpuinfo>.

=head1 METHODS

=head2 processor_regex

Returns a regular expression that identifies the processor that is being read.

=head2 has_multithread

Returns "true" (1) or "false" (0) if the CPU has multithreading.

=head2 get_cores

Returns an integer of the number of cores available in the CPU.

=head2 get_threads

Returns an integer of the number of threads available per core in the CPU.

=head2 get_frequency

Returns a string with the maximum value of frequency of the CPU.

=head2 get_cache

Returns a hash reference.

Each key is the name of a cache, and the value is also a hash reference with
the attributes of each cache.

=head2 get_facilities

Returns an array reference with the list of the facilities the processor has.

=head1 AUTHOR

Alceu Rodrigues de Freitas Junior <glasswalk3r@yahoo.com.br>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2015 by Alceu Rodrigues de Freitas Junior.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
