#!/usr/bin/env perl
use v5.26;
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../lib";
use Future::AsyncAwait;
use Discord::Client;

# Future::AsyncAwait is an optional dependency for this example only.
my $bot = Discord::Client->new(
    token => $ENV{DISCORD_BOT_TOKEN},
    intents => ['GUILDS'],
);

# The same workflow can be written sequentially using async/await.
async sub prepare_report_async {
    my ( $interaction, $bot ) = @_;

    # Acknowledge before work begins so it may outlive the initial-response deadline.
    await $interaction->defer( ephemeral => 1 );

    # Suspend on a Future rather than blocking the shared event loop.
    await $bot->loop->delay_future( after => 1 );

    # Wait for the final reply so its failure belongs to the handler Future.
    await $interaction->reply('Your report is ready.');
}

# An async subroutine returns the Future that the dispatcher monitors.
$bot->command(
    report => (
        description => 'Prepare a report asynchronously',
        handler => sub {
            my ($interaction) = @_;
            return prepare_report_async( $interaction, $bot );
        },
    ),
);

# Run the bot, or expose its declarations to the deployment script.
$bot->run unless caller;
$bot;
