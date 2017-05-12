package LiBot::Provider::IRC;
use strict;
use warnings;
use utf8;
use AnyEvent::IRC::Client;
use Encode qw(decode encode);

use Mouse;

has irc => (
    is => 'rw',
);

has [qw(host port)] => (
    is => 'ro',
    required => 1,
);

has nick => (
    is => 'ro',
    default => sub { 'libot' },
);

has encoding => (
    is => 'ro',
    default => sub { 'utf-8' },
);

has channels => (
    is => 'rw',
);

no Mouse;

sub _connect {
    my ($self, $bot) = @_;

    my $irc = AnyEvent::IRC::Client->new;
    $irc->reg_cb(
        connect => sub {
            my ( $con, $err ) = @_;
            if ( defined $err ) {
                warn "connect error: $err\n";
                return;
            }
            for (@{Data::OptList::mkopt($self->channels)}) {
                $con->send_srv(JOIN => $_->[0], $_->[1]->{key});
            }
        }
    );
    $irc->reg_cb( registered => sub { print "I'm in!\n"; } );
    $irc->reg_cb( disconnect => sub {
        print "I'm out!\n";
        $self->_connect($bot);
    } );
    $irc->reg_cb(
        publicmsg => sub {
            my ( $irc, $channel, $msg ) = @_;
            my $text = decode( $self->encoding, $msg->{params}->[1] );
            my ( $nickname, ) = split '!', ( $msg->{prefix} || '' );
            my $message = LiBot::Message->new(
                text     => $text,
                nickname => $nickname,
            );
            my $proceeded = eval {
                $bot->handle_message(
                    sub {
                        warn $_[0];
                        for (grep /\S/, split /\n/, $_[0]) {
                            $irc->send_chan( $channel, "NOTICE", $channel, encode($self->encoding, $_) );
                        }
                    },
                    $message
                );
            };
            if ($@) {
                print STDERR $@;
                die $@;
            }
            else {
                if ($proceeded) {
                    return;
                }
            }
        }
    );
    $irc->connect( $self->host, $self->port, { nick => $self->nick } );
    $irc->enable_ping(10);
    $self->irc($irc);
}

sub run {
    my ($self, $bot) = @_;
    $self->_connect($bot);
}

1;

