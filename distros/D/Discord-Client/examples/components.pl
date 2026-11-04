#!/usr/bin/env perl
use v5.26;
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../lib";
use Discord::Client;
use Discord::Client::UI qw(row button);

# Configure a bot whose message contains a button.
my $bot = Discord::Client->new(
    token => $ENV{DISCORD_BOT_TOKEN},
    intents => ['GUILDS'],
);

# Send a button using named properties rather than numeric component types.
$bot->command(
    button => (
        description => 'Show a button',
        handler => sub {
            my ($interaction) = @_;

            # Build the visible control with the same ID registered by the component handler.
            return $interaction->reply(
                {
                    content => 'Press the button.',
                    components => [ row( button( 'hello', label => 'Say hello' ) ) ],
                }
            );
        },
    ),
);

# The button ID connects the displayed control to its handler.
$bot->component(
    hello => sub {
        my ($interaction) = @_;

        # Keep the button response private to the person who clicked it.
        return $interaction->reply( 'Hello!', ephemeral => 1 );
    }
);

# Run the bot, or expose its declarations to the deployment script.
$bot->run unless caller;
$bot;
