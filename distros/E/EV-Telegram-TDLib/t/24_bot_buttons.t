use strict;
use warnings;
use Test::More;

BEGIN { $ENV{EV_TDLIB_SHUTDOWN_TIMEOUT} = 0.1 }

use EV;
use EV::Telegram::TDLib;

# --- inline keyboards gained a web app button
my $kb = EV::Telegram::TDLib->inline_keyboard([
    [ { text => 'Open', web_app => 'https://example.com/' } ] ]);
is($kb->{rows}[0][0]{type}{'@type'}, 'inlineKeyboardButtonTypeWebApp',
    'inline web app button type');
is($kb->{rows}[0][0]{type}{url}, 'https://example.com/',
    'inline web app button carries the url');

# --- existing spellings are untouched
my $old = EV::Telegram::TDLib->inline_keyboard([
    [ { text => 'Yes', data => 'y' }, { text => 'Doc', url => 'https://e' } ] ]);
is($old->{rows}[0][0]{type}{'@type'}, 'inlineKeyboardButtonTypeCallback',
    'callback buttons unchanged');
is($old->{rows}[0][1]{type}{'@type'}, 'inlineKeyboardButtonTypeUrl',
    'url buttons unchanged');

my $err = do { local $@;
    eval { EV::Telegram::TDLib->inline_keyboard([[ { text => 'x' } ]]) }; $@ };
like($err, qr/data, url or web_app/, 'a button with no actionable key is refused');

# --- reply keyboards
my $rk = EV::Telegram::TDLib->reply_keyboard([
    [ { text => 'Open', web_app => 'https://example.com/' } ],
    [ { text => 'Pick a chat', request_chat  => { id => 1, channel => 1 } } ],
    [ { text => 'Pick people', request_users => { id => 2, max => 3, bot => 0 } } ],
    [ 'plain', { text => 'Number', request => 'phone' } ],
]);
is($rk->{rows}[0][0]{type}{'@type'}, 'keyboardButtonTypeWebApp',
    'reply web app button type');
is($rk->{rows}[0][0]{type}{url}, 'https://example.com/',
    'reply web app button carries the url');

my $rc = $rk->{rows}[1][0]{type};
is($rc->{'@type'}, 'keyboardButtonTypeRequestChat', 'request chat button type');
is($rc->{id}, 1, 'request chat id');
is(ref $rc->{chat_is_channel}, 'SCALAR', 'channel flag is a JSON boolean');
# a restrict flag is only set for a key the caller actually mentioned
is(${ $rc->{restrict_chat_is_forum} }, 0, 'an unmentioned constraint is not restricted');
ok(!exists $rc->{user_administrator_rights}, 'absent rights are omitted, not sent empty');

my $ru = $rk->{rows}[2][0]{type};
is($ru->{'@type'}, 'keyboardButtonTypeRequestUsers', 'request users button type');
is($ru->{max_quantity}, 3, 'request users max quantity');
is(${ $ru->{restrict_user_is_bot} }, 1, 'a mentioned constraint is restricted');
is(${ $ru->{user_is_bot} }, 0, 'even when its value is false');

is($rk->{rows}[3][0]{type}{'@type'}, 'keyboardButtonTypeText', 'plain buttons unchanged');
is($rk->{rows}[3][1]{type}{'@type'}, 'keyboardButtonTypeRequestPhoneNumber',
    'phone request buttons unchanged');

$err = do { local $@;
    eval { EV::Telegram::TDLib->reply_keyboard([[ { text => 'x', request => 'nope' } ]]) }; $@ };
like($err, qr/unknown button request/, 'an unknown request is still refused');

$err = do { local $@;
    eval { EV::Telegram::TDLib->reply_keyboard([[ { text => 'x', request_chat => 1 } ]]) }; $@ };
like($err, qr/request_chat needs a hashref/, 'a non-hashref request_chat is refused');

# --- TL bytes fields reject text rather than dying inside MIME::Base64 or
# silently sending latin-1 for a character the caller meant as UTF-8
{
    my $err = '';
    eval {
        EV::Telegram::TDLib->inline_keyboard(
            [ [ { text => 'b', data => "vote:\x{2713}" } ] ]);
        1;
    } or $err = $@;
    like $err, qr/bytes, not text/,
        'a wide character in callback button data croaks naming the caller';
    unlike $err, qr/Wide character in subroutine entry/,
        'and not from inside MIME::Base64';

    my $ok = EV::Telegram::TDLib->inline_keyboard(
        [ [ { text => 'b', data => "caf\xe9" } ] ]);
    is $ok->{rows}[0][0]{type}{'@type'}, 'inlineKeyboardButtonTypeCallback',
        'a byte string in the latin-1 range is still accepted';
}

done_testing;
