package Ekahau::Response::MapImage;
use base 'Ekahau::Response'; our $VERSION=Ekahau::Response::VERSION;

# Written by Scott Gifford <gifford@umich.edu>
# Copyright (C) 2004 The Regents of the University of Michigan.
# See the file LICENSE included with the distribution for license
# information.

use strict;
use warnings;

=head1 NAME

Ekahau::Response::MapImage - Contains a map of a location

=head1 SYNOPSIS

Ekahau stores a map of the areas it can find locations in, and this
object contains one of those maps.  The maps are simply a bitmap image
of the area, and are encoded in PNG format.

=head1 DESCRIPTION

=head2 Constructor

Generally you will not want to construct these objects yourself; they
are created by L<Ekahau::Response|Ekahau::Response>, and use its constructor.

=head2 Methods

=cut

# Internal
sub init
{
    warn "Created Ekahau::Response::MapImage object\n"
	if ($ENV{VERBOSE});
}

=head3 map_size ( )

Returns the size of the map image in bytes.

=cut

sub map_size ( )
{
    my $self = shift;
    return $self->{params}{size};
}

=head3 map_type ( )

Returns the data type of the map image.  At the time of this writing,
this is always C<png>.

=cut

sub map_type
{ 
    my $self = shift;
    return $self->{params}{type};
}

=head3 map_image ( )

Returns the data for this map, in PNG format.

=cut

sub map_image
{
    my $self = shift;
    return $self->{params}{data};
}

=head3 type ( )

Returns the string I<MapImage>, to identify the type of this object.

=cut

sub type
{
    'MapImage';
}

=head1 AUTHOR

Scott Gifford E<lt>gifford@umich.eduE<gt>, E<lt>sgifford@suspectclass.comE<gt>

Copyright (C) 2005 The Regents of the University of Michigan.

See the file LICENSE included with the distribution for license
information.


=head1 SEE ALSO

L<Ekahau::Response|Ekahau::Response>, L<Ekahau::Base|Ekahau::Base>.

=cut

1;
