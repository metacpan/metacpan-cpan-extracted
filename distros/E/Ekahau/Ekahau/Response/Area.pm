package Ekahau::Response::Area;
use base 'Ekahau::Response'; our $VERSION=Ekahau::Response::VERSION;

# Written by Scott Gifford <gifford@umich.edu>
# Copyright (C) 2004 The Regents of the University of Michigan.
# See the file LICENSE included with the distribution for license
# information.

use strict;
use warnings;

=head1 NAME

Ekahau::Response::Area - Represents a single area contained in an Ekahau response

=head1 SYNOPSIS

Contains information about a single area, generally from an
L<Ekahau::Response::AreaList|Ekahau::Response::AreaList> or L<Ekahau::Response::AreaEstimate|Ekahau::Response::AreaEstimate>
object.  Generally you'll be interested in the L<Properties|/Properties>.

=head1 DESCRIPTION

=head2 Constructor

Generally you will not want to construct these objects yourself; they
are created by L<Ekahau::Response|Ekahau::Response>, and use its constructor.

=head2 Methods

=cut

# Internal function
sub init
{
    warn "Created Ekahau::Response::Area object\n"
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

Returns the string I<Area>, to identify the type of this object.

=cut

sub type
{
    'Area';
}

=head2 Properties

Properties can be retreived with L<get_prop|/get_prop> or L<get_props|/get_props>.  The
list of properties below may not be complete, and not all properties
will be available for all objects.  Property names are case-sensitive.

=head3 name

The name of the area.

=head3 contextId

Identifies the I<location context>, which can be used to obtain more
information about this area with L<Ekahau::get_location_context|Ekahau::get_location_context> or
L<Ekahau::Base::request_location_context|Ekahau::Base::request_location_context>.

=head3 polygon

A string representing the vertices of the polygon containing this
area.  The format is:

    x1;x2;x3&y1;y2;y3

where the points are I<(x1,y1)>, I<(x2,y2)>, and I<(x3, y3)>.

=head3 probability

For areas obtained from L<Ekahau::Response::AreaEstimate|Ekahau::Response::AreaEstimate> objects,
contains the probability that the tracked device is in this area.

=head1 AUTHOR

Scott Gifford E<lt>gifford@umich.eduE<gt>, E<lt>sgifford@suspectclass.comE<gt>

Copyright (C) 2005 The Regents of the University of Michigan.

See the file LICENSE included with the distribution for license
information.


=head1 SEE ALSO

L<Ekahau::Response|Ekahau::Response>.

=cut


1;
