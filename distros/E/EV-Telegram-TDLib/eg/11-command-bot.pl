#!/usr/bin/env perl
# 11-command-bot.pl - a bot built from on_command, on_callback_data and ask
#
# The point of interest is ask(): it sends a prompt and waits for that user's
# next message in that chat. While one is pending it shadows the command
# router for that user, so an answer beginning with a slash cannot both answer
# the prompt and run a command handler. That is deliberate, and it is why the
# /cancel here is checked inside the ask callback rather than registered as a
# command: a command handler would never see it while the ask was pending.
#
#   TD_API_ID=... TD_API_HASH=... TD_BOT_TOKEN=... perl eg/11-command-bot.pl
#
# Talk to the bot in a private chat: /start, /help, /name, /colour, /vote.

use strict;
use warnings;
use EV;
use EV::Telegram::TDLib;

sub env_or_die {
    my ($name, $what) = @_;
    $ENV{$name} // die "missing environment variable $name ($what)\n";
}

my $td = EV::Telegram::TDLib->new(
    api_id             => env_or_die('TD_API_ID', 'from https://my.telegram.org'),
    api_hash           => env_or_die('TD_API_HASH', 'from https://my.telegram.org'),
    bot_token          => env_or_die('TD_BOT_TOKEN', 'from @BotFather'),
    database_directory => $ENV{TD_DATABASE_DIRECTORY} // 'tdlib-bot-db',
    on_error           => sub { warn "tdlib: $_[0]\n" },
);

sub sender_of { $_[0]{sender_id}{user_id} }

$td->on_command(start => sub {
    my ($msg) = @_;
    $td->send_message($msg->{chat_id},
        "hello. try /help, /name or /colour");
});

$td->on_command(help => sub {
    my ($msg, $args) = @_;
    # $args is the rest of the line, '' when there is nothing after the command
    my $topic = length $args ? " about $args" : '';
    $td->send_message($msg->{chat_id}, "no help$topic yet, sorry");
});

# a one-shot question
$td->on_command(name => sub {
    my ($msg) = @_;
    my $chat = $msg->{chat_id};
    my $user = sender_of($msg) or return;

    $td->ask($chat, $user, 'What should I call you?', timeout => 60, sub {
        my ($reply, $err) = @_;
        if ($err) {
            # timed out, cancelled, or replaced by a later ask
            $td->send_message($chat, "never mind ($err->{message})");
            return;
        }
        my $text = $reply->{content}{text}{text} // '';
        # the escape hatch has to live here: a pending ask shadows commands
        return $td->send_message($chat, 'cancelled') if $text eq '/cancel';
        $td->send_message($chat, "noted, $text");
    });
});

# two questions in sequence: nesting is the whole multi-step mechanism
$td->on_command(colour => sub {
    my ($msg) = @_;
    my $chat = $msg->{chat_id};
    my $user = sender_of($msg) or return;

    $td->ask($chat, $user, 'Favourite colour?', timeout => 60, sub {
        my ($reply, $err) = @_;
        return if $err;
        my $colour = $reply->{content}{text}{text} // '';

        $td->ask($chat, $user, "And why $colour?", timeout => 60, sub {
            my ($why, $err) = @_;
            return if $err;
            $td->send_message($chat,
                "$colour, because @{[ $why->{content}{text}{text} // '' ]}. Noted.");
        });
    });
});

# inline buttons, routed by their payload. inline_keyboard rather than a
# hand-built replyMarkupInlineKeyboard: callback data is a bytes field, so
# TDLib wants it base64-encoded and refuses the plain text outright.
$td->on_command(vote => sub {
    my ($msg) = @_;
    $td->send_message($msg->{chat_id}, 'Pick one:',
        reply_markup => $td->inline_keyboard([
            [ { text => 'Yes', data => 'vote:yes' },
              { text => 'No',  data => 'vote:no'  } ],
        ]),
        sub { my (undef, $err) = @_; warn "vote: $err->{message}\n" if $err });
});

# a literal pattern would be an exact match; a regex is what handles a prefix
$td->on_callback_data(qr/^vote:(\w+)$/ => sub {
    my ($query, $choice) = @_;
    $td->answer_callback_query($query->{id}, text => "you picked $choice");
});

my $status = 0;

$td->login(sub {
    my (undef, $err) = @_;
    # contained and reported, not propagated: break out or the loop runs on
    if ($err) {
        warn "login failed: $err->{message}\n";
        $status = 1;
        return EV::break;
    }
    warn "bot ready\n";
});

# EV::signal, not %SIG: perl dispatches a signal handler only at an op
# boundary, and no perl op runs while EV::run is blocked, so a %SIG{INT}
# handler here would never fire -- and installing one also suppresses the
# default terminate, leaving the bot unkillable by Ctrl-C
my $sigint = EV::signal 'INT', sub { $td->close(sub { EV::break }) };

EV::run;
exit $status;
