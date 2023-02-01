package Lemonldap::NG::Portal::Lib::2fDevices;

=pod

=head1 NAME

Lemonldap::NG::Portal::Lib::2fDevices - Role for registrable second factors

=head1 DESCRIPTION

This role provides LemonLDAP::NG modules with a high-level interface to storing
information on registrable second factors into the persistent session.

It is recommended that _2fDevices is never accessed directly from code outside
of this module

=head1 METHODS

=over

=cut

use strict;
use Mouse::Role;
use JSON;

requires qw(p conf logger);

our $VERSION = '2.0.16';

=item update2fDevice

Updates one field of a registered device

    $self->update2fDevice($req, $info, $type, $key, $value, $update_key, $update_value);

=over 4

=item req: Current LemonLDAP::NG request

=item info: hashref of current session information

=item type: 'type' field of the device to update

=item key, value: update the device whose 'key' field equals value

=item update_key, update_value: set the matched devices' 'update_key' field to update_value

=back

Returns true if the update was sucessful

=cut

sub update2fDevice {
    my ( $self, $req, $info, $type, $key, $value, $update_key, $update_value )
      = @_;

    my $user = $info->{ $self->conf->{whatToTrace} };

    my $_2fDevices = $self->get2fDevices( $req, $info );
    return 0 unless $_2fDevices;

    my @found =
      grep { $_->{type} eq $type and $_->{$key} eq $value } @{$_2fDevices};

    for my $device (@found) {
        $device->{$update_key} = $update_value;
    }

    if (@found) {
        $self->p->updatePersistentSession( $req,
            { _2fDevices => to_json($_2fDevices) }, $user );
        return 1;
    }
    return 0;
}

=item add2fDevice

Register a new device

    $self->add2fDevice($req, $info, $device);

=over 4

=item req: Current LemonLDAP::NG request

=item info: hashref of current session information

=item device: hashref of device details. It must contain at least a 'type',
'name' and 'epoch' key

=back

Returns true if the update was sucessful

=cut

sub add2fDevice {
    my ( $self, $req, $info, $device ) = @_;

    my $_2fDevices = $self->get2fDevices( $req, $info );

    push @{$_2fDevices}, $device;
    $self->logger->debug(
        "Append 2F device: { type => $device->{type}, name => $device->{name} }"
    );
    $self->p->updatePersistentSession( $req,
        { _2fDevices => to_json($_2fDevices) } );
    return 1;
}

=item del2fDevices

Delete the devices specified in the @$devices array

    $self->del2fDevices($req, $info, $devices);

=over 4

=item req: Current LemonLDAP::NG request

=item info: hashref of current session information

=item device: arrayref of type+epoch hashrefs

    [ { type => xxx, epoch => xxx }, { type => xxx, epoch => xxx } ]

=back

Returns true if the update was sucessful

=cut

sub del2fDevices {
    my ( $self, $req, $info, $devices ) = @_;

    return 0 unless ( ref($devices) eq 'ARRAY' );

    my $_2fDevices = $self->get2fDevices( $req, $info );
    return 0 unless $_2fDevices;

    my @updated_2fDevices = @{$_2fDevices};
    my $need_update       = 0;

    for my $device_spec (@$devices) {
        next unless ( ref($device_spec) eq 'HASH' );
        my $type  = $device_spec->{type};
        my $epoch = $device_spec->{epoch};
        next unless ( $type and $epoch );

        my $size_before = @updated_2fDevices;
        @updated_2fDevices =
          grep { not( $_->{type} eq $type and $_->{epoch} eq $epoch ) }
          @updated_2fDevices;
        if ( @updated_2fDevices < $size_before ) {
            $need_update = 1;
            $self->logger->debug(
                "Deleted 2F device: { type => $type, epoch => $epoch }");
        }
    }

    $self->p->updatePersistentSession( $req,
        { _2fDevices => to_json( [@updated_2fDevices] ) } )
      if $need_update;

    return 1;
}

=item del2fDevice

Delete a single device

    $self->del2fDevice($req, $info, $type, $epoch);

=over 4

=item req: Current LemonLDAP::NG request

=item info: hashref of current session information

=item type: type of the device to remove

=item epoch: timestamp of the device to remove

=back

Returns true if the update was sucessful

=cut

sub del2fDevice {
    my ( $self, $req, $info, $type, $epoch ) = @_;

    return $self->del2fDevices( $req, $info,
        [ { type => $type, epoch => $epoch } ] );
}

=item find2fDevicesByKey

Find devices from one of its attributes

    $self->find2fDevicesByKey($req, $info, $type, $key, $value);

=over 4

=item req: Current LemonLDAP::NG request

=item info: hashref of current session information

=item type: device type

=item key, value: attribute to search in the device hash and the value to filter on

=back

Returns an array of devices for which type, key and value match the supplied ones

=cut

sub find2fDevicesByKey {
    my ( $self, $req, $info, $type, $key, $value ) = @_;

    my $_2fDevices = $self->get2fDevices( $req, $info );
    return unless $_2fDevices;

    my @found =
      grep { $_->{type} eq $type and $_->{$key} eq $value } @{$_2fDevices};
    return @found;
}

=item get2fDevices

Return all registrable devices.

    $self->get2fDevices($req, $info);

=over 4

=item req: Current LemonLDAP::NG request

=item info: hashref of current session information

=back

Returns an arrayref of all registrable devices, or undef if an error occured

=cut

sub get2fDevices {
    my ( $self, $req, $info ) = @_;
    my $_2fDevices;

    $self->logger->debug("Looking for 2F devices...");
    if ( $info->{_2fDevices} ) {
        $_2fDevices =
          eval { from_json( $info->{_2fDevices}, { allow_nonref => 1 } ); };
        if ($@) {
            $self->logger->error("Corrupted session (_2fDevices): $@");
            return;
        }
    }
    else {
        # Return new ArrayRef
        return [];
    }
    return ref($_2fDevices) eq 'ARRAY' ? $_2fDevices : undef;
}

=item find2fDevicesByType

Return all registrable devices of a certain type. If type is not given, return
all registrable devices

    $self->find2fDevicesByType($req, $info, $type);

=over 4

=item req: Current LemonLDAP::NG request

=item info: hashref of current session information

=item type: type of registrable device to return

=back

Returns an array of all matching devices

=cut

sub find2fDevicesByType {
    my ( $self, $req, $info, $type ) = @_;
    my $_2fDevices = $self->get2fDevices( $req, $info );
    return                unless $_2fDevices;
    return @{$_2fDevices} unless $type;

    my @found = grep { $_->{type} eq $type } @{$_2fDevices};
    $self->logger->debug("Return $type");
    return @found;
}

1;

=back

