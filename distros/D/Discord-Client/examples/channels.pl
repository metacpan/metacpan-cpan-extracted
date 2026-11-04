#!/usr/bin/env perl
use v5.26;
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../lib";
use Discord::Client;

# Configure a bot that lists the current server's channels.
my $bot = Discord::Client->new(
    token => $ENV{DISCORD_BOT_TOKEN},
    intents => ['GUILDS'],
);

# Acknowledge before fetching channels, then complete the deferred reply.
sub list_channels {
    my ( $interaction, $bot ) = @_;

    # Reject direct-message use before acknowledging or requesting guild resources.
    my $guild_id = $interaction->guild_id;
    return $interaction->reply( 'Use this command in a server.', ephemeral => 1 )
        unless defined $guild_id;

    # Acknowledge before REST I/O so channel lookup does not consume the reply deadline.
    return $interaction->defer( ephemeral => 1 )->then(
        sub {
            my $guild = $bot->model( guild => { id => $guild_id } );
            return $guild->channels;
        }
    )->then(
        sub {
            my ($channels) = @_;

            # Bound the displayed names and suppress mentions in server-controlled channel names.
            my $names = join( ', ', map { $_->name } @$channels );
            $names = substr( $names, 0, 1900 );

            return $interaction->reply(
                {
                    content => length($names) ? "Channels: $names" : 'No channels found.',
                    allowed_mentions => { parse => [] },
                }
            );
        }
    );
}

# Keep the command declaration focused on its purpose.
$bot->command(
    channels => (
        description => 'List this server\'s channels',
        handler => sub {
            my ($interaction) = @_;
            return list_channels( $interaction, $bot );
        },
    ),
);

# Run the bot, or expose its declarations to the deployment script.
$bot->run unless caller;
$bot;
