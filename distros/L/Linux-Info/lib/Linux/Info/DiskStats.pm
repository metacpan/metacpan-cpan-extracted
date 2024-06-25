package Linux::Info::DiskStats;
use strict;
use warnings;
use Carp qw(confess carp);
use Time::HiRes 1.9764;
use YAML::XS 0.88;
use Hash::Util qw(lock_keys);

use Linux::Info::SysInfo;
use Linux::Info::KernelRelease;

our $VERSION = '2.18'; # VERSION

use constant SPACES_REGEX => qr/\s+/;

# ABSTRACT: Collect Linux disks statistics.


sub _block_size {
    my ( $self, $device_name ) = @_;

    return $self->{global_block_size}
      if ( defined $self->{global_block_size} );

    if ( defined $self->{block_sizes} ) {
        if ( exists $self->{block_sizes}->{$device_name} ) {
            return $self->{block_sizes}->{$device_name};
        }
        else {
            confess
              "There is no configured block size for the device $device_name!";
        }
    }
    else {
        confess 'No block size available!';
    }
}

sub _shift_fields {
    my $fields_ref = shift;
    confess 'Must receive an array reference as parameter'
      unless ( ( defined($fields_ref) ) and ( ref $fields_ref eq 'ARRAY' ) );
    shift( @{$fields_ref} );    # nothing, really
    my %non_stats;
    $non_stats{major}       = shift( @{$fields_ref} );
    $non_stats{minor}       = shift( @{$fields_ref} );
    $non_stats{device_name} = shift( @{$fields_ref} );
    return \%non_stats;
}

sub _backwards_fields {
    my ( $size, $non_stats_ref, $stats_ref, $fields_ref ) = @_;
    my $device_name = $non_stats_ref->{device_name};

    $stats_ref->{$device_name} = {
        major  => $non_stats_ref->{major},
        minor  => $non_stats_ref->{minor},
        rdreq  => $fields_ref->[4],
        rdbyt  => ( $fields_ref->[5] * $size ),
        wrtreq => $fields_ref->[6],
        wrtbyt => ( $fields_ref->[7] * $size ),
        ttreq  => ( $fields_ref->[4] + $fields_ref->[6] ),
    };

    $stats_ref->{$device_name}->{ttbyt} =
      $stats_ref->{$device_name}->{rdbyt} +
      $stats_ref->{$device_name}->{wrtbyt};
}

sub _parse_ssd {
    my $self        = shift;
    my $source_file = $self->{source_file};

    open my $fh, '<', $source_file or confess "Cannot read $source_file: $!";
    my %stats;

    while ( my $line = <$fh> ) {
        chomp $line;
        my @fields           = split( SPACES_REGEX, $line );
        my $available_fields = scalar(@fields);

        if (    ( $self->{fields} > 0 )
            and ( $self->{fields} != $available_fields ) )
        {
            carp 'Inconsistent number of fields, had '
              . $self->{fields}
              . ", now have $available_fields";
        }

        $self->{fields} = $available_fields;
        my $non_stats_ref = _shift_fields( \@fields );

        if ( $self->{backwards_compatible} ) {
            _backwards_fields(
                $self->_block_size( $non_stats_ref->{device_name} ),
                $non_stats_ref, \%stats, \@fields );
        }
        else {
            my @name_position = (
                'read_completed',   'read_merged',
                'sectors_read',     'read_time',
                'write_completed',  'write_merged',
                'sectors_written',  'write_time',
                'io_in_progress',   'io_time',
                'weighted_io_time', 'discards_completed',
                'discards_merged',  'sectors_discarded',
                'discard_time',     'flush_completed',
                'flush_time'
            );

            my $field_counter = 0;
            for my $field_name (@name_position) {
                $stats{ $non_stats_ref->{device_name} }->{$field_name} =
                  $fields[$field_counter];
                $field_counter++;
            }
        }
    }

    close($fh) or confess "Cannot close $source_file: $!";
    confess "Failed to fetch statistics from $source_file"
      unless ( ( scalar( keys(%stats) ) ) > 0 );
    return \%stats;
}

sub _parse_disk_stats {
    my $self        = shift;
    my $source_file = $self->{source_file};

    open my $fh, '<', $source_file or confess "Cannot read $source_file: $!";
    my %stats;

    while ( my $line = <$fh> ) {
        chomp $line;
        my @fields           = split( SPACES_REGEX, $line );
        my $available_fields = scalar(@fields);

        if (    ( $self->{fields} > 0 )
            and ( $self->{fields} != $available_fields ) )
        {
            carp 'Inconsistent number of fields, had '
              . $self->{fields}
              . ", now have $available_fields";
        }

        $self->{fields} = $available_fields;
        my $non_stats_ref = _shift_fields( \@fields );

        if ( $self->{backwards_compatible} ) {
            _backwards_fields(
                $self->_block_size( $non_stats_ref->{device_name} ),
                $non_stats_ref, \%stats, \@fields );
        }
        else {
            my @name_position = (
                'read_completed',  'read_merged',
                'sectors_read',    'read_time',
                'write_completed', 'write_merged',
                'sectors_written', 'write_time',
                'io_in_progress',  'io_time',
                'weighted_io_time',
            );

            my $field_counter = 0;
            for my $field_name (@name_position) {
                $stats{ $non_stats_ref->{device_name} }->{$field_name} =
                  $fields[$field_counter];
                $field_counter++;
            }
        }
    }

    close($fh) or confess "Cannot close $source_file: $!";
    confess "Failed to fetch statistics from $source_file"
      unless ( ( scalar( keys(%stats) ) ) > 0 );
    return \%stats;
}

sub _parse_partitions {
    my $self        = shift;
    my $source_file = $self->{source_file};

    open my $fh, '<', $source_file or confess "Cannot read $source_file: $!";
    my %stats;

    while ( my $line = <$fh> ) {
        chomp $line;
        my @fields           = split( SPACES_REGEX, $line );
        my $available_fields = scalar(@fields);

        if (    ( $self->{fields} > 0 )
            and ( $self->{fields} != $available_fields ) )
        {
            carp 'Inconsistent number of fields, had '
              . $self->{fields}
              . ", now have $available_fields";
        }

        $self->{fields} = $available_fields;
        my $non_stats_ref = _shift_fields( \@fields );

        if ( $self->{backwards_compatible} ) {
            _backwards_fields(
                $self->_block_size( $non_stats_ref->{device_name} ),
                $non_stats_ref, \%stats, \@fields );
        }
        else {
            my @name_position = (
                'total_issued_reads',  'total_sectors_to_read',
                'total_issued_writes', 'total_sectors_to_write'
            );

            my $field_counter = 0;
            for my $field_name (@name_position) {
                $stats{ $non_stats_ref->{device_name} }->{$field_name} =
                  $fields[$field_counter];
                $field_counter++;
            }
        }
    }

    close($fh) or confess "Cannot close $source_file: $!";
    confess "Failed to fetch statistics from $source_file"
      unless ( ( scalar( keys(%stats) ) ) > 0 );
    return \%stats;
}


sub new {
    my ( $class, $opts ) = @_;
    my $config_class = 'Linux::Info::DiskStats::Options';
    confess "Must receive as parameter a instance of $config_class"
      unless ( ( ref $opts ne '' ) and ( $opts->isa($config_class) ) );

    my $self = {
        fields      => 0,
        time        => undef,
        source_file => undef,
        init        => undef,
        stats       => undef,
    };

    if ( defined( $opts->get_current_kernel ) ) {
        $self->{current} = $opts->get_current_kernel;
    }
    else {
        $self->{current} = Linux::Info::SysInfo->new->get_basic_kernel;
    }

    $self->{backwards_compatible} = $opts->get_backwards_compatible;
    warn
'Instance created in backward compatibility, this feature will be deprecated in the future'
      if ( $self->{backwards_compatible} );

    $self->{source_file}       = $opts->get_source_file;
    $self->{init_file}         = $opts->get_init_file;
    $self->{global_block_size} = $opts->get_global_block_size;
    $self->{block_sizes}       = $opts->get_block_sizes;

    unless ( defined $self->{source_file} ) {

        # not a real value, but should be enough accurate
        if (
            $self->{current} < Linux::Info::KernelRelease->new(
                { release => '2.4.20-0-generic' }
            )
          )
        {
            $self->{source_file}  = '/proc/partitions';
            $self->{parse_method} = \&_parse_partitions;
        }
        else {
            $self->{source_file} = '/proc/diskstats';
        }
    }

    unless ( exists $self->{parse_method} ) {
        if ( $self->{current} >=
            Linux::Info::KernelRelease->new('2.6.18-0-generic') )
        {
            $self->{parse_method} = \&_parse_ssd;
        }
        else {
            $self->{parse_method} = \&_parse_disk_stats;
        }
    }

    bless $self, $class;
    lock_keys( %{$self} );
    return $self;
}


sub init {
    my $self = shift;

    # TODO: properly test for not finding the file
    if ( $self->{init_file} && -r $self->{init_file} ) {
        $self->{init}   = YAML::XS::LoadFile( $self->{init_file} );
        $self->{'time'} = delete $self->{init}->{time};
    }
    else {
        $self->{time} = Time::HiRes::gettimeofday();
        $self->{init} = $self->_load;
    }

    return 1;
}


sub get {
    my $self  = shift;
    my $class = ref $self;

    confess "$class: there are no initial statistics defined"
      unless ( ( exists $self->{init} ) and ( $self->{init} ) );

    $self->{stats} = $self->_load;
    $self->_deltas if ( $self->{backwards_compatible} );

    if ( $self->{init_file} ) {
        $self->{init}->{time} = $self->{time};
        YAML::XS::DumpFile( $self->{init_file}, $self->{init} );
    }

    return $self->{stats};
}


sub raw {
    my $self = shift;
    return $self->_load;
}

sub _load {
    my $self = shift;
    $self->{parse_method}($self);
}

sub _deltas {
    my $self  = shift;
    my $class = ref $self;
    my $istat = $self->{init};
    my $lstat = $self->{stats};
    my $time  = Time::HiRes::gettimeofday();
    my $delta = sprintf( '%.2f', $time - $self->{time} );
    $self->{time} = $time;

    foreach my $dev ( keys %{$lstat} ) {
        if ( !exists $istat->{$dev} ) {
            delete $lstat->{$dev};
            next;
        }

        my $idev = $istat->{$dev};
        my $ldev = $lstat->{$dev};

        while ( my ( $k, $v ) = each %{$ldev} ) {
            next if $k =~ /^major\z|^minor\z/;

            if ( !defined $idev->{$k} ) {
                confess "$class: not defined key found '$k'";
            }

            if ( $v !~ /^\d+\z/ || $ldev->{$k} !~ /^\d+\z/ ) {
                confess "$class: invalid value for key '$k'";
            }

            if ( $ldev->{$k} == $idev->{$k} || $idev->{$k} > $ldev->{$k} ) {
                $ldev->{$k} = sprintf( '%.2f', 0 );
            }
            elsif ( $delta > 0 ) {
                $ldev->{$k} =
                  sprintf( '%.2f', ( $ldev->{$k} - $idev->{$k} ) / $delta );
            }
            else {
                $ldev->{$k} = sprintf( '%.2f', $ldev->{$k} - $idev->{$k} );
            }

            $idev->{$k} = $v;
        }
    }
}


sub fields_read() {
    my $self = shift;
    return $self->{fields};
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Linux::Info::DiskStats - Collect Linux disks statistics.

=head1 VERSION

version 2.18

=head1 SYNOPSIS

    use Linux::Info::DiskStats;

    my $config = Linux::Info::DiskStats::Options->new({backwards_compatibility => 0});
    my $lxs = Linux::Info::DiskStats->new($config);
    $lxs->init;
    sleep 1;
    my $stat = $lxs->get;

Or

    my $config = Linux::Info::DiskStats::Options->new({backwards_compatibility => 1,
                                                       global_block_size => 4096});
    my $lxs = Linux::Info::DiskStats->new($config);
    $lxs->init;
    my $stat = $lxs->get;

=head1 DESCRIPTION

C<Linux::Info::DiskStats> gathers disk statistics from the virtual F</proc>
filesystem (procfs).

For more information read the documentation of the front-end module
L<Linux::Info>.

=head1 DISK STATISTICS

The disk statics will depend on the kernel version that is running in the host.
See the L<Linux::Info::DiskStats/"SEE ALSO"> section for more details on that.

Also, this module produces two types of statistics:

=over

=item *

Backwards compatible with C<Linux::Info> versions 1.5 and lower.

=item *

New fields since version 1.6 and higher. These fields are also incompatible
with those produced by L<Sys::Statistics::Linux>.

=back

=head2 Backwards compatible fields

Those fields are generated from F</proc/diskstats> or F</proc/partitions>,
depending on the kernel version.

Not necessarily those fields will have a direct correlation with the fields
on the F</proc> directory, some of them are basically calculations and
others are not even statistics (C<major> and C<minor>).

These fields are kept only to provide compatibility, but it is
B<highly recommended> to not use compatibility mode since some statistics won't
be exposed and you can always execute the calculations yourself with that set.

=over

=item *

major: The mayor number of the disk

=item *

minor: The minor number of the disk

=item *

rdreq: Number of read requests that were made to physical disk per second.

=item *

rdbyt: Number of bytes that were read from physical disk per second.

=item *

wrtreq: Number of write requests that were made to physical disk per second.

=item *

wrtbyt: Number of bytes that were written to physical disk per second.

=item *

ttreq: Total number of requests were made from/to physical disk per second.

=item *

ttbyt: Total number of bytes transmitted from/to physical disk per second.

=back

=head2 The "new" fields

Actually, those fields are not really new: they are the almost exact
representation of those available on the respective F</proc> file, with small
differences in the fields naming in this module in order to make it easier to
type in.

These are the fields you want to use, if possible. It is also possible to have
the calculated fields by using the module
L<Linux::Info::DiskStats::Calculated>.

=head1 METHODS

=head2 new

Call C<new> to create a new object.

    my $lxs = Linux::Info::DiskStats->new($opts);

Where C<$opts> is a L<Linux::Info::DiskStats::Options>.

=head2 init

Call C<init> to initialize the statistics.

    $lxs->init;

=head2 get

Call C<get> to get the statistics. C<get()> returns the statistics as a hash reference.

    my $stat = $lxs->get;

=head2 raw

Get raw values, retuned as an hash reference.

=head2 fields_read

Returns an integer telling the number of fields process in each line from the
source file.

=head1 EXPORTS

Nothing.

=head1 SEE ALSO

=over

=item *

L<Linux::Info::DiskStats::Options>

=item *

B<proc(5)>

=item *

https://docs.kernel.org/admin-guide/iostats.html

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
