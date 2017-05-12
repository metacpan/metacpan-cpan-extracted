package Hubot::Message;
$Hubot::Message::VERSION = '0.2.8';
use Moose;
use namespace::autoclean;

has 'user' => ( is => 'ro', isa => 'Hubot::User', );

has 'done' => ( is => 'rw', isa => 'Bool', default => 0, );

sub finish { shift->done(1) }

sub TO_JSON {
    my $self = shift;
    return {
        ## prvent recursive call
        ## Hubot::UserTO_JSON -> Hubot::Message::TO_JSON -> Hubot::User::TO_JSON
        user => { name => $self->user->{name}, id => $self->user->{id}, },
        done => $self->done,
    };
}

__PACKAGE__->meta->make_immutable;

1;

package Hubot::TextMessage;
$Hubot::TextMessage::VERSION = '0.2.8';
use Moose;
use namespace::autoclean;

extends 'Hubot::Message';

has 'text' => ( is => 'ro', isa => 'Str', );

sub match {
    my ( $self, $regex ) = @_;
    return $self->text =~ m/$regex/;
}

override 'TO_JSON' => sub {
    my $self = shift;
    return { %{ super() }, text => $self->text };
};

__PACKAGE__->meta->make_immutable;

1;

package Hubot::EnterMessage;
$Hubot::EnterMessage::VERSION = '0.2.8';
use Moose;
use namespace::autoclean;
extends 'Hubot::Message';
__PACKAGE__->meta->make_immutable;

1;

package Hubot::LeaveMessage;
$Hubot::LeaveMessage::VERSION = '0.2.8';
use Moose;
use namespace::autoclean;
extends 'Hubot::Message';
__PACKAGE__->meta->make_immutable;

1;

package Hubot::WhisperMessage;
$Hubot::WhisperMessage::VERSION = '0.2.8';
use Moose;
use namespace::autoclean;
extends 'Hubot::TextMessage';
__PACKAGE__->meta->make_immutable;

1;

package Hubot::NoticeMessage;
$Hubot::NoticeMessage::VERSION = '0.2.8';
use Moose;
use namespace::autoclean;
extends 'Hubot::TextMessage';
__PACKAGE__->meta->make_immutable;

1;

package Hubot::CatchAllMessage;
$Hubot::CatchAllMessage::VERSION = '0.2.8';
use Moose;
use namespace::autoclean;
extends 'Hubot::Message';

has 'message' => ( is => 'ro', isa => 'Hubot::Message' );

__PACKAGE__->meta->make_immutable;

1;

=pod

=encoding utf-8

=head1 NAME

Hubot::Message

=head1 VERSION

version 0.2.8

=head1 SYNOPSIS

    my $msg = Hubot::Message->new(
        user => $user    # $user is Hubot::User
    );

    $msg = Hubot::TextMessage->new(
        user => $user    # $user is Hubot::User
        text => 'hi'
    );

    $msg->finish;    # this message is processed.
                     # Hubot::Script::* will ignore this message.

=head1 DESCRIPTION

Hubot::Adapter::* will make L<Hubot::Message> stand on input.

=head1 AUTHOR

Hyungsuk Hong <hshong@perl.kr>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Hyungsuk Hong.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
