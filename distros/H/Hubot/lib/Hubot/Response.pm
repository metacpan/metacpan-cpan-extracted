package Hubot::Response;
$Hubot::Response::VERSION = '0.2.8';
use Moose;
use namespace::autoclean;

has 'robot' => ( is => 'ro', isa => 'Hubot::Robot', );

has 'message' => ( is => 'rw', isa => 'Hubot::Message', );

has 'match' => ( is => 'rw', isa => 'ArrayRef' );

sub send {
    my ( $self, @strings ) = @_;
    $self->robot->adapter->send( $self->message->user, @strings );
}

sub whisper {
    my ( $self, $to, @strings ) = @_;
    $self->robot->adapter->whisper( $self->message->user, $to, @strings );
}

sub topic {
    my ( $self, @strings ) = @_;
    $self->robot->adapter->topic( $self->message->user, @strings );
}

sub reply {
    my ( $self, @strings ) = @_;
    $self->robot->adapter->reply( $self->message->user, @strings );
}

sub random {
    my ( $self, @items ) = @_;
    return $items[rand( scalar(@items) )];
}

sub finish {
    my $self = shift;
    $self->message->finish();
}

sub http {
    my ( $self, $url ) = @_;
    return $self->robot->http($url);
}

sub exist {
    my ( $self, $nick ) = @_;
    $self->robot->adapter->exist( $self->message->user, $nick );
}

__PACKAGE__->meta->make_immutable;

1;

=pod

=encoding utf-8

=head1 NAME

Hubot::Response

=head1 VERSION

version 0.2.8

=head1 SYNOPSIS

    ## generally Hubot::Response used to Hubot::Script::* callback.
    ## assume this is a callback subroutine.
    $robot->hear(
        qr/echo (.+)/i,
        sub {
            my $res = shift;
            $res->reply($res->match->[0]); # aanoaa> echo 123
                                           #  hubot> aanoaa: 123
        }
    );

=head1 DESCRIPTION

Interface between C<Hubot::Script::*> callback and C<Hubot::Adapter::*>

=head1 AUTHOR

Hyungsuk Hong <hshong@perl.kr>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Hyungsuk Hong.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
