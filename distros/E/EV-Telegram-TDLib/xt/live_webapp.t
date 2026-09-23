use strict;
use warnings;
use Test::More;

BEGIN {
    plan skip_all => 'author test: set AUTHOR_TESTING=1' unless $ENV{AUTHOR_TESTING};
}

plan skip_all => 'set TD_API_ID and TD_API_HASH'
    unless $ENV{TD_API_ID} && $ENV{TD_API_HASH};
plan skip_all => 'set TD_DATABASE_DIRECTORY to an authenticated user session'
    unless $ENV{TD_DATABASE_DIRECTORY} && -d $ENV{TD_DATABASE_DIRECTORY};
plan skip_all => 'set TD_BOT_TOKEN (or TD_BOT_TOKEN_FILE)'
    unless $ENV{TD_BOT_TOKEN} || $ENV{TD_BOT_TOKEN_FILE};
# A bot session created in a fresh database does not receive updates here:
# measured twice, the bot never saw the message and the run timed out, while
# the same code against a reused directory passes in a second. So this needs
# a persistent bot session rather than a throwaway one.
plan skip_all => 'set TD_BOT_DATABASE_DIRECTORY to a persistent bot session'
    unless $ENV{TD_BOT_DATABASE_DIRECTORY};

use EV;
use EV::Telegram::TDLib;

my $token = $ENV{TD_BOT_TOKEN};
if (!$token && $ENV{TD_BOT_TOKEN_FILE}) {
    open my $fh, '<', $ENV{TD_BOT_TOKEN_FILE} or plan skip_all => "token file: $!";
    # not chomp: under `local $/` chomp is a no-op, and the trailing newline
    # makes TDLib reject the token as ACCESS_TOKEN_INVALID
    $token = do { local $/; <$fh> };
    $token =~ s/\s+\z//;
}

# Both sessions receive whatever arrived while they were offline, so every
# message this test cares about carries a per-run nonce. Without it a replay
# from an earlier run drives the exchange and the assertions pass by accident.
my $nonce = sprintf '%d_%d', $$, time;

my $botdir = $ENV{TD_BOT_DATABASE_DIRECTORY};

my $BTN     = "Open $nonce";
my $PAYLOAD = qq({"nonce":"$nonce","n":42});
my $URL     = $ENV{TD_WEBAPP_URL} // 'https://example.com/';

my $user = EV::Telegram::TDLib->new(
    api_id => $ENV{TD_API_ID}, api_hash => $ENV{TD_API_HASH},
    database_directory => $ENV{TD_DATABASE_DIRECTORY}, on_error => sub {},
    on_code     => sub { BAIL_OUT 'user session is not authenticated' },
    on_password => sub { BAIL_OUT 'user session is not authenticated' });
my $bot = EV::Telegram::TDLib->new(
    api_id => $ENV{TD_API_ID}, api_hash => $ENV{TD_API_HASH},
    bot_token => $token, database_directory => $botdir, on_error => sub {});

my ($bot_id, $got_data, $got_button, $sent_seen, $keyboard_type);
my $done = 0;
sub finish { return if $done++; $bot->close(sub { $user->close(sub { EV::break }) }) }

$bot->on_message(sub {
    my ($m) = @_;
    return if $m->{is_outgoing};
    return unless index(($m->{content}{text}{text} // ''), $nonce) >= 0;
    $bot->send_message($m->{chat_id}, "probe $nonce",
        reply_markup => $bot->reply_keyboard([[ { text => $BTN, web_app => $URL } ]]),
        sub { });
});

$bot->on_web_app_data(sub {
    my (undef, $data, $button) = @_;
    return unless index($data, $nonce) >= 0;
    ($got_data, $got_button) = ($data, $button);
    finish();
});

$user->on_message(sub {
    my ($m) = @_;
    my $c = $m->{content} || {};
    my $text = $c->{text}{text} // '';
    if (!$m->{is_outgoing} && $m->{reply_markup} && index($text, $nonce) >= 0) {
        $keyboard_type = $m->{reply_markup}{rows}[0][0]{type}{'@type'};
        $user->send_web_app_data($bot_id, $BTN, $PAYLOAD, sub { }) if defined $bot_id;
    }
    elsif ($m->{is_outgoing} && ($c->{'@type'} // '') eq 'messageWebAppDataSent'
           && ($c->{button_text} // '') eq $BTN) {
        $sent_seen = $c->{button_text};
    }
});

my ($user_up, $bot_up);
sub kick {
    return unless $user_up && $bot_up;
    $user->send_message($bot_id, "/start $nonce", sub { });
}
$user->login(sub {
    my (undef, $e) = @_; BAIL_OUT("user login: $e->{message}") if $e;
    $user_up = 1; kick();
});
$bot->login(sub {
    my (undef, $e) = @_; BAIL_OUT("bot login: $e->{message}") if $e;
    $bot->me(sub {
        my ($u, $ue) = @_; BAIL_OUT("me: $ue->{message}") if $ue;
        $bot_id = $u->{id}; $bot_up = 1; kick();
    });
});

my $timeout = EV::timer 90, 0, sub { finish() };
EV::run;

is $keyboard_type, 'keyboardButtonTypeWebApp', 'the user saw a Web App button';
is $got_data, $PAYLOAD, 'the bot received the payload byte for byte';
is $got_button, $BTN, 'and the button text that produced it';
is $sent_seen, $BTN, 'the user saw messageWebAppDataSent';

done_testing;
