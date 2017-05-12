package Hubot::Scripts::op;
$Hubot::Scripts::op::VERSION = '0.1.10';
use strict;
use warnings;

sub load {
    my ( $class, $robot ) = @_;

    my $nickserv = $ENV{HUBOT_IRC_NICKSERV} || 'NickServ';
    my @allow_accounts = split( /,/, $ENV{HUBOT_OP_ACCOUNTS} || '' );
    my $room = '';

    $robot->enter(
        sub {
            my $msg = shift;

            $room = $msg->message->user->{room};
            my $user = $msg->message->user->{name};
            ## support IRC adapter only
            if ( 'Hubot::Adapter::Irc' eq ref $robot->adapter ) {
                my $to = $robot->userForName($nickserv);
                ## maybe need more common interface for adapters
                $robot->adapter->irc->send_srv( 'WHOIS' => $user );
            }
        }
    );

    $robot->notice(
        sub {
            my $msg = shift;

            my $text = $msg->message->text;
            if ( my ( $nick, $account )
                = $text =~ m/^([^ ]+) is logged in as (.+)$/ )
            {
                ## freenode only?
                return unless grep { $account eq $_ } @allow_accounts;
                if ( $robot->mode eq '+o' ) {
                    ## maybe need more common interface for adapters
                    $robot->adapter->irc->send_srv( 'MODE', $room, '+o',
                        $nick );
                }
            }
        }
    );
}

1;

=head1 NAME

Hubot::Scripts::op

=head1 VERSION

version 0.1.10

=head1 SYNOPSIS

    op - hubot will `/op <nick>` to configured account if hubot can

=head1 CONFIGURATION

C<HUBOT_OP_ACCOUNTS>

account is needed, not nickname. separated by comma.

=head1 AUTHOR

Hyungsuk Hong <hshong@perl.kr>

=cut
