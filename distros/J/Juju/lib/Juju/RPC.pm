package Juju::RPC;
BEGIN {
  $Juju::RPC::AUTHORITY = 'cpan:ADAMJS';
}
$Juju::RPC::VERSION = '2.002';
# ABSTRACT: RPC Class


use Moose::Role;
use AnyEvent;
use AnyEvent::WebSocket::Client;
use JSON::PP;
use Function::Parameters;

has conn         => (is => 'rw');
has result       => (is => 'rw');
has is_connected => (is => 'rw');
has done         => (is => 'rw');
has request_id   => (is => 'rw', isa => 'Int', default => 1);

method BUILD {
    my $client = AnyEvent::WebSocket::Client->new(ssl_no_verify => 1);
    $self->conn($client->connect($self->endpoint)->recv);
    $self->is_connected(1);

    $self->conn->on(
        each_message => sub {
            my ($conn, $message) = @_;
            my $body = decode_json($message->decoded_body);
            if (defined($body->{Response})) {
                $self->done->send($body);
            }
        }
    );
}

method close {
    $self->conn->close;
}


method call($params, $cb = undef) {
    $self->done(AnyEvent->condvar);

    # Increment request id
    $self->request_id($self->request_id + 1);
    $params->{RequestId} = $self->request_id;
    $self->conn->send(encode_json($params));

    # non-blocking
    return $cb->($self->done->recv) if $cb;

    # blocking
    return $self->done->recv;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Juju::RPC - RPC Class

=head1 VERSION

version 2.002

=head1 DESCRIPTION

Contains methods and attributes not meant to be accessed directly but
utilized by the exposed API.

=head1 ATTRIBUTES

=head2 conn

Connection object

=head2 request_id

An incremented ID based on how many requests performed on the connection.

=head2 is_connected

Check if a websocket connection exists

=head1 METHODS

=head2 close

Close connection

=head2 call

Sends event to juju api server, this is the entrypoint for all api calls. If an
B<error> occurs it will return a response object of:

  {
    Error => 'Error message',
    RequestId => 1,
    Response => {}
  }

Otherwise, successful queries will return:

  {
    Response => { some_successful => 'hash' }
    RequestId => 1
  }

B<Params>

=over 4

=item *

C<params>

Hash of request parameters

=item *

C<cb>

(optional) callback for non-blocking operations

=back

=head1 AUTHOR

Adam Stokes <adamjs@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2014 by Adam Stokes.

This is free software, licensed under:

  The MIT (X11) License

=head1 SEE ALSO

Please see those modules/websites for more information related to this module.

=over 4

=item *

L<Juju|Juju>

=back

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT
WHEN OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER
PARTIES PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND,
EITHER EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
PURPOSE. THE ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE
SOFTWARE IS WITH YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME
THE COST OF ALL NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE LIABLE
TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE THE
SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH
DAMAGES.

=cut
