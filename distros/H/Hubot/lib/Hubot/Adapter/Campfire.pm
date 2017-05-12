package Hubot::Adapter::Campfire;
$Hubot::Adapter::Campfire::VERSION = '0.2.8';
use Moose;
use namespace::autoclean;

extends 'Hubot::Adapter';

use AnyEvent;
use AnyEvent::HTTP;
use AnyEvent::Campfire::Client;
use JSON::XS;
use Encode 'encode_utf8';
use HTTP::Request;
use LWP::UserAgent;
use Try::Tiny;

use Hubot::Message;

has 'robot' => ( is => 'ro', isa => 'Hubot::Robot', );

has 'cv' => ( is => 'ro', lazy_build => 1, );

has 'bot' => ( is => 'rw', );

has 'httpClient' => ( is => 'ro', default => sub { LWP::UserAgent->new }, );

sub _build_cv { AnyEvent->condvar }

sub send {
    my ( $self, $user, @strings ) = @_;
    $self->bot->speak( $user->{room}, encode_utf8($_) ) for @strings;
}

sub reply {
    my ( $self, $user, @strings ) = @_;
    @strings = map { $user->{name} . ": $_" } @strings;
    $self->send( $user, @strings );
}

sub run {
    my $self = shift;

    my %options = (
        token   => $ENV{HUBOT_CAMPFIRE_TOKEN},
        rooms   => $ENV{HUBOT_CAMPFIRE_ROOMS},
        account => $ENV{HUBOT_CAMPFIRE_ACCOUNT},
    );

    $self->cv->begin;

    my $bot = AnyEvent::Campfire::Client->new(%options);
    $bot->on(
        'join',
        sub {
            my ( $e, $data ) = @_;
            $self->receive( new Hubot::EnterMessage );
        }
    );

    $bot->on(
        'message',
        sub {
            my ( $e, $data ) = @_;
            my $user = $self->userForId( $data->{user_id},
                { room => $data->{room_id}, } );

            if ( $user->{name} eq $user->{id} ) {
                my $req = HTTP::Request->new(
                    GET => sprintf(
                        "https://%s.campfirenow.com/users/%s",
                        $options{account}, $user->{id}
                    ),
                );
                $req->header( 'Accept',        'application/json' );
                $req->header( 'Authorization', $bot->authorization );
                my $res = $self->httpClient->request($req);    # non-async
                return unless $res->is_success;

                my $userData;
                try {
                    $userData = decode_json( $res->content );
                }
                catch {
                    $bot->emit( 'error', $_ );
                };

                $user->{name} = $userData->{user}{name};
            }

            ## TODO: support EnterMessage, LeaveMessage
            $self->receive(
                new Hubot::TextMessage(
                    user => $user,
                    text => $data->{body},
                )
            );
        }
    );

    $bot->on(
        'error',
        sub {
            my ( $e, $error ) = @_;
            print STDERR "$error\n";
        }
    );

    $bot->on(
        'leave',
        sub {
            $self->cv->send;    # TODO: support multiple rooms `leave`
        }
    );

    $self->bot($bot);
    $self->emit('connected');
    $self->cv->recv;
}

sub close {
    my $self = shift;
    $self->bot->exit;
}

__PACKAGE__->meta->make_immutable;

1;

=pod

=encoding utf-8

=head1 NAME

Hubot::Adapter::Campfire - Campfire adapter for L<Hubot>

=head1 VERSION

version 0.2.8

=head1 SYNOPSIS

    $ export HUBOT_CAMPFIRE_TOKEN='xxxx'
    $ export HUBOT_CAMPFIRE_ROOMS='1234'
    $ export HUBOT_CAMPFIRE_ACCOUNT='aanoaa'
    $ hubot -a campfire

=head1 DESCRIPTION

Campfire is the web based chat application built by L<37 Signals|http://37signals.com/>.
The Campfire adapter is one of the original adapters in Hubot.

=head1 CONFIGURATION

=over

=item HUBOT_CAMPFIRE_TOKEN

This can be found by logging in with your hubot's account click the My Info link and make a note of the API token.

=item HUBOT_CAMPFIRE_ROOMS

If you join the rooms you want your hubot to join will see notice a numerical ID for the room in the URL. Make a note of each ID for the rooms you want your hubot to join.

=item HUBOT_CAMPFIRE_ACCOUNT

This is simply the first part of the domain you visit for your Campfire account. For example if your Campfire was at C<hubot.campfirenow.com> your subdomain is hubot. Make a note of the subdomain.

=back

=head1 SEE ALSO

=over

=item L<https://github.com/37signals/campfire-api#authentication>

=item L<https://github.com/github/hubot/wiki/Adapter:-Campfire>

=back

=head1 AUTHOR

Hyungsuk Hong <hshong@perl.kr>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Hyungsuk Hong.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
