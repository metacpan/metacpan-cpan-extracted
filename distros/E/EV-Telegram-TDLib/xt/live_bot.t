use strict;
use warnings;
use Test::More;
use File::Temp ();
use MIME::Base64 ();

# Destructive, and unlike xt/live_planes.t it does not clean up after itself.
# It overwrites the bot's public identity -- name, short description,
# description and profile photo -- and does not put any of them back, because
# TDLib offers no way to read a bot's photo before replacing it. Point
# TD_BOT_TOKEN at a throwaway bot, never at one anyone uses.

plan skip_all => 'author test: set AUTHOR_TESTING=1' unless $ENV{AUTHOR_TESTING};
plan skip_all => 'set TD_API_ID and TD_API_HASH'
    unless $ENV{TD_API_ID} && $ENV{TD_API_HASH};
plan skip_all => 'set TD_DATABASE_DIRECTORY to an authenticated user session'
    unless $ENV{TD_DATABASE_DIRECTORY} && -d $ENV{TD_DATABASE_DIRECTORY};
plan skip_all => 'set TD_BOT_TOKEN (or TD_BOT_TOKEN_FILE)'
    unless $ENV{TD_BOT_TOKEN} || $ENV{TD_BOT_TOKEN_FILE};

require EV;
require EV::Telegram::TDLib;

my $token = $ENV{TD_BOT_TOKEN};
if (!$token && $ENV{TD_BOT_TOKEN_FILE}) {
    open my $fh, '<', $ENV{TD_BOT_TOKEN_FILE} or plan skip_all => "token file: $!";
    chomp($token = <$fh>);
}

# a 512x512 solid PNG: Telegram requires a real image, and a profile photo
# must be square enough to crop
my $PNG = <<'B64';
iVBORw0KGgoAAAANSUhEUgAAAgAAAAIACAMAAADDpiTIAAAAIGNIUk0AAHomAACAhAAA+gAAAIDo
AAB1MAAA6mAAADqYAAAXcJy6UTwAAAADUExURR5aqCmbLaQAAAAHdElNRQfqCBkRBSLTmb12AAAA
JXRFWHRkYXRlOmNyZWF0ZQAyMDI2LTA4LTI1VDE3OjA1OjM0KzAwOjAwpTxjvAAAACV0RVh0ZGF0
ZTptb2RpZnkAMjAyNi0wOC0yNVQxNzowNTozNCswMDowMNRh2wAAAAAodEVYdGRhdGU6dGltZXN0
YW1wADIwMjYtMDgtMjVUMTc6MDU6MzQrMDA6MDCDdPrfAAABFUlEQVR42u3BMQEAAADCoPVP7WkJ
oAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA4AYCPAAByZWgVQAAAABJRU5ErkJggg==
B64

my $botdir = File::Temp::tempdir('ev-td-bot-XXXXXX', TMPDIR => 1, CLEANUP => 1);
my $data   = 'vote:yes';
my $answer = "counted $$";

# two clients in one process and one loop, as the Cookbook describes
my $bot = EV::Telegram::TDLib->new(
    api_id => $ENV{TD_API_ID}, api_hash => $ENV{TD_API_HASH},
    bot_token => $token, database_directory => $botdir,
    on_error => sub { diag "bot: $_[0]" },
);
my $user = EV::Telegram::TDLib->new(
    api_id => $ENV{TD_API_ID}, api_hash => $ENV{TD_API_HASH},
    database_directory => $ENV{TD_DATABASE_DIRECTORY},
    on_error => sub { diag "user: $_[0]" },
    on_code     => sub { BAIL_OUT 'user session is not authenticated' },
    on_password => sub { BAIL_OUT 'user session is not authenticated' },
);

my $photo_file;
my ($bot_me, $bot_username, $bot_chat, $user_chat, $kb_message, $seen_query, $got_answer);
my $finished = 0;

sub finish {
    return if $finished++;
    my @open = ($bot, $user);
    my $left = scalar @open;
    $_->close(sub { EV::break() unless --$left }) for @open;
}

# the bot learns the user's chat from the /start it receives
$bot->on_message(sub {
    my ($msg) = @_;
    return if $msg->{is_outgoing} || $user_chat;
    $user_chat = $msg->{chat_id};
    $bot->send_message($user_chat, 'pick one',
        reply_markup => EV::Telegram::TDLib->inline_keyboard(
            [ [ { text => 'Yes', data => $data } ] ]),
        sub {
            my (undef, $err) = @_;
            fail "bot send_message: $err->{message}" if $err;
        });
});

$bot->on_callback_query(sub {
    my ($q) = @_;
    $seen_query = $q;
    $bot->answer_callback_query($q->{id}, text => $answer, sub {});
});

# the user presses the button as soon as the keyboard message arrives
$user->on_message(sub {
    my ($msg) = @_;
    return if !$bot_chat || $msg->{chat_id} != $bot_chat;
    return if $msg->{is_outgoing} || $kb_message;
    $kb_message = $msg->{id};
    $user->send({
        '@type' => 'getCallbackQueryAnswer',
        chat_id => 0 + $bot_chat, message_id => 0 + $kb_message,
        payload => { '@type' => 'callbackQueryPayloadData',
                     data => MIME::Base64::encode_base64($data, '') },
    }, sub {
        my ($ans, $err) = @_;
        if ($err) { fail "getCallbackQueryAnswer: $err->{message}"; finish(); return }
        $got_answer = $ans->{text};
        $user->react($bot_chat, $kb_message, "\x{1F44D}", sub {
            my (undef, $err) = @_;
            if ($err) { fail "react: $err->{message}"; finish(); return }
            pass 'react added in the bot chat';
            $user->react($bot_chat, $kb_message, "\x{1F44D}", remove => 1, sub {
                my (undef, $err) = @_;
                if ($err) { fail "react remove: $err->{message}" }
                else      { pass 'react removed again' }
                finish();
            });
        });
    });
});

my $watchdog = EV::timer($ENV{TD_TIMEOUT} || 180, 0, sub { fail 'timed out'; finish() });

$bot->login(sub {
    my (undef, $err) = @_;
    if ($err) { fail "bot login: $err->{message}"; finish(); return }
    $bot->me(sub {
        my ($u, $err) = @_;
        if ($err) { fail "bot me: $err->{message}"; finish(); return }
        $bot_me = $u;
        $bot_username = $u->{usernames}{editable_username}
                     // $u->{usernames}{active_usernames}[0];
        is $u->{type}{'@type'}, 'userTypeBot', 'bot session reports a bot account';
        is $bot->my_id, $u->{id}, 'my_id matches the account getMe reports';
        $bot->set_commands([ ['start', 'Begin'], ['help', 'Show help'] ], sub {
            my (undef, $err) = @_;
            if ($err) { fail "set_commands: $err->{message}" }
            else      { pass 'set_commands accepted' }
        });
        # the account-level profile setters are refused to bots by TDLib
        # itself; a bot has the set_bot_* family instead
        for my $forbidden (
            [ set_name          => ['Probe'] ],
            [ set_bio           => ['probe'] ],
            [ set_username      => ['ev_td_probe_bot'] ],
        ) {
            my ($method, $args) = @$forbidden;
            $bot->$method(@$args, sub {
                my (undef, $err) = @_;
                like $err && $err->{message}, qr/not available to bots/,
                    "$method is refused to a bot, cleanly";
            });
        }
        # Telegram allows a bot's public identity to change only rarely, so
        # a second run the same day is flood-limited. That says nothing
        # about the binding, and failing on it reddens every rerun.
        my $identity = sub {
            my ($what) = @_;
            return sub {
                my (undef, $err) = @_;
                if ($err && ($err->{code} // 0) == 429) {
                    diag "$what rate-limited: $err->{message}";
                    pass "$what skipped (rate limited)";
                } elsif ($err) { fail "$what: $err->{message}" }
                else           { pass "$what accepted" }
            };
        };
        $bot->set_bot_name("EV TDLib live $$", $identity->('set_bot_name'));
        $bot->set_bot_short_description('live test bot',
            $identity->('set_bot_short_description'));
        $bot->set_bot_description('Exercises EV::Telegram::TDLib.',
            $identity->('set_bot_description'));
        {
            my $pic = File::Temp->new(SUFFIX => '.png');
            binmode $pic;
            print {$pic} MIME::Base64::decode_base64($PNG);
            close $pic;
            # the handle must outlive the upload, which is asynchronous
            $photo_file = $pic;
            $bot->set_bot_photo("$pic", sub {
                my (undef, $err) = @_;
                if ($err) { fail "set_bot_photo: $err->{message}" }
                else      { pass 'set_bot_photo accepted' }
            });
        }
        $user->login(sub {
            my (undef, $err) = @_;
            if ($err) { fail "user login: $err->{message}"; finish(); return }
            # the positive user_by_username path: a bot IS a user
            $user->user_by_username($bot_username, sub {
                my ($who, $err) = @_;
                if ($err) { diag "user_by_username: $err->{message}" }
                else { is $who->{id}, $bot_me->{id}, 'user_by_username resolved the bot' }
                $user->chat_by_username($bot_username, sub {
                    my ($chat, $err) = @_;
                    if ($err) { fail "bot chat: $err->{message}"; finish(); return }
                    $bot_chat = $chat->{id};
                    $user->send_message($bot_chat, '/start', sub {});
                });
            });
        });
    });
});

EV::run();

ok $user_chat,   'bot received the /start and learned the chat';
ok $seen_query,  'bot received updateNewCallbackQuery';
is $seen_query && $seen_query->{data}, $data,
    'callback payload decoded back to the original bytes';
is $got_answer, $answer, 'answer_callback_query reached the user';

done_testing;
