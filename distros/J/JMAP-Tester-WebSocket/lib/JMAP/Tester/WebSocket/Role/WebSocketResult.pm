use v5.10.0;
use warnings;

package JMAP::Tester::WebSocket::Role::WebSocketResult 0.002;
# ABSTRACT: the kind of thing that you get back for a WebSocket request

use Moo::Role;

with 'JMAP::Tester::Role::Result';

#pod =head1 OVERVIEW
#pod
#pod This is the role consumed by the class of any object returned by
#pod L<JMAP::Tester::WebSocket>'s C<request> method.
#pod
#pod =cut

has ws_response => (
  is => 'ro',
);

#pod =method response_payload
#pod
#pod Returns the raw payload of the response, if there is one. Empty string
#pod otherwise.
#pod
#pod =cut

sub response_payload {
  my ($self) = @_;

  return $self->ws_response || '';
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

JMAP::Tester::WebSocket::Role::WebSocketResult - the kind of thing that you get back for a WebSocket request

=head1 VERSION

version 0.002

=head1 OVERVIEW

This is the role consumed by the class of any object returned by
L<JMAP::Tester::WebSocket>'s C<request> method.

=head1 METHODS

=head2 response_payload

Returns the raw payload of the response, if there is one. Empty string
otherwise.

=head1 AUTHOR

Matthew Horsfall <wolfsage@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by FastMail, Ltd.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
