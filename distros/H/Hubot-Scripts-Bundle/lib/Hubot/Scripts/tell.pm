package Hubot::Scripts::tell;
$Hubot::Scripts::tell::VERSION = '0.1.10';
use strict;
use warnings;
use DateTime;

sub load {
    my ( $class, $robot ) = @_;
    $robot->respond(
        qr/(tell (\w+) (?:.+))$/i,
        sub {
            my $msg    = shift;
            my $sender = $msg->message->user->{name};
            my ( $post, $recipient ) = ( $msg->match->[0], $msg->match->[1] );

# XXX: hey, There should be generalized nick matchers, supplied from each adapters.
# $robot->exist($room, $nick)
            if ( my ($user) = $robot->userForName($recipient)
                and $msg->exist($recipient) )
            {
                $msg->reply("<$recipient> $post");
            }
            else {
              # XXX: hey, There is no time provided from adapters for messages.
                my $dt = DateTime->now( time_zone => 'Asia/Seoul' );
                $robot->brain->{data}{tell}{$recipient}{ +time }
                    = [$sender, $recipient, $post, $dt->ymd . " " . $dt->hms];
                $msg->reply(
                    "OK, I'll pass that on when $recipient is around.");
            }
        }
    );
    $robot->enter(
        sub {
            my $msg  = shift;
            my $user = $msg->message->user->{name};
            for my $recipient ( keys %{ $robot->brain->{data}{tell} } ) {
                if ( $user =~ /^$recipient$/i ) {
                    for my $post (
                        values %{ $robot->brain->{data}{tell}{$recipient} } )
                    {
                        $msg->send(
                            "$user: $post->[3]: <$post->[0]> $post->[2]");
                    }
                    delete $robot->brain->{data}{tell}{$recipient};
                }
                last;
            }
        }
    );
}

1;

=head1 NAME

Hubot::Scripts::tell

=head1 VERSION

version 0.1.10

=head1 SYNOPSIS

    hubot tell <user> <message> - pass <message> on when <user> is around.

=head1 AUTHOR

Hojung Youn <am0c@perl.kr>

=cut
