package Mac::CoreMIDI;

use 5.006;
use strict;
use warnings;

use Mac::CoreMIDI::Device;
use Mac::CoreMIDI::Entity;
use Mac::CoreMIDI::Endpoint;
use Mac::CoreMIDI::Client;
use Mac::CoreMIDI::Port;

require Exporter;

our @ISA = qw(Exporter);

our %EXPORT_TAGS = ( 'all' => [ qw(
    GetDevices
    GetNumberOfDevices
    GetDevice
    GetSources
    GetNumberOfSources
    GetSource
    GetDestinations
    GetNumberOfDestinations
    GetDestination
    GetExternalDevices
    GetNumberOfExternalDevices
    GetExternalDevice
    FindObject
    Restart
    RunLoopRun
    RunLoopStop
) ] 
);

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our $VERSION = '0.04';

sub GetDevices {
    my $numDevices = GetNumberOfDevices();
    my @devices = map { GetDevice($_) } 0..$numDevices-1;

    return @devices;
}

sub GetSources {
    my $numSources = GetNumberOfSources();
    my @sources = map { GetSource($_) } 0..$numSources-1;

    return @sources;
}

sub GetDestinations {
    my $numDestinations = GetNumberOfDestinations();
    my @destinations = map { GetDestination($_) } 0..$numDestinations-1;

    return @destinations;
}

sub GetExternalDevices {
    my $numExternalDevices = GetNumberOfExternalDevices();
    my @externaldevices = map { GetExternalDevice($_) } 0..$numExternalDevices-1;

    return @externaldevices;
}

require XSLoader;
XSLoader::load('Mac::CoreMIDI', $VERSION);

# Preloaded methods go here.

1;

__END__

=head1 NAME

Mac::CoreMIDI - XS Interface for the Mac OS X CoreMIDI API

=head1 SYNOPSIS

  use Mac::CoreMIDI qw(GetDevices);

  foreach (GetDevices()) {
      $_->Dump();
  }

=head1 DESCRIPTION

With Mac OS X, Apple introduced a flexible MIDI system called CoreMIDI. C<Mac::CoreMIDI> translates the procedural CoreMIDI API into a set of OO Perl classes.

You will need the CoreAudio SDK installed to compile this module.

CoreMIDI models MIDI devices that can have several entities. These entities have endpoints (sources and destinations). The classes are L<Mac::CoreMIDI::Device>, L<Mac::CoreMIDI::Entity> and L<Mac::CoreMIDI::Endpoint> (for both sources and destinations). The base class of most CoreMIDI classes is L<Mac::CoreMIDI::Object>.

=head1 CAVEAT

This module is work in progress. So far, information about the MIDI system can be collected and update messages can be received. However, the structure is subject to change. I hope to use code ref-based callbacks soon, which will help to implement the callbacks to read MIDI data more easily.

=head1 FUNCTIONS

All of the following functions can be imported on demand.

=over

=item C<my @dev = GetDevices()>

Returns a list of all MIDI devices.

=item C<my $n = GetNumberOfDevices()>

Returns the number of MIDI devices.

=item C<my $dev = GetDevice($i)>

Returns the C<$i>'th MIDI device (starting from 0).

=item C<my @src = GetSources()>

Returns a list of source endpoints.

=item C<my $n = GetNumberOfSources()>

Returns the number of sources.

=item C<my $src = GetSource($i)>

Returns the C<$i>'th source (starting from 0).

=item C<my @dest = GetDestinations()>

Returns a list of destination endpoints.

=item C<my $n = GetNumberOfDestinations()>

Returns the number of destinations.

=item C<my $dest = GetDestination($i)>

Returns the C<$i>'th destination (starting from 0).

=item C<my @edev = GetExternalDevices()>

Returns a list of external MIDI devices.

=item C<my $n = GetNumberOfExternalDevices()>

Returns the number of external MIDI devices.

=item C<GetExternalDevice($i)>

Returns the C<$i>'th external MIDI device (starting from 0).

=item C<my $obj = FindObject($id)>

Finds a MIDI object by its unique ID.

=item C<Restart()>

Force MIDI drivers to rescan for the hardware.

=item C<RunLoopRun()>

Starts "main" loop for receiving MIDI data.

=item C<RunLoopStop()>

Stops "main" loop.

=back

=head1 SEE ALSO

L<http://developer.apple.com/audio/>
L<file:///Developer/Examples/CoreAudio/Documentation/MIDI/index.html>

=head1 AUTHOR

Christian Renz, E<lt>crenz @ web42.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2004-2005 Christian Renz, E<lt>crenz @ web42.comE<gt>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
