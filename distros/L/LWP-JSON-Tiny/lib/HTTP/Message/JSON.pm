package HTTP::Message::JSON;

use strict;
use warnings;
no warnings 'uninitialized';

our $VERSION = $LWP::JSON::Tiny::VERSION;

=head1 NAME

HTTP::Message::JSON - a very simple superclass for JSON HTTP messages

=head1 DESCRIPTION

This is a very simple superclass used by HTTP::Request::JSON and
HTTP::Response::JSON. It overrides the default behaviour of the HTTP::Headers
method content_is_text.

=head2 content_is_text

Returns TRUE if this is a message with content type application/json.
Otherwise uses the default behaviour of HTTP::Headers.

=cut

sub content_is_text {
    my ($self) = @_;

    if ($self->content_type eq 'application/json') {
        return 1;
    } else {
        return HTTP::Headers::content_is_text($self);
    }
}

1;