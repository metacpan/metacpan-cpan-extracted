use strict;
use warnings;
use Test::More;

BEGIN { $ENV{EV_TDLIB_SHUTDOWN_TIMEOUT} = 0.1 }

use EV;
use EV::Telegram::TDLib;
use Cpanel::JSON::XS;

my @sent;
{
    no warnings 'redefine';
    *EV::Telegram::TDLib::_send = sub { push @sent, $_[1] };
}
sub last_json { $sent[-1] }
sub last_req  { Cpanel::JSON::XS->new->decode($sent[-1]) }

my $err;
my $td = EV::Telegram::TDLib->new(
    api_id => 1, api_hash => 'x', database_directory => 't/tmp-final');

# --- message utilities
$td->message(-100, 55, sub {});
is last_req()->{'@type'}, 'getMessage', 'message sends getMessage';

$td->messages(-100, [55, 56], sub {});
my $r = last_req();
is $r->{'@type'}, 'getMessages', 'messages sends getMessages';
is_deeply $r->{message_ids}, [55, 56], 'message ids passed through';

$td->replied_message(-100, 55, sub {});
is last_req()->{'@type'}, 'getRepliedMessage', 'replied_message sends its method';

$td->message_link(-100, 55, in_thread => 1, sub {});
$r = last_req();
is $r->{'@type'}, 'getMessageLink', 'message_link sends getMessageLink';
like last_json(), qr/"in_message_thread":true/, 'thread flag is a JSON boolean';

$td->message_link_info('https://t.me/c/1/2', sub {});
$r = last_req();
is $r->{'@type'}, 'getMessageLinkInfo', 'message_link_info sends its method';
is $r->{url}, 'https://t.me/c/1/2', 'the url passed through';

# TDLib cannot count unfiltered, so an omitted filter must fail here rather
# than becoming a request that always errors
$td->message_count(-100, filter => 'Photo', topic => 7, sub {});
$r = last_req();
is $r->{'@type'}, 'getChatMessageCount', 'message_count sends its method';
is $r->{filter}{'@type'}, 'searchMessagesFilterPhoto', 'a short filter name is expanded';
is $r->{topic_id}{forum_topic_id}, 7, 'and can be scoped to a topic';

$td->message_count(-100, filter => 'searchMessagesFilterVideo', sub {});
is last_req()->{filter}{'@type'}, 'searchMessagesFilterVideo',
    'a full filter name is passed through';

$err = do { local $@; eval { $td->message_count(-100, sub {}) }; $@ };
like $err, qr/needs a filter/, 'counting without a filter is refused';

$err = do { local $@; eval { $td->delete_messages(-100, 'nope', sub {}) }; $@ };
like $err, qr/arrayref/, 'delete_messages refuses a non-arrayref';

# --- reactions
$td->available_reactions(-100, 55, sub {});
is last_req()->{'@type'}, 'getMessageAvailableReactions', 'available_reactions works';

$td->message_reactions(-100, 55, emoji => "\x{1F44D}", sub {});
$r = last_req();
is $r->{'@type'}, 'getMessageAddedReactions', 'message_reactions works';
is $r->{reaction_type}{'@type'}, 'reactionTypeEmoji', 'an emoji filter is typed';

$td->message_reactions(-100, 55, sub {});
ok !exists last_req()->{reaction_type}, 'and is omitted when not given';

$td->set_default_reaction("\x{1F44D}", sub {});
is last_req()->{'@type'}, 'setDefaultReactionType', 'set_default_reaction works';

$td->set_chat_reactions(-100, 'all', sub {});
is last_req()->{available_reactions}{'@type'}, 'chatAvailableReactionsAll',
    "'all' allows every reaction";

$td->set_chat_reactions(-100, ["\x{1F44D}", "\x{1F44E}"], sub {});
$r = last_req();
is $r->{available_reactions}{'@type'}, 'chatAvailableReactionsSome',
    'a list restricts them';
is scalar @{ $r->{available_reactions}{reactions} }, 2, 'with both emoji';

$err = do { local $@; eval { $td->set_chat_reactions(-100, 'some', sub {}) }; $@ };
like $err, qr/'all' or an arrayref/, 'an unknown reaction spec is refused';

# --- drafts
$td->set_draft(-100, 'half a thought', sub {});
$r = last_req();
is $r->{'@type'}, 'setChatDraftMessage', 'set_draft sends setChatDraftMessage';
is $r->{draft_message}{content}{'@type'}, 'draftMessageContentText',
    'draft content is a draftMessageContentText';
is $r->{draft_message}{content}{text}{text}, 'half a thought', 'the text is in the draft';

$td->set_draft(-100, '', sub {});
ok !exists last_req()->{draft_message}, 'an empty text clears the draft';

$td->clear_drafts(sub {});
is last_req()->{'@type'}, 'clearAllDraftMessages', 'clear_drafts works';

# --- notification scopes: every field is sent outright, stories untouched
$td->mute_scope('groups', 3600, sub {});
$r = last_req();
is $r->{'@type'}, 'setScopeNotificationSettings', 'mute_scope sends its method';
is $r->{scope}{'@type'}, 'notificationSettingsScopeGroupChats', 'with the right scope';
is $r->{notification_settings}{mute_for}, 3600, 'and the duration';
is_deeply [ sort keys %{ $r->{notification_settings} } ],
    [ sort qw(@type mute_for sound_id show_preview use_default_mute_stories
              mute_stories story_sound_id show_story_poster
              disable_pinned_message_notifications disable_mention_notifications) ],
    'all nine scopeNotificationSettings fields are sent';
like last_json(), qr/"use_default_mute_stories":true/,
    'stories stay at their default setting';
# -1, not 0: the TL says 0 disables the sound and -1 asks for the app
# default, so defaulting to 0 silenced the scope for anyone who only wanted
# to mute it for a while
is $r->{notification_settings}{story_sound_id}, "-1",
    'story sound id defaults to the app default, as an int64 string';
is $r->{notification_settings}{sound_id}, "-1",
    'and so does the message sound';
ok !exists $r->{notification_settings}{use_default_mute_for},
    'mute_for itself has no use_default flag, unlike a single chat';

$err = do { local $@; eval { $td->mute_scope('everything', 1, sub {}) }; $@ };
like $err, qr/unknown notification scope/, 'an unknown scope is refused';

$td->scope_settings('channels', sub {});
is last_req()->{scope}{'@type'}, 'notificationSettingsScopeChannelChats',
    'scope_settings resolves the scope too';

$td->reset_notifications(sub {});
is last_req()->{'@type'}, 'resetAllNotificationSettings', 'reset_notifications works';

# --- profile
$td->set_birthdate(day => 1, month => 4, year => 1990, sub {});
$r = last_req();
is $r->{'@type'}, 'setBirthdate', 'set_birthdate sends its method';
is $r->{birthdate}{month}, 4, 'the month passed through';

$td->set_birthdate(sub {});
ok !exists last_req()->{birthdate}, 'no birthdate clears it';

$td->set_accent_color(5, sub {});
is last_req()->{accent_color_id}, 5, 'set_accent_color passes the colour';

$td->profile_photos(42, sub {});
is last_req()->{'@type'}, 'getUserProfilePhotos', 'profile_photos works';

$td->delete_profile_photo('7239857203948572039', sub {});
like last_json(), qr/"profile_photo_id":"7239857203948572039"/,
    'photo id crosses as a JSON string';

$td->blocked(sub {});
$r = last_req();
is $r->{'@type'}, 'getBlockedMessageSenders', 'blocked works';
is $r->{block_list}{'@type'}, 'blockListMain', 'defaulting to the main block list';

# --- bot plane completion: the answers to request_chat / request_users
$td->share_chat_with_bot(-100, 55, 1, -200, sub {});
$r = last_req();
is $r->{'@type'}, 'shareChatWithBot', 'share_chat_with_bot sends its method';
is $r->{source}{'@type'}, 'keyboardButtonSourceMessage', 'the source is the message';
is $r->{source}{message_id}, 55, 'carrying the message id';
is $r->{button_id}, 1, 'and the button id';
is $r->{shared_chat_id}, -200, 'and the chat being shared';

$td->share_users_with_bot(-100, 55, 2, [7, 8], sub {});
$r = last_req();
is $r->{'@type'}, 'shareUsersWithBot', 'share_users_with_bot sends its method';
is_deeply $r->{shared_user_ids}, [7, 8], 'with the users being shared';

$err = do { local $@; eval { $td->share_users_with_bot(-100, 55, 2, 7, sub {}) }; $@ };
like $err, qr/arrayref/, 'a non-arrayref user list is refused';

$td->allow_bot_messages(42, sub {});
is last_req()->{'@type'}, 'allowBotToSendMessages', 'allow_bot_messages works';

$td->can_bot_message(42, sub {});
is last_req()->{'@type'}, 'canBotSendMessages', 'can_bot_message works';

$td->callback_query_message(-100, 55, '9182736450192837465', sub {});
$r = last_req();
is $r->{'@type'}, 'getCallbackQueryMessage', 'callback_query_message works';
like last_json(), qr/"callback_query_id":"9182736450192837465"/,
    'callback query id crosses as a JSON string';

$td->check_bot_username('probe_bot', sub {});
is last_req()->{'@type'}, 'checkBotUsername', 'check_bot_username works';

$td->toggle_bot_username(42, 'alt_bot', sub {});
$r = last_req();
is $r->{'@type'}, 'toggleBotUsernameIsActive', 'toggle_bot_username works';
like last_json(), qr/"is_active":true/, 'activating is the default';

done_testing;
