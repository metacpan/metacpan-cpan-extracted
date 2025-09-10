# Copyright (c) 2024-2025 Löwenfelsen UG (haftungsbeschränkt)

# licensed under Artistic License 2.0 (see LICENSE file)

# ABSTRACT: generic module for extracting information from filesystems


package File::Information::Remote;

use v5.10;
use strict;
use warnings;

use parent 'File::Information::Base';

use Carp;

our $VERSION = v0.12;

my %_properties = (
    data_uriid_attr_displayname     => {loader => \&_load_data_uriid},
    data_uriid_attr_media_subtype   => {loader => \&_load_data_uriid, rawtype => 'mediatype'},
    data_uriid_attr_thumbnail       => {loader => \&_load_data_uriid},
    data_uriid_id                   => {loader => \&_load_data_uriid},
    data_uriid_ise                  => {loader => \&_load_data_uriid, rawtype => 'ise'},
    data_uriid_type                 => {loader => \&_load_data_uriid, rawtype => 'ise'},
    data_uriid_result               => {loader => \&_load_data_uriid, rawtype => 'Data::URIID::Result'},
    store_file                      => {loader => \&_load_fstore,     rawtype => 'File::FStore::File'},
);

# ----------------

sub _new {
    my ($pkg, %opts) = @_;
    my $self = $pkg->SUPER::_new(%opts, properties => \%_properties);

    return $self;
}

sub _load_data_uriid {
    my ($self) = @_;
    my $result = $self->{data_uriid_result} // return;
    my $pv = ($self->{properties_values} //= {})->{current} //= {};

    return if $self->{_loaded_data_uriid};
    $self->{_loaded_data_uriid} = 1;

    eval {$pv->{data_uriid_ise}  = {raw => $result->ise}};
    eval {$pv->{data_uriid_id}   = {raw => $result->id}};
    eval {$pv->{data_uriid_type} = {raw => $result->id_type(as => 'ise')}};
    $pv->{data_uriid_result} = {raw => $result};

    foreach my $digest ($result->available_keys('digest')) {
        my $value = $result->digest($digest, as => 'hex', default => undef) // next;
        $self->{digest}{current}{$digest} = $value;
    }

    foreach my $key (grep {/^data_uriid_attr_/} keys %_properties) {
        my $real_key = $key =~ s/^data_uriid_attr_//r;
        my $value = $result->attribute($real_key, as => 'string', default => undef) // next;
        $pv->{$key} = {raw => $value};
    }
}

sub _load_fstore {
    my ($self, $key, %opts) = @_;
    my $ise;
    my @candidates;

    return if $self->{_loaded_fstore};
    $self->{_loaded_fstore} = 1;

    $ise    = $self->get('data_uriid_ise', default => undef);

    return unless defined $ise;;

    foreach my $store ($self->instance->store(as => 'File::FStore')) {
        push(@candidates, $store->query(ise => $ise));
    }

    if (scalar(@candidates)) {
        my $pv_current = ($self->{properties_values} //= {})->{current} //= {};
        my $pv_final   = ($self->{properties_values} //= {})->{final} //= {};

        $pv_current->{store_file} = [map {{raw => $_}} @candidates];
        $pv_final->{store_file} = [map {{raw => $_}} @candidates];
    }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

File::Information::Remote - generic module for extracting information from filesystems

=head1 VERSION

version v0.12

=head1 SYNOPSIS

    use File::Information;

    my File::Information $instance = File::Information->new(%config);

    my File::Information::Remote $link = $instance->for_...(...);

B<Note:> This package inherits from L<File::Information::Base>.

This package represents a remote object (such as a remote hardlink or inode).

=head1 METHODS

=head1 AUTHOR

Löwenfelsen UG (haftungsbeschränkt) <support@loewenfelsen.net>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2024-2025 by Löwenfelsen UG (haftungsbeschränkt) <support@loewenfelsen.net>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
