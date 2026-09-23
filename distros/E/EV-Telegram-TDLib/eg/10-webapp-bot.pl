#!/usr/bin/env perl
# 10-webapp-bot.pl - bot that offers a Mini App and prints what it sends back
#
# Demonstrates: a Web App button on a reply keyboard, and on_web_app_data,
# which fires when the page calls Telegram.WebApp.sendData().
#
# Nothing here renders the page. The button carries a URL and the user's own
# Telegram client opens it; the bot only ever sees the data. To try it
# without writing a page, drive the other side from a user session with
# send_web_app_data (see xt/live_webapp.t).
#
# The Mini App must exist first: create it with /newapp in BotFather and
# point TD_WEBAPP_URL at the URL you gave it.
#
# The database directory (default ./tdlib-bot-db) holds the session: it is
# exactly as sensitive as a password.
#
# Environment:
#   TD_API_ID, TD_API_HASH  application credentials from https://my.telegram.org
#   TD_BOT_TOKEN            bot token from BotFather
#   TD_WEBAPP_URL           the Mini App URL
#   TD_DATABASE_DIRECTORY   optional, default ./tdlib-bot-db
#
# Run: perl eg/10-webapp-bot.pl   (add -Mblib to run from a built checkout)

use strict;
use warnings;
use EV;
use EV::Telegram::TDLib;

sub env_or_die {
    my ($name, $hint) = @_;
    return $ENV{$name} // die "missing environment variable $name ($hint)\n";
}

my $url = env_or_die('TD_WEBAPP_URL', 'the Mini App URL configured in BotFather');

my $td = EV::Telegram::TDLib->new(
    api_id             => env_or_die('TD_API_ID', 'api_id from https://my.telegram.org'),
    api_hash           => env_or_die('TD_API_HASH', 'api_hash from https://my.telegram.org'),
    bot_token          => env_or_die('TD_BOT_TOKEN', 'bot token from BotFather'),
    database_directory => $ENV{TD_DATABASE_DIRECTORY} // 'tdlib-bot-db',
    on_error           => sub { warn "tdlib: $_[0]\n" },
);

$td->on_message(sub {
    my ($msg) = @_;
    return if $msg->{is_outgoing};
    return unless ($msg->{content}{text}{text} // '') =~ m{^/start};
    $td->send_message($msg->{chat_id}, 'Open the Mini App:',
        reply_markup => $td->reply_keyboard([
            [ { text => 'Open', web_app => $url } ],
        ]), sub {
            my (undef, $err) = @_;
            warn "send: $err->{message}\n" if $err;
        });
});

# the payload is whatever the page put there: validate before trusting it
$td->on_web_app_data(sub {
    my ($msg, $data, $button_text) = @_;
    printf "data from [%s] in chat %s: %s\n", $button_text, $msg->{chat_id}, $data;
    $td->send_message($msg->{chat_id}, "Got it", sub { });
});

# a die inside a callback is contained and reported, not propagated, so it
# would leave the loop running and the script hanging: break out instead
my $status = 0;

$td->login(sub {
    my (undef, $err) = @_;
    if ($err) {
        warn "login failed: $err->{message}\n";
        $status = 1;
        return EV::break;
    }
    print "listening; send /start to the bot\n";
});

EV::run;
exit $status;
