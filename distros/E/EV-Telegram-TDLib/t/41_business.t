use strict;
use warnings;
use Test::More;

BEGIN { $ENV{EV_TDLIB_SHUTDOWN_TIMEOUT} = 0.1 }

use EV;
use EV::Telegram::TDLib;
use Cpanel::JSON::XS;

# This plane cannot be exercised against a live server without a Telegram
# Business subscription, so these offline assertions are its only oracle:
# every nested object shape is checked explicitly rather than by shape alone.
my @sent;
{
    no warnings 'redefine';
    *EV::Telegram::TDLib::_send = sub { push @sent, $_[1] };
}
sub last_json { $sent[-1] }
sub last_req  { Cpanel::JSON::XS->new->utf8->decode($sent[-1]) }

my $td = EV::Telegram::TDLib->new(
    api_id => 1, api_hash => 'x', database_directory => 't/tmp-business');

# --- connections
$td->business_connection('conn_1', sub {});
my $r = last_req();
is $r->{'@type'}, 'getBusinessConnection', 'business_connection';
is $r->{connection_id}, 'conn_1', 'connection_id is a string, not numified';

$td->connected_bot(sub {});
is last_req()->{'@type'}, 'getBusinessConnectedBot', 'connected_bot takes no arguments';

$td->set_connected_bot(7, rights => { can_reply => 1, can_read_messages => 1 },
                       recipients => { select_existing_chats => 1 }, sub {});
$r = last_req();
is $r->{'@type'}, 'setBusinessConnectedBot', 'set_connected_bot';
is $r->{bot}{'@type'}, 'businessConnectedBot', 'wrapped in businessConnectedBot';
is $r->{bot}{bot_user_id}, 7, 'bot id is int53 and numeric';
is $r->{bot}{recipients}{'@type'}, 'businessRecipients', 'nested businessRecipients';
is $r->{bot}{rights}{'@type'}, 'businessBotRights', 'nested businessBotRights';
like last_json(), qr/"can_reply":true/, 'a granted right is true';
like last_json(), qr/"can_edit_bio":false/, 'an ungranted right is present and false';
like last_json(), qr/"select_existing_chats":true/, 'recipient flags carried';

# the POD promises a typo is refused rather than ignored, which is the whole
# point of naming the flags: a silently dropped right grants nothing
{
    my $e = do { local $@;
        eval { $td->set_connected_bot(7, rights => { can_time_travel => 1 },
                                      sub {}) }; $@ };
    like $e, qr/unknown bot right 'can_time_travel'/,
        'an unknown bot right croaks rather than being dropped';
    $e = do { local $@;
        eval { $td->set_connected_bot(7, recipients => { select_nobody => 1 },
                                      sub {}) }; $@ };
    like $e, qr/unknown recipient option 'select_nobody'/,
        'and so does an unknown recipient option';
}

$td->confirm_connected_bot(7, sub {});
is last_req()->{'@type'}, 'confirmBusinessConnectedBot', 'confirm_connected_bot';

$td->delete_connected_bot(7, sub {});
is last_req()->{'@type'}, 'deleteBusinessConnectedBot', 'delete_connected_bot';

$td->pause_connected_bot(-100, 1, sub {});
$r = last_req();
is $r->{'@type'}, 'toggleBusinessConnectedBotChatIsPaused', 'pause_connected_bot';
like last_json(), qr/"is_paused":true/, 'paused by default';

$td->remove_connected_bot_from_chat(-100, sub {});
is last_req()->{'@type'}, 'removeBusinessConnectedBotFromChat',
    'remove_connected_bot_from_chat';

# --- chat links carry a formattedText
$td->business_chat_links(sub {});
is last_req()->{'@type'}, 'getBusinessChatLinks', 'business_chat_links';

$td->create_business_chat_link('hello there', title => 'Greeting', sub {});
$r = last_req();
is $r->{'@type'}, 'createBusinessChatLink', 'create_business_chat_link';
is $r->{link_info}{'@type'}, 'inputBusinessChatLink', 'wrapped in inputBusinessChatLink';
is $r->{link_info}{text}{'@type'}, 'formattedText', 'the text is a formattedText';
is $r->{link_info}{text}{text}, 'hello there', 'with the text given';
is $r->{link_info}{title}, 'Greeting', 'and the title';

$td->edit_business_chat_link('https://t.me/x', 'new text', sub {});
is last_req()->{'@type'}, 'editBusinessChatLink', 'edit_business_chat_link';

$td->delete_business_chat_link('https://t.me/x', sub {});
is last_req()->{'@type'}, 'deleteBusinessChatLink', 'delete_business_chat_link';

$td->business_chat_link_info('mylink', sub {});
is last_req()->{'@type'}, 'getBusinessChatLinkInfo', 'business_chat_link_info';

# --- account settings
$td->set_business_account_name('conn_1', 'Ada', 'Lovelace', sub {});
$r = last_req();
is $r->{'@type'}, 'setBusinessAccountName', 'set_business_account_name';
is $r->{first_name}, 'Ada', 'first name carried';
is $r->{last_name}, 'Lovelace', 'last name carried';

$td->set_business_account_bio('conn_1', 'hi', sub {});
is last_req()->{'@type'}, 'setBusinessAccountBio', 'set_business_account_bio';

$td->set_business_account_username('conn_1', 'ada', sub {});
is last_req()->{'@type'}, 'setBusinessAccountUsername', 'set_business_account_username';

$td->business_account_star_amount('conn_1', sub {});
is last_req()->{'@type'}, 'getBusinessAccountStarAmount', 'business_account_star_amount';

# --- away and greeting messages nest recipients plus a schedule union
$td->set_away_message(3, schedule => 'always',
                      recipients => { select_contacts => 1 }, sub {});
$r = last_req();
is $r->{'@type'}, 'setBusinessAwayMessageSettings', 'set_away_message';
is $r->{away_message_settings}{'@type'}, 'businessAwayMessageSettings',
    'wrapped in businessAwayMessageSettings';
is $r->{away_message_settings}{shortcut_id}, 3, 'shortcut id is int32 and numeric';
is $r->{away_message_settings}{schedule}{'@type'},
    'businessAwayMessageScheduleAlways', 'the always schedule';
is $r->{away_message_settings}{recipients}{'@type'}, 'businessRecipients',
    'nested recipients';

$td->set_away_message(3, schedule => 'outside_opening_hours', sub {});
is last_req()->{away_message_settings}{schedule}{'@type'},
    'businessAwayMessageScheduleOutsideOfOpeningHours', 'the opening-hours schedule';

$td->set_away_message(3, schedule => { start => 1700000000, end => 1700086400 }, sub {});
$r = last_req();
is $r->{away_message_settings}{schedule}{'@type'},
    'businessAwayMessageScheduleCustom', 'a custom schedule';
is $r->{away_message_settings}{schedule}{start_date}, 1700000000, 'with its start date';

eval { $td->set_away_message(3, schedule => { start => 100, end => 200 }, sub {}) };
like $@, qr/Unix time, not a duration/, 'a duration in the custom schedule croaks';

eval { $td->set_away_message(3, schedule => 'whenever', sub {}) };
like $@, qr/schedule/, 'an unknown schedule croaks';

$td->set_greeting_message(4, inactivity_days => 7, sub {});
$r = last_req();
is $r->{'@type'}, 'setBusinessGreetingMessageSettings', 'set_greeting_message';
is $r->{greeting_message_settings}{inactivity_days}, 7, 'inactivity days carried';

# --- opening hours is a vector of interval objects plus a time zone
$td->set_opening_hours('Europe/Berlin', [ [540, 1020], { start => 1, end => 2 } ], sub {});
$r = last_req();
is $r->{'@type'}, 'setBusinessOpeningHours', 'set_opening_hours';
is $r->{opening_hours}{'@type'}, 'businessOpeningHours', 'wrapped in businessOpeningHours';
is $r->{opening_hours}{time_zone_id}, 'Europe/Berlin', 'time zone carried';
is $r->{opening_hours}{opening_hours}[0]{'@type'}, 'businessOpeningHoursInterval',
    'each interval is an object';
is $r->{opening_hours}{opening_hours}[0]{start_minute}, 540, 'arrayref form works';
is $r->{opening_hours}{opening_hours}[1]{start_minute}, 1, 'hashref form works too';

$td->set_business_location('Berlin', latitude => 52.5, longitude => 13.4, sub {});
$r = last_req();
is $r->{'@type'}, 'setBusinessLocation', 'set_business_location';
is $r->{location}{'@type'}, 'businessLocation', 'wrapped in businessLocation';
is $r->{location}{address}, 'Berlin', 'address carried';

$td->set_start_page(title => 'Hi', message => 'Welcome', sub {});
$r = last_req();
is $r->{'@type'}, 'setBusinessStartPage', 'set_start_page';
is $r->{start_page}{'@type'}, 'inputBusinessStartPage', 'wrapped in inputBusinessStartPage';

$td->business_features(sub {});
is last_req()->{'@type'}, 'getBusinessFeatures', 'business_features';

# --- sending as a business account: flat fields, no options, int64 effect_id
$td->send_business_message('conn_1', -100, 'hello', sub {});
$r = last_req();
is $r->{'@type'}, 'sendBusinessMessage', 'send_business_message';
is $r->{business_connection_id}, 'conn_1', 'connection id carried as a string';
is $r->{input_message_content}{'@type'}, 'inputMessageText', 'text content reused';
ok !exists $r->{options}, 'no messageSendOptions: sendBusinessMessage has no such field';
ok !exists $r->{topic_id}, 'and no topic_id either';
like last_json(), qr/"disable_notification":false/, 'disable_notification is flat';
like last_json(), qr/"protect_content":false/, 'protect_content is flat';

$td->send_business_message('conn_1', -100, 'hi', effect_id => '5104841245755180586', sub {});
like last_json(), qr/"effect_id":"5104841245755180586"/,
    'effect_id is int64 and crosses as a string';

# the POD says these take no wait, schedule or topic; sendBusinessMessage has
# nowhere to put them, so accepting one would silently mean something else
for my $k (qw(wait schedule topic)) {
    for my $m (qw(send_business_message send_business_file)) {
        my $e = do { local $@; eval {
            $td->$m('conn_1', -100, 'x', $k => 1, sub {}) }; $@ };
        like $e, qr/cannot take $k/, "$m refuses $k";
    }
}

$td->edit_business_message_text('conn_1', -100, 5, 'edited', sub {});
$r = last_req();
is $r->{'@type'}, 'editBusinessMessageText', 'edit_business_message_text';
is $r->{input_message_content}{'@type'}, 'inputMessageText', 'with text content';

$td->read_business_message('conn_1', -100, 5, sub {});
is last_req()->{'@type'}, 'readBusinessMessage', 'read_business_message';

$td->delete_business_messages('conn_1', [5, 6], sub {});
$r = last_req();
is $r->{'@type'}, 'deleteBusinessMessages', 'delete_business_messages';
is_deeply $r->{message_ids}, [5, 6], 'message ids are int53 and stay numeric';

# --- quick replies
$td->load_quick_replies(sub {});
is last_req()->{'@type'}, 'loadQuickReplyShortcuts', 'load_quick_replies';

$td->load_quick_reply_messages(3, sub {});
is last_req()->{'@type'}, 'loadQuickReplyShortcutMessages', 'load_quick_reply_messages';

$td->add_quick_reply_message('greet', 'hello', sub {});
$r = last_req();
is $r->{'@type'}, 'addQuickReplyShortcutMessage', 'add_quick_reply_message';
is $r->{shortcut_name}, 'greet', 'shortcut name carried';
is $r->{input_message_content}{'@type'}, 'inputMessageText', 'with text content';

$td->edit_quick_reply_message(3, 5, 'changed', sub {});
is last_req()->{'@type'}, 'editQuickReplyMessage', 'edit_quick_reply_message';

$td->delete_quick_reply(3, sub {});
is last_req()->{'@type'}, 'deleteQuickReplyShortcut', 'delete_quick_reply';

$td->delete_quick_reply_messages(3, [5], sub {});
is last_req()->{'@type'}, 'deleteQuickReplyShortcutMessages',
    'delete_quick_reply_messages';

$td->set_quick_reply_name(3, 'greet2', sub {});
is last_req()->{'@type'}, 'setQuickReplyShortcutName', 'set_quick_reply_name';

$td->reorder_quick_replies([3, 4], sub {});
$r = last_req();
is $r->{'@type'}, 'reorderQuickReplyShortcuts', 'reorder_quick_replies';
is_deeply $r->{shortcut_ids}, [3, 4], 'shortcut ids are int32 and stay numeric';

$td->send_quick_reply(-100, 3, sub {});
is last_req()->{'@type'}, 'sendQuickReplyShortcutMessages', 'send_quick_reply';

# --- updates must reach their hooks, which proves the %UPDATES merge is wired
my ($conn, $bmsg);
$td->on_business_connection(sub { $conn = $_[0] });
$td->on_business_message(sub { $bmsg = $_[0] });

$td->inject_raw(
    q({"@type":"updateBusinessConnection","connection":{"@type":"businessConnection","id":"conn_9"}}));
is $conn->{id}, 'conn_9', 'updateBusinessConnection reaches on_business_connection';

$td->inject_raw(
    q({"@type":"updateNewBusinessMessage","connection_id":"conn_9",)
  . q("message":{"@type":"businessMessage","message":{"id":7}}}));
ok $bmsg, 'updateNewBusinessMessage reaches on_business_message';
is $bmsg->{connection_id}, 'conn_9', 'and carries the connection id';
# the payload is a businessMessage, so the message is one level deeper than
# on_message's -- documenting it as "message" alone sent readers to undef
is $bmsg->{message}{'@type'}, 'businessMessage', 'the message is a businessMessage';
is $bmsg->{message}{message}{id}, 7, 'with the message itself inside it';

# --- a parse_mode failure must reach the caller, not be embedded in the request
{
    my $n = scalar @sent;
    my $err;
    $td->create_business_chat_link('*bold', parse_mode => 'markdown',
                                   sub { $err = $_[1] });
    is scalar(@sent), $n,
        'create_business_chat_link sends nothing when the text fails to parse';
    is $err->{'@type'}, 'error', 'and reports the parse error to the caller';

    $n = scalar @sent;
    undef $err;
    $td->edit_business_chat_link('https://t.me/x', '*bold', parse_mode => 'markdown',
                                 sub { $err = $_[1] });
    is scalar(@sent), $n,
        'edit_business_chat_link sends nothing when the text fails to parse';
    is $err->{'@type'}, 'error', 'and reports the parse error to the caller';
}

done_testing;
