package Eve::Event::HttpResponseReady;

use parent qw(Eve::Event);

use strict;
use warnings;

=head1 NAME

B<Eve::Event::HttpResponseReady> - HTTP response ready.

=head1 SYNOPSIS

    use Eve::Event::HttpResponseReady;

    Eve::Event::HttpResponseReady->new(
        event_map => $event_map,
        response => $http_response);

=head1 DESCRIPTION

B<Eve::Event::HttpResponseReady> is an event assumed to signal when
an HTTP response is ready to be sent.

=head3 Attributes

=over 4

=item C<response>

an HTTP response object.

=back

=head3 Constructor arguments

=over 4

=item C<event_map>

an event map object

=item C<response>

an HTTP response object.

=back

=head1 METHODS

=head2 B<init()>

=cut

sub init {
    my ($self, %arg_hash) = @_;
    Eve::Support::arguments(\%arg_hash, my ($event_map, $response));

    $self->{'response'} = $response;

    $self->SUPER::init(event_map => $event_map);

    return;
}

=head1 LICENSE AND COPYRIGHT

Copyright 2012 Igor Zinovyev.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=head1 AUTHOR

=over 4

=item L<Sergey Konoplev|mailto:gray.ru@gmail.com>

=back

=cut

1;
