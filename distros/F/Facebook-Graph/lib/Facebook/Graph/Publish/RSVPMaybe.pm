package Facebook::Graph::Publish::RSVPMaybe;
$Facebook::Graph::Publish::RSVPMaybe::VERSION = '1.1205';
use Moo;
extends 'Facebook::Graph::Publish';

use constant object_path => '/maybe';

1;

=head1 NAME

Facebook::Graph::Publish::RSVPMaybe - RSVP maybe to an event.

=head1 VERSION

version 1.1205

=head1 SYNOPSIS

 my $fb = Facebook::Graph->new;

 $fb->rsvp_maybe($event_id)
    ->publish;

=head1 DESCRIPTION

RSVP's "Maybe" to an event.

B<ATTENTION:> You must have the C<rsvp_event> privilege to use this module.

=head1 METHODS


=head2 publish ( )

Posts the data and returns a L<Facebook::Graph::Response> object. The response object should contain a string of either 'true' or 'false'.

=head1 LEGAL

Facebook::Graph is Copyright 2010 - 2017 Plain Black Corporation (L<http://www.plainblack.com>) and is licensed under the same terms as Perl itself.

=cut
