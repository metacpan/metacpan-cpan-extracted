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
    api_id => 1, api_hash => 'x', database_directory => 't/tmp-house');

# --- muting must not disturb the other notification choices
$td->mute(-100, 3600, sub {});
my $r = last_req();
is $r->{'@type'}, 'setChatNotificationSettings', 'mute sends setChatNotificationSettings';
is $r->{notification_settings}{mute_for}, 3600, 'mute duration passed through';
like last_json(), qr/"use_default_mute_for":false/, 'the mute value is ours';
like last_json(), qr/"use_default_sound":true/, 'but the sound is left at its default';
like last_json(), qr/"use_default_show_preview":true/, 'and so is the preview';

$td->mute(-100, sub {});
cmp_ok last_req()->{notification_settings}{mute_for}, '>', 31000000,
    'mute with no duration means indefinitely';

$td->unmute(-100, sub {});
is last_req()->{notification_settings}{mute_for}, 0, 'unmute clears the mute';

# TDLib rebuilds every setting from the request, so "use the default" for the
# rest reset a chat's own sound and preview: a cached chat keeps them
$td->inject_raw(q({"@type":"updateNewChat","chat":{"@type":"chat","id":-200,)
              . q("notification_settings":{"@type":"chatNotificationSettings",)
              . q("use_default_mute_for":true,"mute_for":0,)
              . q("use_default_sound":false,"sound_id":"6012345678901234567",)
              . q("use_default_show_preview":false,"show_preview":false}}}));
$td->mute(-200, 3600, sub {});
my $ns = last_req()->{notification_settings};
is $ns->{mute_for}, 3600, 'a cached chat is muted';
is $ns->{sound_id}, '6012345678901234567', 'and keeps its own sound';
like last_json(), qr/"use_default_sound":false/, 'which is still not the default';
like last_json(), qr/"use_default_show_preview":false/, 'and keeps its preview choice';
like last_json(), qr/"show_preview":false/, 'with previews still off';

# an id read without a chomp is accepted everywhere; the cache lookup missed
# it and fell back to the defaults, the very reset above
$td->mute(" -200\n", 60, sub {});
is last_req()->{notification_settings}{sound_id}, '6012345678901234567',
    'a padded chat id finds the cached settings too';

# --- chat list membership
$td->archive(-100, sub {});
$r = last_req();
is $r->{'@type'}, 'addChatToList', 'archive sends addChatToList';
is $r->{chat_list}{'@type'}, 'chatListArchive', 'to the archive list';

$td->unarchive(-100, sub {});
is last_req()->{chat_list}{'@type'}, 'chatListMain', 'unarchive returns it to main';

$td->pin_chat(-100, sub {});
$r = last_req();
is $r->{'@type'}, 'toggleChatIsPinned', 'pin_chat sends toggleChatIsPinned';
like last_json(), qr/"is_pinned":true/, 'pinning defaults to true';
is $r->{chat_list}{'@type'}, 'chatListMain', 'and defaults to the main list';

$td->pin_chat(-100, 1, list => 'archive', sub {});
is last_req()->{chat_list}{'@type'}, 'chatListArchive', 'a named list is honoured';

# a numeric list is a folder id
$td->pin_chat(-100, 1, list => 7, sub {});
$r = last_req();
is $r->{chat_list}{'@type'}, 'chatListFolder', 'a numeric list is a folder';
is $r->{chat_list}{chat_folder_id}, 7, 'with that folder id';

$err = do { local $@; eval { $td->chats(list => 'nope', sub {}) }; $@ };
like $err, qr/unknown chat list/, 'an unknown list name is refused';

$td->mark_unread(-100, sub {});
$r = last_req();
is $r->{'@type'}, 'toggleChatIsMarkedAsUnread', 'mark_unread sends its method';
like last_json(), qr/"is_marked_as_unread":true/, 'marking defaults to true';

$td->chats(limit => 25, sub {});
$r = last_req();
is $r->{'@type'}, 'getChats', 'chats sends getChats';
is $r->{limit}, 25, 'limit passed through';

$td->search_all('invoice', limit => 10, sub {});
$r = last_req();
is $r->{'@type'}, 'searchMessages', 'search_all sends searchMessages';
is $r->{query}, 'invoice', 'query passed through';
is $r->{limit}, 10, 'limit passed through';
# a null list is every chat; defaulting to main skipped the archive
like last_json(), qr/"chat_list":null/, 'search_all searches every chat by default';
$td->search_all('invoice', list => 'archive', sub {});
is last_req()->{chat_list}{'@type'}, 'chatListArchive', 'and can be narrowed to the archive';
$err = do { local $@; eval { $td->search_all('invoice', list => 3, sub {}) }; $@ };
like $err, qr/cannot search a folder/, 'a folder, which TDLib cannot search, croaks';

$err = do { local $@; eval { $td->search_all(undef, sub {}) }; $@ };
like $err, qr/required/, 'a missing query is refused';

# --- polls: creating one was already possible, answering and stopping were not
$td->answer_poll(-100, 55, [0, 2], sub {});
$r = last_req();
is $r->{'@type'}, 'setPollAnswer', 'answer_poll sends setPollAnswer';
is_deeply $r->{option_ids}, [0, 2], 'option ids passed through';

$td->stop_poll(-100, 55, sub {});
is last_req()->{'@type'}, 'stopPoll', 'stop_poll sends stopPoll';

$err = do { local $@; eval { $td->answer_poll(-100, 55, 'one', sub {}) }; $@ };
like $err, qr/arrayref/, 'a non-arrayref answer is refused';

# --- contacts
$td->contacts(sub {});
is last_req()->{'@type'}, 'getContacts', 'contacts sends getContacts';

$td->add_contact(42, first_name => 'Bob', phone => '+15550001', sub {});
$r = last_req();
is $r->{'@type'}, 'addContact', 'add_contact sends addContact';
is $r->{contact}{'@type'}, 'importedContact', 'a contact object is built';
is $r->{contact}{first_name}, 'Bob', 'first name passed through';
ok !exists $r->{contact}{user_id}, 'the user id stays at the top level';
like last_json(), qr/"share_phone_number":false/, 'phone sharing is a JSON boolean';

$td->remove_contacts([1, 2], sub {});
$r = last_req();
is $r->{'@type'}, 'removeContacts', 'remove_contacts sends removeContacts';
is_deeply $r->{user_ids}, [1, 2], 'user ids passed through';

$td->search_contacts('bob', sub {});
is last_req()->{'@type'}, 'searchContacts', 'search_contacts sends searchContacts';

$td->import_contacts([ { phone => '+15550002', first_name => 'Ann' } ], sub {});
$r = last_req();
is $r->{'@type'}, 'importContacts', 'import_contacts sends importContacts';
is $r->{contacts}[0]{phone_number}, '+15550002', 'the phone number is imported';

$err = do { local $@; eval { $td->import_contacts([ 'nope' ], sub {}) }; $@ };
like $err, qr/hashref/, 'a non-hashref contact is refused';

# --- sessions
$td->sessions(sub {});
is last_req()->{'@type'}, 'getActiveSessions', 'sessions sends getActiveSessions';

# session ids are int64 and must not lose precision as numbers
$td->terminate_session('7239857203948572039', sub {});
is last_req()->{'@type'}, 'terminateSession', 'terminate_session sends its method';
like last_json(), qr/"session_id":"7239857203948572039"/,
    'session id crosses as a JSON string';

$td->terminate_other_sessions(sub {});
is last_req()->{'@type'}, 'terminateAllOtherSessions', 'terminate_other_sessions works';

$td->set_session_ttl(30, sub {});
$r = last_req();
is $r->{'@type'}, 'setInactiveSessionTtl', 'set_session_ttl sends its method';
is $r->{inactive_session_ttl_days}, 30, 'the ttl passed through';

$err = do { local $@; eval { $td->terminate_session(undef, sub {}) }; $@ };
like $err, qr/required/, 'a missing session id is refused';

done_testing;
