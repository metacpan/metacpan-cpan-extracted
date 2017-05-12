package Hubot::Scripts::blacklist;
$Hubot::Scripts::blacklist::VERSION = '0.1.10';
use strict;
use warnings;
use Try::Tiny;

sub load {
    my ( $class, $robot ) = @_;
    $robot->brain->{data}{blacklist}{subscriber} ||= {};
    $robot->brain->{data}{blacklist}{patterns}   ||= [];
    print STDERR "you have to set env HUBOT_BLACKLIST_MANAGER"
        unless $ENV{HUBOT_BLACKLIST_MANAGER};
    $robot->respond(
        qr/blacklist add (.*)$/i,
        sub {
            my $msg = shift;

            return unless checkPermission( $robot, $msg );

            my $pattern = $msg->match->[0];
            try {
                qr/$pattern/
                    and push @{ $robot->brain->{data}{blacklist}{patterns} },
                    $pattern;
                $msg->send("OK, added <$pattern> to blacklist");
            }
            catch {
                $msg->send("Failed to add <$pattern> to blacklist: $_");
            };
        }
    );

    $robot->respond(
        qr/blacklist$/i,
        sub {
            my $msg   = shift;
            my $match = $msg->match->[0];
            my @list  = @{ $robot->brain->{data}{blacklist}{patterns} };
            if (@list) {
                my $index = 0;
                map {
                    s/^/\# [$index] /;
                    $index++;
                } @list;
                $msg->send(@list);
            }
            else {
                $msg->send('no blacklist');
            }
        }
    );

    $robot->respond(
        qr/blacklist del(?:ete)? (\d+)$/i,
        sub {
            my $msg = shift;

            return unless checkPermission( $robot, $msg );

            my $index = $msg->match->[0];
            my @list  = @{ $robot->brain->{data}{blacklist}{patterns} };
            if ( $index > @list - 1 ) {
                $msg->send("Can't delete [$index] from blacklist");
            }
            else {
                my $pattern = splice @list, $index, 1;
                $msg->send("Deleted [$index] - <$pattern> from blacklist");
                $robot->brain->{data}{blacklist}{patterns} = \@list;
            }
        }
    );

    $robot->respond(
        qr/blacklist subscribe$/i,
        sub {
            my $msg  = shift;
            my $name = $msg->message->user->{name};
            $robot->brain->{data}{blacklist}{subscriber}{$name}++;
            $msg->send("OK, $name subscribes blacklist");
        }
    );

    $robot->respond(
        qr/blacklist unsubscribe$/i,
        sub {
            my $msg  = shift;
            my $name = $msg->message->user->{name};
            delete $robot->brain->{data}{blacklist}{subscriber}{$name};
            $msg->send("OK, $name unsubscribes blacklist");
        }
    );

    $robot->enter(
        sub {
            my $msg  = shift;
            my $user = $msg->message->user->{name};
            ## support IRC adapter only
            if ( 'Hubot::Adapter::Irc' eq ref $robot->adapter ) {
                my $whois = $robot->adapter->whois($user);
                for my $pattern (
                    @{ $robot->brain->{data}{blacklist}{patterns} } )
                {
                    my $regex = qr/$pattern/;
                    if ( $whois =~ m/$regex/ ) {
                        my @subscriber = keys
                            %{ $robot->brain->{data}{blacklist}{subscriber} };
                        notify( $robot, $msg, $pattern, @subscriber );
                        last;
                    }
                }
            }
        }
    );
}

sub checkPermission {
    my ( $robot, $msg ) = @_;
    my @manager = split /,/, $ENV{HUBOT_BLACKLIST_MANAGER} || '';
    unless (@manager) {
        $msg->send( "oops! no managers. "
                . $robot->name
                . "'s owner has to read the documentation" );
        return;
    }

    my $name = $msg->message->user->{name};
    unless ( grep {/$name/} @manager ) {
        $msg->send(
            "you don't have permission. to add blacklist, asking to managers: $ENV{HUBOT_BLACKLIST_MANAGER}"
        );
        return;
    }

    return 1;
}

sub notify {
    my ( $robot, $res, $patt, @subs ) = @_;
    for my $sub (@subs) {
        my $to = $robot->userForName($sub);
        $res->whisper( $to, "blacklist[$patt] joined channel" );
    }
}

1;

=head1 NAME

Hubot::Scripts::blacklist

=head1 VERSION

version 0.1.10

=head1 SYNOPSIS

    hubot blacklist - show blacklist
    hubot blacklist add <pattern> - add pattern to blacklist
    hubot blacklist del <index> - delete pattern at blacklist[index]
    hubot blacklist subscribe - robot will tell you when blacklist entering a room
    hubot blacklist unsubscribe - robot will not tell you anymore when blacklist entering a room

=head1 CONFIGURATION

=over

=item * HUBOT_BLACKLIST_MANAGER

manager has permission which can add and delete to blacklist.
separate by comma C<,>

e.g.

    export HUBOT_BLACKLIST_MANAGER='hshong,aanoaa'

=back

=head1 AUTHOR

Hyungsuk Hong <hshong@perl.kr>

=cut
