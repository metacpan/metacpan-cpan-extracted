package Ekahau::Response::StopAreaTrackOK;
use base 'Ekahau::Response'; our $VERSION=Ekahau::Response::VERSION;

# Written by Scott Gifford <gifford@umich.edu>
# Copyright (C) 2004 The Regents of the University of Michigan.
# See the file LICENSE included with the distribution for license
# information.

use strict;
use warnings;

=head1 NAME

Ekahau::Response::StopAreaTrackOK - Indicates a "stop area track" command succeeded.

=head1 SYNOPSIS

This object is returned in response to a "stop area track" command,
and indicates that the command succeeded.  If the command fails, an
L<Ekahau::Response::Error|Ekahau::Response::Error> object will be returned instead.

=head1 DESCRIPTION

=head2 Constructor

Generally you will not want to construct these objects yourself; they
are created by L<Ekahau::Response|Ekahau::Response>, and use its constructor.

=head2 Methods

=cut

# Internal method
sub init
{
    warn "Created Ekahau::Response::StopAreaTrackOK object\n"
	if ($ENV{VERBOSE});
}

=head3 type ( )

Returns the string I<StopAreaTrackOK>, to identify the type of this object.

=cut

sub type
{
    'StopAreaTrackOK';
}

=head1 AUTHOR

Scott Gifford E<lt>gifford@umich.eduE<gt>, E<lt>sgifford@suspectclass.comE<gt>

Copyright (C) 2005 The Regents of the University of Michigan.

See the file LICENSE included with the distribution for license
information.


=head1 SEE ALSO

L<Ekahau::Response|Ekahau::Response>, L<Ekahau::Base|Ekahau::Base>, L<Ekahau::Response::Error|Ekahau::Response::Error>.

=cut

1;
