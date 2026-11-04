#!/usr/bin/env perl
use v5.26;
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../lib";
use Discord::Client;

# Configure the bot; slash commands do not need Message Content.
my $bot = Discord::Client->new(
    token => $ENV{DISCORD_BOT_TOKEN},
    intents => ['GUILDS'],
);

# Reply to the ping command.
$bot->command(
    ping => (
        description => 'Replies with Pong',
        handler => sub {
            my ($interaction) = @_;

            # Return asynchronous work to the dispatcher for error handling and shutdown.
            return $interaction->reply('Pong!');
        },
    ),
);

# Run directly, or return the client when loaded for explicit command deployment.
$bot->run unless caller;
$bot;
