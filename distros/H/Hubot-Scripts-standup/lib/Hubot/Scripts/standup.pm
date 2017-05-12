package Hubot::Scripts::standup;
{
  $Hubot::Scripts::standup::VERSION = '0.0.1';
}

# ABSTRACT: Agile standup bot ala tender
use strict;
use warnings;
use List::Util 'shuffle';
use DateTime;
use JSON::XS;

sub load {
    my ( $class, $robot ) = @_;
    $robot->respond(
        qr/(?:cancel|stop) standup *$/i,
        sub {
            my $msg = shift;
            delete $robot->brain->{data}{standup}{$msg->message->user->{room}};
            $msg->send("Standup cancelled");
        }
    );

    $robot->respond(
        qr/standup for (.*) *$/i,
        sub {
            my $msg = shift;
            my $room = $msg->message->user->{room};
            my $group = trim($msg->match->[0]);
            if ($robot->brain->{data}{standup}{$room}) {
                $msg->send("The standup for " . $robot->brain->{data}{standup}{$room}{$group} . " is in progress! Cancel it first with 'cancel standup'");
                return;
            }

            my @attendees;
            while (my ($key, $user) = each %{ $robot->brain->{data}{users} }) {
                my @roles = @{ $user->{roles} ||= [] };
                if (grep { m/an? $group member/ } @roles or grep { m/a member of $group/ } @roles) {
                    push @attendees, $user;
                }
            }

            if (@attendees) {
                $robot->brain->{data}{standup}{$room} = {
                    group => $group,
                    start => DateTime->now->epoch,
                    attendees => \@attendees,
                    remaining => [shuffle @attendees],
                    log => [],
                };

                my $who = join ', ', map { $_->{name} } @attendees;
                $msg->send("OK, let's start the standup: $who");
                nextPerson($robot, $room, $msg);
            }
        }
    );

    $robot->respond(
        qr/(?:next(?: person)?|done)/i,
        sub {
            my $msg = shift;
            return unless $robot->brain->{data}{standup}{$msg->message->user->{room}};
            nextPerson($robot, $msg->message->user->{room}, $msg);
        }
    );

    $robot->respond(
        qr/standup\?? *$/i,
        sub {
            my $msg = shift;
            $msg->send((
                "<who> is a member of <team> - tell hubot who is the member of <team>'s standup",
                "standup for <team> - start the standup for <team>",
                "cancel standup - cancel the current standup",
                "next - say when your updates for the standup is done",
            ));
        }
    );

    $robot->catchAll(
        sub {
            my $msg = shift;
            my $standup = $robot->brain->{data}{standup};
            return unless $standup->{$msg->message->user->{room}};
            push @{ $standup->{$msg->message->user->{room}}{log} ||= [] }, {
                message => $msg->message,
                time    => DateTime->now->epoch,
            }
        }
    );

    $robot->respond(
        qr/post (.*) standup logs? to (\d*) *$/i,
        sub {
            my $msg = shift;
            my ($group, $group_id) = @{ $msg->match };
            warn "$group, $group_id";
            $robot->brain->{data}{yammerGroups}{$group} = $group_id;
            if (my $buff = $robot->brain->{data}{tempYammerBuffer}{group}) {
                postYammer($robot, $group, $msg->message->user->{room}, $msg, $buff);
                delete $robot->brain->{data}{tempYammerBuffer}{$group};
            }
        }
    );

    ### post yammer
    $robot->brain->on(
        'standupLog',
        sub {
            my ($e, $group, $room, $response, $logs) = @_;
            postYammer($robot, $group, $room, $response, $logs);
        }
    );
}

sub trim {
    my $str = shift;
    $str =~ s/(^\s+|\s+$)//g;
    return $str;
}

sub nextPerson {
    my ($robot, $room, $msg) = @_;
    my $standup = $robot->brain->{data}{standup}{$room};
    if (scalar @{ $standup->{remaining} } == 0) {
        my $duration = DateTime->now - DateTime->from_epoch(epoch => $standup->{start});
        my $howlong = $duration->minutes
            ? sprintf("%s minutes and %s seconds", $duration->minutes, $duration->seconds)
            : sprintf("%s seconds", $duration->seconds);
        $msg->send("All done! Standup was $howlong");
        $robot->brain->emit('standupLog', $standup->{group}, $room, $msg, $standup->{log});
        delete $robot->brain->{data}{standup}{$room};
    } else {
        $standup->{current} = shift @{ $standup->{remaining} };
        $msg->send($standup->{current}{name} . ' your turn');
    }
}

sub postYammer {
    my ($robot, $group, $room, $response, $logs) = @_;
    my $group_id = getYammerGroup($robot, $group);
    if (!$group_id) {
        $response->send("Tell me which Yammer group to post archives. Say 'hubot post $group standup logs to <GROUP_ID>'. Use Group ID 0 if you don't need archives.");
        $robot->brain->{data}{tempYammerBuffer}{$group} = $logs;
    } elsif ($group_id == 0) {
        # do nothing
    } else {
        my $body = makeBody($robot, $group, $logs);
        $response->http('https://www.yammer.com/api/v1/messages.json')
            ->header({
                Authorization  => "Bearer $ENV{HUBOT_STANDUP_YAMMER_TOKEN}",
                Accept         => 'application/json',
            })
            ->query({
                group_id => $group_id,
                body     => $body,
                topic0   => 'standup',
            })
            ->post(
                sub {
                    my ($body, $hdr) = @_;
                    if ($hdr->{Status} !~ m/^2/) {
                        $response->send("Posting to the group $group_id FAILED: $hdr->{Reason}");
                    } else {
                        my $data = decode_json($body);
                        if ($data->{messages}) {
                            $response->send("Posted to Yammer: " . $data->{messages}[0]{web_url});
                        } else {
                            $response->send("Posting to the group $group_id FAILED: $body");
                        }
                    }
                }
            );
    }
}

sub getYammerGroup {
    my ($robot, $group) = @_;
    $robot->brain->{data}{yammerGroups} ||= {};
    return $robot->brain->{data}{yammerGroups}{$group};
}

sub makeBody {
    my ($robot, $group, $logs) = @_;
    my $dt = DateTime->now;
    my $body = "Standup log for $group: $dt\n======================\n";
    my $prev = '';
    for my $log (@$logs) {
        if ($log->{message}{user}{name} ne $prev) {
            my $name = $log->{message}{user}{name};
            if ($log->{message}{user}{yammerName}) {
                $name = "@" . $log->{message}{user}{yammerName};
            }
            $body .= "\n$name:\n";
        }
        $body .= $log->{message}{text} . "\n";
        $prev = $log->{message}{user}{name};
    }

    return $body;
}

1;


=pod

=head1 NAME

Hubot::Scripts::standup - Agile standup bot ala tender

=head1 SYNOPSIS

    hubot standup? - show help for standup

=head1 SETUP

First, you tell hubot who is a member for a particular team for the standup, using the C<roles> commands with "(who) is a (team) member".

Let's take "engineering" team for example.

    miyagawa: hubot miyagawa is an engineering member
    hubot: Ok, miyagawa is an engineering member
    miyagawa: hubot john is an engineering member
    hubot: Ok, john is an engineering member
    miyagawa: hubot davidlee is an engineering member
    hubot: Ok, davidlee is an engineering member

You can create as many teams as you want.

=head2 START THE STANDUP

Hubot won't schedule the standup for you (yet), you have to start it by yourself when it's time.

    miyagawa: hubot standup for engineering
    hubot: Ok, let's start the standup: miyagawa, john, davidlee
    hubot: john: your turn

Hubot remembers who should participate the standup, and will tell whose turn is the next. Tell what you did yesterday, will do today, anything blocked. and say "next" (or "done") when you're done.

    john: Done some pretty nice hack yesterday.
    john: I will work on another cool stuff today.
    john: I'm not blocked
    john: hubot next
    hubot: davidlee: your turn

When the user is offline or away for a second, tell hubot to skip the user.

    miyagawa: hubot skip davidlee
    hubot: Will skip davidlee
    hubot: miyagawa: your turn

Once the last user is done, hubot will tell you how long the standup was.

    miyagawa: I'm working on some nice stuff, and will continue doing so today.
    miyagawa: hubot next
    hubot: All done! Standup was 5 minutes and 24 seconds.

=head2 CONFIGURATION

=over

=item HUBOT_STANDUP_YAMMER_TOKEN

=back

the bot will post the standup archive to Yammer. You need to set a valid Yammer OAuth2 token to C<HUBOT_STANDUP_YAMMER_TOKEN> environment variable.

Here's how to get a valid Yammer OAuth2 token with the standard OAuth2 authorization flow.

See L<Yammer documentation|https://developer.yammer.com/api/oauth2.html> for more details.

=over

=item * Register a new application on Yammer at `https://www.yammer.com/<DOMAIN>/client_applications/new`. Leave the callback URLs empty

=item * Take notes of your `consumer_key` and `consumer_secret`

=item * Make a new bot user on Yammer (optional). This is the user who will post archives as.

=item * Sign in as the new bot user on Yammer if necessary

=item * Go to `https://www.yammer.com/dialog/oauth?client_id=<consumer_key>`

=item * There's an authorization dialog. Authorize the app

=item * Look at the URL bar and there's a `code=<CODE>` query parameter in there, copy that.

=item * `curl https://www.yammer.com/oauth2/access_token?code=<CODE>&client_id=<consumer_key>&client_secret=<consumer_secret>`

=item * you'll get a big JSON that contains `access_token` -> `token`

=back

Now set the token to C<HUBOT_STANDUP_YAMMER_TOKEN> and Hubot will ask which group ID the log should be posted to. Use the group ID 0 to turn off the feature for a group.

=head1 SEE ALSO

L<https://github.com/miyagawa/hubot-standup>

=head1 AUTHOR

Hyungsuk Hong <hshong@perl.kr>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Hyungsuk Hong.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
