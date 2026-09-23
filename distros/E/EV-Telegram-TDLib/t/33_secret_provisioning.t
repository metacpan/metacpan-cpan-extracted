use strict;
use warnings;
use Test::More;

BEGIN { $ENV{EV_TDLIB_SHUTDOWN_TIMEOUT} = 0.1 }

use EV;
use EV::Telegram::TDLib;
use Cpanel::JSON::XS;
use MIME::Base64 ();

my @sent;
{
    no warnings 'redefine';
    *EV::Telegram::TDLib::_send = sub { push @sent, $_[1] };
}
sub last_json { $sent[-1] }
sub last_req  { Cpanel::JSON::XS->new->decode($sent[-1]) }

my $err;
my $td = EV::Telegram::TDLib->new(
    api_id => 1, api_hash => 'x', database_directory => 't/tmp-secret');

# --- secret chats: the secret chat id is its own space, not a chat_id
$td->new_secret_chat(42, sub {});
my $r = last_req();
is $r->{'@type'}, 'createNewSecretChat', 'new_secret_chat sends createNewSecretChat';
is $r->{user_id}, 42, 'user id passed through';

$td->open_secret_chat(7, sub {});
$r = last_req();
is $r->{'@type'}, 'createSecretChat', 'open_secret_chat sends createSecretChat';
is $r->{secret_chat_id}, 7, 'the secret chat id passed through';

$td->secret_chat(7, sub {});
is last_req()->{'@type'}, 'getSecretChat', 'secret_chat sends getSecretChat';

$td->close_secret_chat(7, sub {});
is last_req()->{'@type'}, 'closeSecretChat', 'close_secret_chat sends closeSecretChat';

$td->search_secret_messages('hello', limit => 5, sub {});
$r = last_req();
is $r->{'@type'}, 'searchSecretMessages', 'search_secret_messages sends its method';
is $r->{query}, 'hello', 'query passed through';
is $r->{limit}, 5, 'limit passed through';
ok !exists $r->{filter}, 'no filter unless asked for';

$td->search_secret_messages('x', filter => 'Photo', sub {});
is last_req()->{filter}{'@type'}, 'searchMessagesFilterPhoto',
    'a short filter name is expanded';

# new_encryption_key is TL bytes: passing the passphrase through verbatim made
# TDLib reject the request outright for most passphrases, and silently decode
# the base64-shaped ones into a key the caller never chose
$td->set_database_encryption_key('hunter2', sub {});
$r = last_req();
is $r->{'@type'}, 'setDatabaseEncryptionKey', 'set_database_encryption_key works';
is $r->{new_encryption_key}, 'aHVudGVyMg==', 'the key is base64 encoded';
is MIME::Base64::decode_base64($r->{new_encryption_key}), 'hunter2',
    'and decodes back to the passphrase the caller gave';

# the real TL parser is the oracle: it parses the whole request before
# deciding the method is not synchronous
{
    my $res = EV::Telegram::TDLib->execute({
        '@type' => 'setDatabaseEncryptionKey',
        new_encryption_key => $r->{new_encryption_key} });
    unlike $res->{message} // '', qr/Failed to parse/,
        'and TDLib can parse the request we built';

    my $bad = EV::Telegram::TDLib->execute({
        '@type' => 'setDatabaseEncryptionKey', new_encryption_key => 'hunter2' });
    like $bad->{message} // '', qr/Failed to parse/,
        'where the unencoded passphrase would not parse at all';
}

# session ids are int64
$td->session_accepts_secret_chats('7239857203948572039', 1, sub {});
$r = last_req();
is $r->{'@type'}, 'toggleSessionCanAcceptSecretChats', 'the session toggle works';
like last_json(), qr/"session_id":"7239857203948572039"/,
    'session id crosses as a JSON string';
like last_json(), qr/"can_accept_secret_chats":true/, 'the flag is a JSON boolean';

$err = do { local $@; eval { $td->new_secret_chat(undef, sub {}) }; $@ };
like $err, qr/required/, 'a missing user id is refused';

# --- bot provisioning
$td->create_bot('Probe', 'probe_bot', sub {});
$r = last_req();
is $r->{'@type'}, 'createBot', 'create_bot sends createBot';
is $r->{name}, 'Probe', 'name passed through';
is $r->{username}, 'probe_bot', 'username passed through';
like last_json(), qr/"via_link":false/, 'via_link is a JSON boolean';

$td->owned_bots(sub {});
is last_req()->{'@type'}, 'getOwnedBots', 'owned_bots works';

$td->bot_token(42, sub {});
$r = last_req();
is $r->{'@type'}, 'getManagedBotToken', 'bot_token sends getManagedBotToken';
like last_json(), qr/"revoke":false/, 'revoking is off by default';
$td->bot_token(42, revoke => 1, sub {});
like last_json(), qr/"revoke":true/, 'and can be turned on';

$td->bot_access_settings(42, sub {});
is last_req()->{'@type'}, 'getManagedBotAccessSettings', 'access settings getter works';

$td->set_bot_access_settings(42, { '@type' => 'botAccessSettings' }, sub {});
is last_req()->{'@type'}, 'setManagedBotAccessSettings', 'the setter works';

$err = do { local $@; eval { $td->set_bot_access_settings(42, 'nope', sub {}) }; $@ };
like $err, qr/hashref/, 'a non-hashref settings object is refused';

$td->set_updates_status(3, error => 'busy', sub {});
$r = last_req();
is $r->{'@type'}, 'setBotUpdatesStatus', 'set_updates_status works';
is $r->{pending_update_count}, 3, 'the pending count passed through';

$td->recent_inline_bots(sub {});
is last_req()->{'@type'}, 'getRecentInlineBots', 'recent_inline_bots works';

$td->similar_bots(42, sub {});
is last_req()->{'@type'}, 'getBotSimilarBots', 'similar_bots works';
$td->similar_bot_count(42, sub {});
is last_req()->{'@type'}, 'getBotSimilarBotCount', 'similar_bot_count works';
$td->open_similar_bot(42, 43, sub {});
is last_req()->{opened_bot_user_id}, 43, 'open_similar_bot passes both ids';

# --- media previews
$td->bot_media_previews(42, sub {});
is last_req()->{'@type'}, 'getBotMediaPreviews', 'previews without a language';
$td->bot_media_previews(42, language_code => 'en', sub {});
$r = last_req();
is $r->{'@type'}, 'getBotMediaPreviewInfo', 'with a language it asks for the info form';
is $r->{language_code}, 'en', 'and passes the language';

$td->add_bot_media_preview(42, { '@type' => 'inputStoryContentPhoto' }, sub {});
is last_req()->{'@type'}, 'addBotMediaPreview', 'add_bot_media_preview works';

$td->delete_bot_media_previews(42, [1, 2], sub {});
is_deeply last_req()->{file_ids}, [1, 2], 'file ids passed through';

$err = do { local $@; eval { $td->delete_bot_media_previews(42, 5, sub {}) }; $@ };
like $err, qr/arrayref/, 'a non-arrayref file list is refused';

# --- games
$td->set_game_score(-100, 55, 42, 900, sub {});
$r = last_req();
is $r->{'@type'}, 'setGameScore', 'set_game_score works';
is $r->{score}, 900, 'the score passed through';
like last_json(), qr/"edit_message":true/, 'the message is edited by default';
like last_json(), qr/"force":false/, 'and a lower score is refused unless forced';

$td->set_game_score(-100, 55, 42, 1, force => 1, edit => 0, sub {});
like last_json(), qr/"force":true/, 'force can be set';
like last_json(), qr/"edit_message":false/, 'and editing turned off';

$td->game_high_scores(-100, 55, 42, sub {});
is last_req()->{'@type'}, 'getGameHighScores', 'game_high_scores works';

$td->set_inline_game_score('abc', 42, 10, sub {});
$r = last_req();
is $r->{'@type'}, 'setInlineGameScore', 'set_inline_game_score works';
is $r->{inline_message_id}, 'abc', 'the inline id passed through';

$td->inline_game_high_scores('abc', 42, sub {});
is last_req()->{'@type'}, 'getInlineGameHighScores', 'inline_game_high_scores works';

$err = do { local $@; eval { $td->set_game_score(-100, 55, 42, undef, sub {}) }; $@ };
like $err, qr/required/, 'a missing score is refused';

done_testing;
