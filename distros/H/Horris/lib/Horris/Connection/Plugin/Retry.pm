package Horris::Connection::Plugin::Retry;
# ABSTRACT: Auto Reconnect Plugin on Horris


use Moose;
use AnyEvent::RetryTimer;
extends 'Horris::Connection::Plugin';
with 'MooseX::Role::Pluggable::Plugin';

my $timer;
sub on_connect {
    if( $timer ) {
        $timer->success;
        undef $timer;
    }
}
sub on_disconnect {
    my ($self) = @_;
    $timer ||= AnyEvent::RetryTimer->new (
            on_retry => sub {
                my ($timer) = @_;
                $self->connection->irc->connect($self->connection->server, $self->connection->port, {
                    nick => $self->connection->nickname,
                    user => $self->connection->username,
                    password => $self->connection->password,
                    timeout => 1,
                });

                $timer->retry;
            },
    );
}

__PACKAGE__->meta->make_immutable;

1;

__END__
=pod

=encoding utf-8

=head1 NAME

Horris::Connection::Plugin::Retry - Auto Reconnect Plugin on Horris

=head1 VERSION

version v0.1.2

=head1 DESCRIPTION

Auto Reconnect when Disconnected

=head1 AUTHOR

hshong <hshong@perl.kr>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by hshong.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

