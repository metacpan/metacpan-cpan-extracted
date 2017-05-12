package Ekahau::Response::LocationEstimate;
use base 'Ekahau::Response'; our $VERSION=Ekahau::Response::VERSION;

# Written by Scott Gifford <gifford@umich.edu>
# Copyright (C) 2004 The Regents of the University of Michigan.
# See the file LICENSE included with the distribution for license
# information.

use strict;
use warnings;


=head1 NAME

Ekahau::Response::LocationEstimate - Contains an estimate of an object's location

=head1 SYNOPSIS

When an object is being tracked by Ekahau, you'll receive periodic
estimates of its location, in the form of these objects.

=head1 DESCRIPTION

=head2 Constructor

Generally you will not want to construct these objects yourself; they
are created by L<Ekahau::Response|Ekahau::Response>, and use its constructor.

=head2 Methods

=cut

# Internal method
sub init
{
    warn "Created Ekahau::Response::LocationEstimate object\n"
	if ($ENV{VERBOSE});
}

=head3 get_props ( @prop_names )

Inherited from L<Ekahau::Response::get_props|Ekahau::Response/get_props>.  Returns a hash
containing the values for the list of L<Properties|/Properties> in
C<@prop_names>.  If C<@prop_names> is empty, all properties will be
returned.

=cut

=head3 get_prop ( $prop_name )

Inherited from L<Ekahau::Response::get_prop|Ekahau::Response/get_prop>.  Returns the value for
one of this object's L<Properties|/Properties>, specified by C<$prop_name>.  If
no property named C<$prop_name> exists, C<undef> is returned.

=cut

=head3 type ( )

Returns the string I<LocationEstimate>, to identify the type of this object.

=cut

sub type
{
    'LocationEstimate';
}

=head2 Properties

Properties can be retreived with L<get_prop|/get_prop> or L<get_props|/get_props>.  The
list of properties below may not be complete, and not all properties
will be available for all objects.  Property names are case-sensitive.

=head3 accurateX

The X coordinate of the most accurate position information available
for the device.  The extra accuracy comes at the expense of some
additional time to gather and process information, so the information
may be slightly older than that available in L<latestX|/latestX>

=head3 accurateY

The X coordinate of the most accurate position information available
for the device.

=head3 accurateTime

The time of the last accurate position information update.

=head3 accurateContextId

The location context of the last accurate position information update.

=head3 accurateExpectedError

The expected error of the last accurate position information update,
in meters or feet depending on configuration.

=head3 latestX

The X coordinate of the latest position information available for the
device.  The speedy update comes at the expense of some accuracy, so
the information may be somewhat inaccurate and jittery.  More
accurate, but older, information is available in L<accurateX|/accurateX>

=head3 latestY

The Y coordinate of the latest position information available for the
device.

=head3 latestTime

The time of the last position information update.

=head3 latestContexId

The location context of the last position information update.

=head3 latestExpectedError

The expected error of the last accurate position information update,
in meters or feet depending on configuration.

=head3 speed

The speed the device being tracked is moving.

=head3 heading

The heading of the device being tracked.

=head1 AUTHOR

Scott Gifford E<lt>gifford@umich.eduE<gt>, E<lt>sgifford@suspectclass.comE<gt>

Copyright (C) 2005 The Regents of the University of Michigan.

See the file LICENSE included with the distribution for license
information.


=head1 SEE ALSO

L<Ekahau::Response|Ekahau::Response>, L<Ekahau::Base|Ekahau::Base>.

=cut

1;
