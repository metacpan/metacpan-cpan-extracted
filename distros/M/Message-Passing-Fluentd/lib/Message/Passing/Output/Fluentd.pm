package Message::Passing::Output::Fluentd;

use Moo;
use namespace::autoclean;
use Try::Tiny;
use JSON::MaybeXS qw( decode_json );
use Message::Passing::Exception::Decoding;

with qw(
  Message::Passing::Fluentd::Role::HasAConnection
  Message::Passing::Role::Output
);

has tag => ( is => 'ro', default => sub { 'app_log'  });

sub consume {
  my ($self, $msg) = @_;
  $msg = try {
    ref($msg) ? $msg : decode_json($msg)
  } catch {
    $self->error->consume(Message::Passing::Exception::Decoding->new(
      exception => $_,
      packed_data => $msg,
    ));
    return; # Explicit return undef
  };
  $self->connection_manager->connection->post(
    delete($msg->{'tag'}) || $self->tag,
    $msg
  );
}

sub connected {}

1;

__END__

=encoding utf-8

=head1 NAME

Message::Passing::Fluentd - A fluentd publisher for Message::Passing

=head1 SYNOPSIS

  $ message-pass --input STDIN --output Fluentd --output_options '{"hostname":"127.0.0.1","port":"24224"}'

=head1 DESCRIPTION

A simple message output which publishes messages to a fluentd.

=head1 ATTRIBUTES

=head2 hostname

The hostname of the fluentd server. Required.

=head2 port

The port number of the fluentd server. Defaults to 24224.

=head1 AUTHOR

Wallace Reis E<lt>wallace@reis.meE<gt>

=head1 COPYRIGHT

Copyright 2018- Wallace Reis

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

=cut
