use v5.26;
use strict;
use warnings;
use Discord::Client::HTTPInteractions;

# Verify signed HTTP requests without a Bot token or Gateway connection.
my $service = Discord::Client::HTTPInteractions->new( public_key => $ENV{DISCORD_PUBLIC_KEY}, );

# Send the reply directly in the HTTP response.
$service->command(
    ping => (
        description => 'Replies with Pong',
        handler => sub {
            my ($interaction) = @_;

            # Return the reply Future so delivery failures remain visible to the dispatcher.
            return $interaction->reply('Pong!');
        },
    ),
);

# Return the application for a PSGI host to serve.
$service->psgi_app;
