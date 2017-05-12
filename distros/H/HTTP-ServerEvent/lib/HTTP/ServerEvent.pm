package HTTP::ServerEvent;
use strict;
use Carp qw( croak );

use vars qw($VERSION);
$VERSION = '0.02';

=head1 NAME

HTTP::ServerEvent - create strings for HTTP Server Sent Events

=cut

=head2 C<< ->as_string( %options ) >>

  return HTTP::ServerEvent->as_string(
    event => "ping",
    data => time(),
    retry => 5000, # retry in 5 seconds if disconnected
    id => $counter++,
  );

Returns a string that can be sent as a server-sent event
through the socket.

The allowed options are:

=over 4

=item *

C<event> - the type of event (optional). This is the
event type you will want to listen to on the other side.
Newlines or null characters in the event type are
treated as a fatal error.

=item *

C<data> - the data to be sent. This can be either a string
or an array reference of strings. Note that embedded newlines
(either C<\x{0d}> , C<\x{0a}> or C<\x{0d}\x{0a}> ) will
be interpreted as newlines and be normalized to the C<\x{0d}\x{0a}>
pairs that are sent over the wire.

=item *

C<id> - the event id. If you send this, a client will send the
C<Last-Event-Id> header when reconnecting, allowing you to send
the events missed while offline.
Newlines or null characters in the event id are
treated as a fatal error.

=item *

C<retry> - the amount of miliseconds to wait before reconnecting
if the connection is lost.
Newlines or null characters in the retry interval are
treated as a fatal error.

=back

=cut

sub as_string {
    my ($self, %options) = @_;
    
    # Better be on the safe side
    for my $key (qw( event id retry )) {
        croak "Newline or null detected in event type '$options{ $key }'. Possible event injection."
            if defined $options{ $key } and $options{ $key } =~ /[\x0D\x0A\x00]/;
    };
    
    if( !$options{ data }) {
        $options{ data }= [];
    };
    $options{ data } = [ $options{ data }]
        unless 'ARRAY' eq ref $options{ data };
    
    my @result;
    if( defined $options{ event }) {
        push @result, "event: $options{ event }";
    };
    if(defined $options{ id }) {
        push @result, "id: $options{ id }";
    };
    
    if( defined $options{ retry }) {
        push @result, "retry: $options{ retry }";
    };
    
    push @result, map {"data: $_" }
                  map { split /(?:\x0D\x0A?|\x0A)/ }
                  @{ $options{ data } || [] };
    
    return ((join "\x0D\x0A", @result) . "\x0D\x0A\x0D\x0A")
};

1;

=head1 Javascript EventSource object

To receive events on the other side, usually in a browser,
you will want to instantiate an C<EventSource> object.

  var events = new EventSource('/events');
  // Subscribe to "tick" event
  events.addEventListener('tick', function(event) {
    var out= document.getElementById("my_console");
    out.appendChild(document.createTextNode(event.data));
  }, false);


=head1 Last-Event-Id Header

If you're sending events, you may want to look at the C<< Last-Event-Id >>
HTTP header. This header is sent by the C<EventSource> object when
reestablishing a connection that was intermittently lost. You can use this
to bring the reconnecting client up to date with the current state
instead of transmitting the complete state.

=head1 SEE ALSO

L<https://developer.mozilla.org/en-US/docs/Server-sent_events/Using_server-sent_events>

L<https://hacks.mozilla.org/2011/06/a-wall-powered-by-eventsource-and-server-sent-events/>

L<http://www.html5rocks.com/en/tutorials/eventsource/basics/?ModPagespeed=noscript>

=head1 REPOSITORY

The public repository of this module is 
L<http://github.com/Corion/http-serverevent>.

=head1 SUPPORT

The public support forum of this module is
L<http://perlmonks.org/>.

=head1 BUG TRACKER

Please report bugs in this module via the RT CPAN bug queue at
L<https://rt.cpan.org/Public/Dist/Display.html?Name=HTTP-ServerEvent>
or via mail to L<http-serverevent-Bugs@rt.cpan.org>.

=head1 AUTHOR

Max Maischein C<corion@cpan.org>

=head1 COPYRIGHT (c)

Copyright 2013-2013 by Max Maischein C<corion@cpan.org>.

=head1 LICENSE

This module is released under the same terms as Perl itself.

=cut