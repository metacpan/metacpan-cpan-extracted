package Email::Sender::Transport::QMQP;
{
  $Email::Sender::Transport::QMQP::VERSION = '0.001';
}
# ABSTRACT: send mail via QMQP

use Moose;
with 'Email::Sender::Transport';


has 'host' => (is  => 'ro',
               isa => 'Str',
               required => 1,
               default  => sub { 'localhost' });

has 'port' => (is  => 'ro',
               isa => 'Str',
               required => 1,
               default  => sub { 628 });


sub send_email {
    my ($self, $email, $envelope) = @_;

    my $socket;
    if ($self->port =~ m,^/,) {
        require IO::Socket::UNIX;
        $socket = IO::Socket::UNIX->new (Peer => $self->port) or Email::Sender::Failure->throw ("Couldn't connect to qmqp socket at " . $self->port . ", " . $!);
    } else {
        require IO::Socket::INET;
        $socket = IO::Socket::INET->new (PeerAddr => $self->host, PeerPort => $self->port) or Email::Sender::Failure->throw ("Couldn't connect to qmqp socket at " . join (':', $self->host, $self->port) . ", " . $!);
    }

    my $payload = join '', map {sprintf "%d:%s,", length $_, $_} $email->as_string, $envelope->{from}, @{$envelope->{to}};
    $socket->printf ('%d:%s,', length $payload, $payload) or Email::Sender::Failure->throw ("Couldn't send message via socket: $!");

    my $response = $socket->getline;

    if (my ($length, $code, $detail) = $response =~ m/^(\d+):(\S)(.+),$/) {
        if ($code eq "K") {
            $self->success;
        } else {
            my $class = join '::', 'Email::Sender::Failure', ($detail eq "D" ? 'Permanent' : 'Temporary');
            $class->throw ('Transmission failed: ' . $detail);
        }
    } else {
        Email::Sender::Failure::Temporary->throw ("Bad response from server: $response");
    }
}

__PACKAGE__->meta->make_immutable;
no Moose;

1;

__END__
=pod

=head1 NAME

Email::Sender::Transport::QMQP - send mail via QMQP

=head1 VERSION

version 0.001

=head1 METHODS

=head2 send_email

We connect to the QMQP service wherever specified, format the email
and envelope information as appropriate, send it, then look for and
parse the response, passing along the results appropriately.

=head2 DESCRIPTION

This transport sends mail by connecting to a host implementing the
C<QMQP> protocol (generally running either C<qmail> or C<postfix>).

If the hostname or the port of the C<QMQP> server host is not provided
in the constructor (see below) then the library will try
C<localhost:628>

To specify the QMQP server location, use the port and host parameters:

  my $sender = Email::Sender::Transport::QMQP->new({ host => $host, port => $port });

If host is set to an absolute file path (starting with '/'), it's
assumed to be a Unix socket path, and is connected to accordingly.

=head1 AUTHOR

Michael Alan Dorman <mdorman@ironicdesign.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Ironic Design, Inc..

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

