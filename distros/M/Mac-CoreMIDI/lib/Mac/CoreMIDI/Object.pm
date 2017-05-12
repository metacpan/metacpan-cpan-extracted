package Mac::CoreMIDI::Object;

use 5.006;
use strict;
use warnings;

our $VERSION = '0.03';

sub Dump {
    my ($self) = @_;
    (my $type = ref $self) =~ s/^Mac::CoreMIDI:://;
    my ($name, $manufacturer, $model, $uniqueID, $deviceID,
        $receiveCh, $transmitCh, $sysexspd, $schedule,
        $isembedded, $isbroadcast, $isrtent, $isoffline,
        $isprivate, $driverowner, $driverversion) = (
        $self->GetName() || '',
        $self->GetManufacturer() || '',
        $self->GetModel() || '',
        $self->GetUniqueID(),
        $self->GetDeviceID(),
        $self->GetReceiveChannels(),
        $self->GetTransmitChannels(),
        $self->GetMaxSysExSpeed(),
        $self->GetAdvanceScheduleTimeMuSec(),
        $self->IsEmbeddedEntity(),
        $self->IsBroadcast(),
        $self->IsSingleRealtimeEntity(),
        $self->IsOffline(),
        $self->IsPrivate(),
        $self->GetDriverOwner() || '',
        $self->GetDriverVersion(),
    );

    print <<EOT;
$type
    Name:                        $name
    Manufacturer:                $manufacturer
    Model:                       $model
    Unique ID:                   $uniqueID
    Device ID:                   $deviceID
    Receive channels:            $receiveCh
    Transmit channels:           $transmitCh
    Max. Sysex speed:            $sysexspd
    Schedule time:               $schedule
    Is embedded entity:          $isembedded
    Is broadcast:                $isbroadcast
    Is single real-time entity:  $isrtent
    Is offline:                  $isoffline
    Is private:                  $isprivate
    Driver owner:                $driverowner
    Driver version:              $driverversion

EOT
}

1;

__END__

=head1 NAME

Mac::CoreMIDI::Object - Encapsulates a CoreMIDI Object

=head1 DESCRIPTION

Mac::CoreMIDI::Object is the base class for most other CoreMIDI objects.

=head1 METHODS

=over 4

=item C<$self-E<gt>Dump()>

Prints a lot of information about the object to STDOUT.

=back

=head1 READ-ONLY PROPERTIES

=over 4

=item C<GetAdvanceScheduleTimeMuSec>

=item C<GetDeviceID>

=item C<GetDriverOwner>

=item C<GetDriverVersion>

=item C<GetManufacturer>

=item C<GetMaxSysExSpeed>

=item C<GetModel>

=item C<GetName>

=item C<GetReceiveChannels>

=item C<GetTransmitChannels>

=item C<GetUniqueID>

=item C<IsBroadcast>

=item C<IsEmbeddedEntity>

=item C<IsOffline>

=item C<IsPrivate>

=item C<IsSingleRealtimeEntity>

=back

=head1 SEE ALSO

L<CoreMIDI>

=head1 AUTHOR

Christian Renz, E<lt>crenz @ web42.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2004-2005 Christian Renz, E<lt>crenz @ web42.comE<gt>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut