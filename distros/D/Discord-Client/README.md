# Discord::Client

Build Discord bots in Perl with slash commands, messages, buttons and forms.
Uses `IO::Async` and `Future` to handle connections and rate limits.
Requires Perl 5.26 or newer. The API is experimental.

Unofficial; not affiliated with or endorsed by Discord.

## Install

From CPAN:

```sh
cpanm Discord::Client
```

From a source checkout:

```sh
cpanm .
```

## A simple bot

```perl
use v5.26;
use warnings;
use Discord::Client;

# Create the bot.
my $bot = Discord::Client->new(token => $ENV{DISCORD_BOT_TOKEN});

# Reply to /ping.
$bot->command(
    ping => (
        description => 'Replies with Pong',
        handler => sub {
            my ($interaction) = @_;
            return $interaction->reply('Pong!');
        },
    ),
);

# Run until shutdown.
$bot->run;
```

Create a bot in the [Discord Developer Portal](https://discord.com/developers/applications)
and invite it to a test server with the `bot` and `applications.commands` scopes.
Leave the Interactions Endpoint URL empty.
Set `DISCORD_BOT_TOKEN` and `TEST_GUILD_ID` in your environment.

Deploy [the ping example](examples/ping.pl) once, then run it:

```sh
perl examples/sync-commands.pl examples/ping.pl
perl examples/ping.pl
```

Deployment replaces this application's commands in the test server.
Startup does not deploy commands. Try `/ping`; stop the bot with Ctrl+C.

## More

Read the installed API documentation with `perldoc Discord::Client`.

- [Client API and examples](lib/Discord/Client.pm)
- [Commands](lib/Discord/Client/Commands.pm) and [Interactions](lib/Discord/Client/Interaction.pm)
- [REST](lib/Discord/Client/REST.pm), [Gateway](lib/Discord/Client/Gateway.pm) and [HTTP delivery](lib/Discord/Client/HTTPInteractions.pm)
- [Models](lib/Discord/Client/Model.pm), [shards](lib/Discord/Client/Gateway/Shards.pm) and [cache](lib/Discord/Client/Cache.pm)
- [Contributing](CONTRIBUTING.md)

[Apache License 2.0](LICENSE).
