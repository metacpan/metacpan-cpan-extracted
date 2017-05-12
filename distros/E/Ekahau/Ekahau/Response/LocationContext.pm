package Ekahau::Response::LocationContext;
use base 'Ekahau::Response'; our $VERSION=Ekahau::Response::VERSION;

# Written by Scott Gifford <gifford@umich.edu>
# Copyright (C) 2004 The Regents of the University of Michigan.
# See the file LICENSE included with the distribution for license
# information.

use strict;
use warnings;

=head1 NAME

Ekahau::Response::LocationContex - Contains an Ekahau I<location context>, with information about a location

=head1 SYNOPSIS

Ekahau uses I<location contexts> to refer to information about a
location returned in an L<Ekahau::Response::AreaList|Ekahau::Response::AreaList> or
L<Ekahau::Response::AreaEstimate|Ekahau::Response::AreaEstimate>.  When you request information about
a specific location context, this is the response you'll get.

=head1 DESCRIPTION

=head2 Constructor

Generally you will not want to construct these objects yourself; they
are created by L<Ekahau::Response|Ekahau::Response>, and use its constructor.

=head2 Methods

=cut

# Internal method
sub init
{
    warn "Created Ekahau::Response::LocationContext object\n"
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


=head3 context_id ( )

Returns the identifier for this location context.

=cut

sub context_id
{
    my $self = shift;
    
    return $self->{args}[0];
}

=head3 type ( )

Returns the string I<LocationContext>, to identify the type of this object.

=cut

sub type { 'LocationContext' }

=head2 Properties

Properties can be retreived with L<get_prop|/get_prop> or L<get_props|/get_props>.  The
list of properties below may not be complete, and not all properties
will be available for all objects.  Property names are case-sensitive.

=head3 address

A short text string describing this location.

=head3 mapScale

The scale of the map used for this location, in pixels/meter of
pixels/foot (depending on configuration).


=head1 AUTHOR

Scott Gifford E<lt>gifford@umich.eduE<gt>, E<lt>sgifford@suspectclass.comE<gt>

Copyright (C) 2005 The Regents of the University of Michigan.

See the file LICENSE included with the distribution for license
information.


=head1 SEE ALSO

L<Ekahau::Response|Ekahau::Response>, L<Ekahau::Base|Ekahau::Base>, L<Ekahau::Response::Area|Ekahau::Response::Area>.

=cut

1;
