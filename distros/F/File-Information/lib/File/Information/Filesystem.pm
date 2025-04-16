# Copyright (c) 2024-2025 Löwenfelsen UG (haftungsbeschränkt)

# licensed under Artistic License 2.0 (see LICENSE file)

# ABSTRACT: generic module for extracting information from filesystems


package File::Information::Filesystem;

use v5.10;
use strict;
use warnings;

use parent 'File::Information::Base';

use Carp;

our $VERSION = v0.08;

my @_copy_properties = (
    qw(dos_device dos_path),
    qw(mountpoint fs_type),
    qw(linux_mount_options linux_superblock_options),
);

my %_properties = (
    dev_disk_by_uuid        => {rawtype => 'uuid'},
    dev_disk_by_label       => {},
    dev_name                => {},
    dev_mapper_name         => {},
    (map {$_ => {}}
        @_copy_properties,
    ),
);

my %_known_paths = (
    '/dev/disk/by-uuid'     => 'uuid',
    '/dev/disk/by-label'    => 'label',
    '/dev/mapper'           => 'mapper',
    '/dev'                  => 'dev',
);

sub _new {
    my ($pkg, %opts) = @_;
    my $self = $pkg->SUPER::_new(%opts, properties => \%_properties);
    my $pv = ($self->{properties_values} //= {})->{current} //= {};

    croak 'No stat or dirstat is given' unless defined($self->{stat}) || defined($self->{dirstat});
    croak 'No paths is given' unless defined $self->{paths};

    foreach my $key (keys %{$self->{paths}}) {
        my $known = $_known_paths{$key} or next;
        foreach my $value (@{$self->{paths}{$key}}) {
            if ($known eq 'uuid') {
                if ($value =~ __PACKAGE__->SUPER::RE_UUID) {
                    $pv->{dev_disk_by_uuid} = {raw => $value};
                }
            } elsif ($known eq 'label') {
                $pv->{dev_disk_by_label} = {raw => $value};
            } elsif ($known eq 'dev') {
                $pv->{dev_name} //= {raw => $value};
            } elsif ($known eq 'mapper') {
                $pv->{dev_mapper_name} //= {raw => $value};
            }
        }
    }

    # Simple keys:
    foreach my $key (@_copy_properties) {
        if (defined $self->{$key}) {
            $pv->{$key} = {raw => $self->{$key}};
        }
    }

    return $self;
}

# ----------------

sub _default_device_search_paths {
    return state $defaults = [qw(/dev /dev/disk/by-id /dev/mapper), keys %_known_paths];
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

File::Information::Filesystem - generic module for extracting information from filesystems

=head1 VERSION

version v0.08

=head1 SYNOPSIS

    use File::Information;

    my File::Information::Filesystem $filesystem = $instance->for_link($path)->filesystem;

    my File::Information::Filesystem $filesystem = $instance->for_handle($path)->filesystem;

B<Note:> This package inherits from L<File::Information::Base>.

This module represents a filesystem. A filesystem is the the stroage structure for inodes, hardlinks and maybe other types of objects.

=head1 METHODS

=head1 AUTHOR

Löwenfelsen UG (haftungsbeschränkt) <support@loewenfelsen.net>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2024-2025 by Löwenfelsen UG (haftungsbeschränkt) <support@loewenfelsen.net>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
