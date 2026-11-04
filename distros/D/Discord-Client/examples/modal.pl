#!/usr/bin/env perl
use v5.26;
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../lib";
use Discord::Client;
use Discord::Client::UI qw(text_input modal);

# Configure a bot with a feedback form.
my $bot = Discord::Client->new(
    token => $ENV{DISCORD_BOT_TOKEN},
    intents => ['GUILDS'],
);

# Opening the form acknowledges the slash command.
$bot->command(
    feedback => (
        description => 'Send feedback',
        handler => sub {
            my ($interaction) = @_;

            # Declare the field once; its ID is also used when reading the submission.
            return $interaction->modal(
                modal(
                    'feedback_form',
                    title => 'Feedback',
                    fields => [
                        text_input(
                            'note',
                            label => 'Your note',
                            style => 'paragraph',
                            min_length => 1,
                            max_length => 1000,
                        ),
                    ],
                )
            );
        },
    ),
);

# Read the submitted input by name without walking Discord's component tree.
$bot->component(
    feedback_form => sub {
        my ($interaction) = @_;

        # Read the submitted field by its declared ID, independently of the component layout.
        my $note = $interaction->field('note');

        # Echo the note privately and disable mentions in user-supplied text.
        return $interaction->reply(
            {
                content => "Thanks for your feedback: $note",
                allowed_mentions => { parse => [] },
            },
            ephemeral => 1
        );
    }
);

# Run the bot, or expose its declarations to the deployment script.
$bot->run unless caller;
$bot;
