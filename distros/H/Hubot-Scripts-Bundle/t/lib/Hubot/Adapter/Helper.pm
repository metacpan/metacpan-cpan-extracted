package Hubot::Adapter::Helper;
use Moose;
use namespace::autoclean;

extends 'Hubot::Adapter';

use AnyEvent;
use Encode 'decode_utf8';
use Hubot::Message;

has 'robot' => (
    is  => 'ro',
    isa => 'Hubot::Robot',
);

has 'cv' => (
    is         => 'ro',
    lazy_build => 1,
);

has 'interval' => (
    is      => 'rw',
    default => 1,
);

sub BUILD {
    my $self = shift;
    $self->robot->{sent}    = [];
    $self->robot->{receive} = [];
}

sub _build_cv { AnyEvent->condvar }
sub close     { shift->cv->send }

sub send {
    my ( $self, $user, @strings ) = @_;
    push @{ $self->robot->{sent} }, \@strings;
    $self->cv->end;
}

sub reply {
    my ( $self, $user, @strings ) = @_;
    @strings = map { $user->{name} . ": $_" } @strings;
    $self->send( $user, @strings );
}

sub exist {
    my ( $self, $user, $nick ) = @_;
    return $self->userForName($nick);
}

sub run {
    my $self = shift;

    local $| = 1;
    my $w = AnyEvent->timer(
        after    => 0,
        interval => $self->interval,
        cb       => sub {
            my $text = shift @{ $self->robot->{receive} };
            return $self->cv->end unless $text;

            $self->cv->begin;
            my $user = $self->userForId(
                1,
                {
                    name => 'helper',
                    room => 'helper'
                }
            );

            $self->receive(
                new Hubot::TextMessage(
                    {
                        user => $user,
                        text => $text,
                    }
                )
            );
        }
    );

    $self->cv->begin;
    $self->cv->recv;

    # callback?
}

__PACKAGE__->meta->make_immutable;

1;
