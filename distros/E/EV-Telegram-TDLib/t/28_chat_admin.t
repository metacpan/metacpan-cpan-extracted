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
    api_id => 1, api_hash => 'x', database_directory => 't/tmp-chat-admin');

# --- members
$td->member(-100, 42, sub {});
my $r = last_req();
is $r->{'@type'}, 'getChatMember', 'member sends getChatMember';
is $r->{member_id}{'@type'}, 'messageSenderUser', 'the member is a message sender';
is $r->{member_id}{user_id}, 42, 'with the user id';

$td->admins(-100, sub {});
is last_req()->{'@type'}, 'getChatAdministrators', 'admins sends getChatAdministrators';

$td->search_members(-100, 'bob', limit => 5, sub {});
$r = last_req();
is $r->{'@type'}, 'searchChatMembers', 'search_members sends searchChatMembers';
is $r->{query}, 'bob', 'query passed through';
is $r->{limit}, 5, 'limit passed through';
ok !exists $r->{filter}, 'no filter is sent when none was asked for';

$td->search_members(-100, '', filter => 'administrators', sub {});
is last_req()->{filter}{'@type'}, 'chatMembersFilterAdministrators',
    'a named filter becomes its TDLib type';

$err = do { local $@;
    eval { $td->search_members(-100, '', filter => 'wizards', sub {}) }; $@ };
like $err, qr/unknown member filter/, 'an unknown filter is refused';

# --- permissions: TDLib replaces the whole set, so absent means denied
$td->set_permissions(-100, { can_send_basic_messages => 1, can_send_photos => 1 }, sub {});
$r = last_req();
is $r->{'@type'}, 'setChatPermissions', 'set_permissions sends setChatPermissions';
is $r->{permissions}{'@type'}, 'chatPermissions', 'permissions are a chatPermissions';
like last_json(), qr/"can_send_basic_messages":true/, 'a granted permission is true';
like last_json(), qr/"can_send_videos":false/, 'an unmentioned one is denied, not omitted';
is scalar(grep { /^can_/ } keys %{ $r->{permissions} }), 16,
    'every permission the schema defines is sent';

# a typo must not silently take a right away
$err = do { local $@;
    eval { $td->set_permissions(-100, { can_send_photo => 1 }, sub {}) }; $@ };
like $err, qr/unknown permission/, 'a misspelled permission is refused';
like $err, qr/can_send_photo\b/, 'and is named';

$err = do { local $@; eval { $td->set_permissions(-100, 'nope', sub {}) }; $@ };
like $err, qr/hashref/, 'a non-hashref permission set is refused';

$td->set_chat_description(-100, 'A group', sub {});
$r = last_req();
is $r->{'@type'}, 'setChatDescription', 'set_chat_description sends its method';
is $r->{description}, 'A group', 'description passed through';

# --- invite links
$td->invite_link(-100, name => 'launch', limit => 10, sub {});
$r = last_req();
is $r->{'@type'}, 'createChatInviteLink', 'invite_link sends createChatInviteLink';
is $r->{name}, 'launch', 'link name passed through';
is $r->{member_limit}, 10, 'member limit passed through';
like last_json(), qr/"creates_join_request":false/, 'join request is a JSON boolean';

$td->invite_link(-100, join_request => 1, sub {});
like last_json(), qr/"creates_join_request":true/, 'and can be turned on';

$td->edit_invite_link(-100, 'https://t.me/+abc', name => 'edited', sub {});
$r = last_req();
is $r->{'@type'}, 'editChatInviteLink', 'edit_invite_link sends its method';
is $r->{invite_link}, 'https://t.me/+abc', 'the link passed through';

$td->invite_links(-100, revoked => 1, sub {});
$r = last_req();
is $r->{'@type'}, 'getChatInviteLinks', 'invite_links sends getChatInviteLinks';
like last_json(), qr/"is_revoked":true/, 'revoked filter passed through';

$td->revoke_invite_link(-100, 'https://t.me/+abc', sub {});
is last_req()->{'@type'}, 'revokeChatInviteLink', 'revoke_invite_link sends its method';

$td->replace_primary_invite_link(-100, sub {});
is last_req()->{'@type'}, 'replacePrimaryChatInviteLink',
    'replace_primary_invite_link sends its method';

$td->invite_link_members(-100, 'https://t.me/+abc', limit => 3, sub {});
$r = last_req();
is $r->{'@type'}, 'getChatInviteLinkMembers', 'invite_link_members sends its method';
is $r->{limit}, 3, 'limit passed through';

# these two take only the link: the chat is whatever it points at
$td->check_invite_link('https://t.me/+abc', sub {});
$r = last_req();
is $r->{'@type'}, 'checkChatInviteLink', 'check_invite_link sends its method';
ok !exists $r->{chat_id}, 'and sends no chat id';

$td->join_by_link('https://t.me/+abc', sub {});
$r = last_req();
is $r->{'@type'}, 'joinChatByInviteLink', 'join_by_link sends its method';
ok !exists $r->{chat_id}, 'and sends no chat id';

$err = do { local $@; eval { $td->join_by_link(undef, sub {}) }; $@ };
like $err, qr/required/, 'a missing link is refused';

# --- join requests: the other half of a join_request invite link
$td->join_requests(-100, link => 'https://t.me/+abc', sub {});
$r = last_req();
is $r->{'@type'}, 'getChatJoinRequests', 'join_requests sends getChatJoinRequests';
is $r->{invite_link}, 'https://t.me/+abc', 'the link filter passed through';
is $r->{limit}, 100, 'a default limit is sent';

$td->process_join_request(-100, 42, sub {});
$r = last_req();
is $r->{'@type'}, 'processChatJoinRequest', 'process_join_request sends its method';
is $r->{user_id}, 42, 'user id passed through';
like last_json(), qr/"approve":true/, 'approving is the default';

$td->process_join_request(-100, 42, 0, sub {});
like last_json(), qr/"approve":false/, 'and it can decline';

$td->process_join_requests(-100, 1, link => 'https://t.me/+abc', sub {});
$r = last_req();
is $r->{'@type'}, 'processChatJoinRequests', 'the bulk form sends its method';
is $r->{invite_link}, 'https://t.me/+abc', 'scoped to one link';

# the update carries the request nested; the handler flattens it
my @jr;
$td->on_join_request(sub { push @jr, $_[0] });
my $J = Cpanel::JSON::XS->new;
$td->inject_raw($J->encode({ '@type' => 'updateNewChatJoinRequest',
    chat_id => -100, user_chat_id => 7, invite_link => { invite_link => 'x' },
    request => { '@type' => 'chatJoinRequest', user_id => 42, date => 1, bio => 'hi' } }));
is scalar @jr, 1, 'on_join_request fired';
is $jr[0]{user_id}, 42, 'the nested user id is lifted out';
is $jr[0]{bio}, 'hi', 'and the bio';
is $jr[0]{chat_id}, -100, 'with the chat it belongs to';

$err = do { local $@; eval { $td->process_join_request(undef, 42, sub {}) }; $@ };
like $err, qr/required/, 'a missing chat id is refused';

done_testing;
