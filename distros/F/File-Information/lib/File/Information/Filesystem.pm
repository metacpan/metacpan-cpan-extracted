# Copyright (c) 2024 Löwenfelsen UG (haftungsbeschränkt)

# licensed under Artistic License 2.0 (see LICENSE file)

# ABSTRACT: generic module for extrating information from filesystems


package File::Information::Filesystem;

use v5.10;
use strict;
use warnings;

use parent 'File::Information::Base';

use Carp;

our $VERSION = v0.01;

my %_properties = (
    dev_disk_by_uuid        => {rawtype => 'uuid'},
    dev_disk_by_label       => {},
    dev_name                => {},
    dev_mapper_name         => {},
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

    croak 'No stat is given' unless defined $self->{stat};
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

File::Information::Filesystem - generic module for extrating information from filesystems

=head1 VERSION

version v0.01

=head1 SYNOPSIS

    use File::Information;

=head1 METHODS

=head1 AUTHOR

Löwenfelsen UG (haftungsbeschränkt) <support@loewenfelsen.net>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2024 by Löwenfelsen UG (haftungsbeschränkt) <support@loewenfelsen.net>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
