#!/usr/bin/env perl
# 02-bot-echo.pl - bot that echoes every text message back to its chat
#
# Demonstrates: bot_token authorization (no credential callbacks needed),
# the on_message handler, send_message, and running until Ctrl-C.
#
# The database directory (default ./tdlib-bot-db) holds the session: it is
# exactly as sensitive as a password. A bot session needs its own directory;
# do not point it at the user session created by 01-login.pl.
#
# Environment:
#   TD_API_ID, TD_API_HASH  application credentials from https://my.telegram.org
#   TD_BOT_TOKEN            bot token from BotFather
#   TD_DATABASE_DIRECTORY   optional, default ./tdlib-bot-db
#
# Run: perl eg/02-bot-echo.pl   (add -Mblib to run from a built checkout)

use strict;
use warnings;
use EV;
use EV::Telegram::TDLib;

sub env_or_die {
    my ($name, $hint) = @_;
    return $ENV{$name} // die "missing environment variable $name ($hint)\n";
}

my $td;
$td = EV::Telegram::TDLib->new(
    api_id             => env_or_die('TD_API_ID', 'api_id from https://my.telegram.org'),
    api_hash           => env_or_die('TD_API_HASH', 'api_hash from https://my.telegram.org'),
    bot_token          => env_or_die('TD_BOT_TOKEN', 'bot token from BotFather'),
    database_directory => $ENV{TD_DATABASE_DIRECTORY} // 'tdlib-bot-db',
    on_message => sub {
        my ($msg) = @_;
        return if $msg->{is_outgoing};
        my $content = $msg->{content} // {};
        return unless ($content->{'@type'} // '') eq 'messageText';
        my $text = $content->{text}{text};
        return unless defined $text && length $text;
        $td->send_message($msg->{chat_id}, $text, sub {
            my (undef, $err) = @_;
            warn "echo failed: $err->{message}\n" if $err;
        });
    },
    on_error => sub { warn "tdlib: $_[0]\n" },
);

my $sigint = EV::signal 'INT', sub {
    print "shutting down\n";
    $td->close(sub { EV::break });
};

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
    print "echo bot running, Ctrl-C to stop\n";
});

EV::run;
exit $status;
