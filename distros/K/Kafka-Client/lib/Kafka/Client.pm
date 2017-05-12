package Kafka::Client;
BEGIN {
  $Kafka::Client::VERSION = '0.02';
}
use Moose;

use Digest::CRC qw(crc32);
use IO::Socket;

=head1 NAME

Kafka::Client - Client for LinkedIn's Kafka

=head1 WARNING

This module is almost completely untested, save that it actually gets messages
to send to Kafka. It cannot consume and might set things on fire. It might not
be encoded correctly. Patches are welcome!!!

=head1 DESCRIPTION

Kafka::Client is a client for LinkedIn's <Kafka|http://sna-projects.com/kafka/>.
It was pretty much translated directly from kafka.py that is included in the
kafka source code.

=head1 SYNOPSIS

  use Kafka::Client;

  my $kafka = Kafka::Client->new( host => '127.0.0.1' );

  my @messages = ( 'One', 'Two', 'Three' );
  my $topic = 'test';

  $kafka->send( \@messages, $topic );

=cut

my $PRODUCE_REQUEST_ID = 0;

=head1 ATTRIBUTES

=head2 host

The host to which we are connecting.

=cut

has 'host' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

=head2 port

The port to which we are connecting.  Defaults to 9092.

=cut

has 'port' => (
    is       => 'ro',
    isa      => 'Num',
    required => 1,
    default => 9092
);

has '_socket' => (
    is => 'ro',
    isa => 'IO::Socket',
    lazy_build => 1,
    handles => {
        close => 'close',
    }
);

=head1 METHODS

=cut

sub _build__socket {
    my ( $self ) = @_;
    IO::Socket::INET->new( PeerAddr => $self->host, PeerPort => $self->port );
}

=head2 send ($messags, $topic, $parition)

Send one (or many!) messages to a specitic topic.

=cut

sub send {
    my ( $self, $messages, $topic, $partition ) = @_;
    $partition ||= 0;
    $messages    = [ $messages ] if not ref $messages;

    $self->socket->send( $self->encode_produce_request( $topic, $partition, $messages ) );
}

=head2 encode_message

Encodes a message, using the following format:

=over 4

=item MAGIC_BYTE: char

=item CRC32: int

=item PAYLOAD: bytes

=back

=cut

sub encode_message {
    my ( $self, $msg ) = @_;

    return pack('C', 0) . pack('i>', crc32($msg)) . $msg;
}

=head2 encode_produce_request

=cut

sub encode_produce_request {
    my ( $self, $topic, $partition, $messages ) = @_;
    my $message_set = join('', map {
        my $encoded = $self->encode_message($_);
        pack('i>', length($encoded)) . $encoded;
    } @$messages);

    my $data = pack('n', $PRODUCE_REQUEST_ID) .
                        pack('n', length($topic)) . $topic .
                        pack('i>', $partition) .
                        pack('i>', length($message_set)) . $message_set;
    return pack('i>', length($data)) . $data;
}

=head1 AUTHOR

Cory G Watson, C<< <gphat at cpan.org> >>

=head1 CONTRIBUTORS

J. Shirley

=head1 COPYRIGHT & LICENSE

Copyright 2011 Magazines.com, LLC

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1;