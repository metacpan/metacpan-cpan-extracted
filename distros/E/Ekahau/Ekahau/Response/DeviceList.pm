package Ekahau::Response::DeviceList;
use base 'Ekahau::Response'; our $VERSION=Ekahau::Response::VERSION;

# Written by Scott Gifford <gifford@umich.edu>
# Copyright (C) 2004 The Regents of the University of Michigan.
# See the file LICENSE included with the distribution for license
# information.

use strict;
use warnings;

=head1 NAME

Ekahau::Response::DeviceList - A list of devices visible to Ekahau

=head1 SYNOPSIS

Contains a list of devices visible to Ekahau.  This response only
contains the device identifiers, and no other information about the
devices.  This class inherits from L<Ekahau::Response|Ekahau::Response> , and methods
that class can be used on this object.

=head1 DESCRIPTION

=head2 Constructor

Generally you will not want to construct these objects yourself; they
are created by L<Ekahau::Response|Ekahau::Response>, and use its constructor.

=head2 Methods

=cut

# Internal method
sub init
{
    warn "Created Ekahau::Response::DeviceList object\n"
	if ($ENV{VERBOSE});
}

=head3 devices ( )

Returns the list of device identifiers contained in this response.

=cut

sub devices
{
    my $self = shift;
    keys %{$self->{params}};
}

=head3 type ( )

Returns the string I<DeviceList>, to identify the type of this object.

=cut

sub type
{
    'DeviceList';
}

=head1 AUTHOR

Scott Gifford E<lt>gifford@umich.eduE<gt>, E<lt>sgifford@suspectclass.comE<gt>

Copyright (C) 2005 The Regents of the University of Michigan.

See the file LICENSE included with the distribution for license
information.


=head1 SEE ALSO

L<Ekahau::Response|Ekahau::Response>, L<Ekahau::DeviceProperties|Ekahau::DeviceProperties>, L<Ekahau::Base|Ekahau::Base>.

=cut

1;
