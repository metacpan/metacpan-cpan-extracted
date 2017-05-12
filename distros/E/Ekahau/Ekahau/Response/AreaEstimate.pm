package Ekahau::Response::AreaEstimate;
use base 'Ekahau::Response::AreaList'; our $VERSION=Ekahau::Response::AreaList::VERSION;

# Written by Scott Gifford <gifford@umich.edu>
# Copyright (C) 2004 The Regents of the University of Michigan.
# See the file LICENSE included with the distribution for license
# information.

use strict;
use warnings;

=head1 NAME

Ekahau::Response::AreaEstimate - A list of areas where a tracked object may be

=head1 SYNOPSIS

Contains information about the areas where a tracked object might be.
This class inherits both L<Ekahau::Response|Ekahau::Response> and L<Ekahau::Response::AreaList|Ekahau::Response::AreaList>,
and methods from both classes can be used on this object.  It's likely
that the L<Ekahau::Response::AreaList::get|Ekahau::Response::AreaList/get> and
L<Ekahau::Response::AreaList::get_all|Ekahau::Response::AreaList/get_all> methods will prove useful.

=head1 DESCRIPTION

=head2 Constructor

Generally you will not want to construct these objects yourself; they
are created by L<Ekahau::Response|Ekahau::Response>, and use its constructor.

=head2 Methods

=cut

# Internal method
sub init
{
    my $self = shift;
    warn "Created Ekahau::Response::AreaEstimate object\n"
	if ($ENV{VERBOSE});
    $self->SUPER::init(@_);
}


=head3 get_props ( @which_props )

Gets the properties of the first L<Ekahau::Area|Ekahau::Area> object in the list,
using L<Ekahau::Area::get_props|Ekahau::Area/get_props>.  This convenience method is provided
because the first area is the most likely location of the device, and
because it's common to request only one area.

=cut

sub get_props
{
    my $self = shift;

    # Get properties for first estimate
    $self->{_areas}[0]->get_props(@_);
}

=head3 get_prop ( $which_prop )

Gets the properties of the first L<Ekahau::Area|Ekahau::Area> object in the list,
using L<Ekahau::Area::get_prop|Ekahau::Area/get_prop>.  This convenience method is provided
because the first area is the most likely location of the device, and
because it's common to request only one area.

=cut

sub get_prop
{
    my $self = shift;

    # Get property for first estimate
    $self->{_areas}[0]->get_prop(@_);
}

=head3 type ( )

Returns the string I<AreaEstimate>, to identify the type of this
object.  Note that subclasses of this class will override this method,
returning their own type string.

=cut

sub type
{
    'AreaEstimate';
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
