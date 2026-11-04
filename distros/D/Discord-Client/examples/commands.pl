#!/usr/bin/env perl
use v5.26;
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../lib";
use Discord::Client;

# Configure a bot with one slash command.
my $bot = Discord::Client->new(
    token => $ENV{DISCORD_BOT_TOKEN},
    intents => ['GUILDS'],
);

# Keep the response logic separate from the command's argument declaration.
sub greet {
    my ($interaction) = @_;
    my $name = $interaction->option('name');

    # Treat the supplied name as text so it cannot trigger a mention.
    return $interaction->reply(
        {
            content => "Hello, $name!",
            allowed_mentions => { parse => [] },
        }
    );
}

# Discord presents and validates the required name argument.
$bot->command(
    greet => (
        description => 'Greet someone by name',
        options => [
            {
                name => 'name',
                type => 'string',
                description => 'Name to greet',
                required => 1,
            },
        ],
        handler => \&greet,
    ),
);

# Run the bot, or expose its declarations to the deployment script.
$bot->run unless caller;
$bot;
