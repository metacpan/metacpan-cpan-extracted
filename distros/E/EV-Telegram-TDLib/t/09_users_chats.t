use strict;
use warnings;
use Test::More;

# _send is stubbed here, so a close can never complete and the END block
# would spend its whole default budget waiting for one
BEGIN { $ENV{EV_TDLIB_SHUTDOWN_TIMEOUT} = 0.1 }

use EV;
use EV::Telegram::TDLib;

my @sent;
{
    no warnings 'redefine';
    *EV::Telegram::TDLib::_send = sub { push @sent, $_[1]; };
}

my (@users_seen, @chats_seen, @updates, $title_seen_by_on_update);
my $td = EV::Telegram::TDLib->new(
    api_id   => 1,
    api_hash => 'x',
    auto_auth => 0,
    database_directory => 't/tmp-users-chats',
    on_user   => sub { push @users_seen, $_[0] },
);
$td->on_chat(sub { push @chats_seen, $_[0] });
$td->on_update(sub {
    my ($obj) = @_;
    push @updates, $obj;
    if (($obj->{'@type'} // '') eq 'updateChatTitle') {
        my $cached = $td->chat($obj->{chat_id});
        $title_seen_by_on_update = $cached ? $cached->{title} : undef;
    }
});

$td->inject_raw(q({"@type":"updateUser","user":{"@type":"user","id":42,"first_name":"Ada"}}));
is($td->user(42)->{first_name}, 'Ada', 'user cached from updateUser');
is(scalar @users_seen, 1, 'on_user fired from the constructor option');
is($users_seen[0]{id}, 42, 'on_user got the user');
is($updates[-1]{'@type'}, 'updateUser', 'cached updates still reach on_update');

is($td->user(999), undef, 'unknown user is undef, not an exception');
is($td->user("+42\n") && $td->user("+42\n")->{first_name}, 'Ada',
    'a padded or signed user id reads the same cached user');

$td->inject_raw(q({"@type":"updateNewChat","chat":{"@type":"chat","id":-100123,"title":"Room","positions":[{"@type":"chatPosition","list":{"@type":"chatListMain"},"order":100}]}}));
is($td->chat(-100123)->{title}, 'Room', 'chat cached from updateNewChat');
is(scalar @chats_seen, 1, 'on_chat fired from the setter');
is($chats_seen[0]{id}, -100123, 'on_chat got the chat');

$td->inject_raw(q({"@type":"updateChatTitle","chat_id":-100123,"title":"Renamed"}));
is($td->chat(-100123)->{title}, 'Renamed', 'updateChatTitle patches the cache');
is($title_seen_by_on_update, 'Renamed', 'the cache is patched before on_update runs');

is($td->chat(999), undef, 'unknown chat is undef, not an exception');
is($td->chat(" -100123\n") && $td->chat(" -100123\n")->{title}, 'Renamed',
    'a padded id, accepted everywhere else, reads the same cached chat');
is($td->chat('not an id'), undef, 'and a non-id is simply not found');

$td->inject_raw(q({"@type":"updateChatTitle","chat_id":-777,"title":"Ghost"}));
is($td->chat(-777), undef, 'patching an unknown chat does not create it');

$td->inject_raw(q({"@type":"updateChatLastMessage","chat_id":-100123,"last_message":{"@type":"message","id":1048576,"chat_id":-100123},"positions":[{"@type":"chatPosition","list":{"@type":"chatListMain"},"order":200}]}));
is($td->chat(-100123)->{last_message}{id}, 1048576, 'updateChatLastMessage patches last_message');
is($td->chat(-100123)->{title}, 'Renamed', 'a patch does not replace the cached chat');
is(scalar @{ $td->chat(-100123)->{positions} }, 1, 'one position per list');
is($td->chat(-100123)->{positions}[0]{order}, 200, 'the position for the list was updated');

$td->inject_raw(q({"@type":"updateChatPosition","chat_id":-100123,"position":{"@type":"chatPosition","list":{"@type":"chatListArchive"},"order":50}}));
is(scalar @{ $td->chat(-100123)->{positions} }, 2, 'updateChatPosition adds a second list');

$td->inject_raw(q({"@type":"updateChatPosition","chat_id":-100123,"position":{"@type":"chatPosition","list":{"@type":"chatListArchive"},"order":0}}));
is(scalar @{ $td->chat(-100123)->{positions} }, 1, 'order 0 removes the position');
is($td->chat(-100123)->{positions}[0]{list}{'@type'}, 'chatListMain', 'the other list survives');

# every folder is a chatListFolder: keying on the type alone let a position in
# one folder delete the chat's position in another
sub folder_pos {
    my ($id, $order) = @_;
    return qq({"\@type":"updateChatPosition","chat_id":-100123,"position":)
         . qq({"\@type":"chatPosition","list":{"\@type":"chatListFolder",)
         . qq("chat_folder_id":$id},"order":$order}});
}
$td->inject_raw(folder_pos(1, 50));
$td->inject_raw(folder_pos(2, 60));
my %pos = map { ($_->{list}{chat_folder_id} // $_->{list}{'@type'}) => $_->{order} }
          @{ $td->chat(-100123)->{positions} };
is_deeply(\%pos, { chatListMain => 200, 1 => 50, 2 => 60 },
    'two folders hold a position each alongside the main list');
$td->inject_raw(folder_pos(2, 0));
%pos = map { ($_->{list}{chat_folder_id} // $_->{list}{'@type'}) => $_->{order} }
       @{ $td->chat(-100123)->{positions} };
is_deeply(\%pos, { chatListMain => 200, 1 => 50 },
    'and leaving one folder keeps the other');

# updateChatLastMessage and updateChatDraftMessage carry the complete set, so
# a list the chat has left appears only as absent from it
$td->inject_raw(q({"@type":"updateChatDraftMessage","chat_id":-100123,"positions":[]}));
is(scalar @{ $td->chat(-100123)->{positions} }, 0,
    'a full position set that is empty removes every position');

# chat_lists is membership, kept by its own two updates; updateNewChat usually
# carries it empty, so without them it stayed empty for most chats
sub list_upd {
    my ($type, $list) = @_;
    return qq({"\@type":"$type","chat_id":-100123,"chat_list":$list});
}
my $main = q({"@type":"chatListMain"});
$td->inject_raw(list_upd('updateChatAddedToList', $main));
$td->inject_raw(list_upd('updateChatAddedToList', q({"@type":"chatListFolder","chat_folder_id":3})));
$td->inject_raw(list_upd('updateChatAddedToList', q({"@type":"chatListFolder","chat_folder_id":4})));
$td->inject_raw(list_upd('updateChatAddedToList', $main));
my $lists = sub { [ sort map { $_->{chat_folder_id} // $_->{'@type'} }
                         @{ $td->chat(-100123)->{chat_lists} } ] };
is_deeply($lists->(), [3, 4, 'chatListMain'],
    'each list the chat joins is recorded once, folders apart');
$td->inject_raw(list_upd('updateChatRemovedFromList', q({"@type":"chatListFolder","chat_folder_id":3})));
is_deeply($lists->(), [4, 'chatListMain'], 'and leaving one folder removes only that one');

$td->inject_raw(q({"@type":"updateChatReadInbox","chat_id":-100123,"last_read_inbox_message_id":1048576,"unread_count":3}));
is($td->chat(-100123)->{unread_count}, 3, 'updateChatReadInbox patches unread_count');

$td->inject_raw(q({"@type":"updateChatBlockList","chat_id":-100123,"block_list":{"@type":"blockListMain"}}));
is($td->chat(-100123)->{block_list}{'@type'}, 'blockListMain', 'updateChatBlockList patches block_list');

$td->inject_raw(q({"@type":"updateChatMessageAutoDeleteTime","chat_id":-100123,"message_auto_delete_time":86400}));
is($td->chat(-100123)->{message_auto_delete_time}, 86400, 'updateChatMessageAutoDeleteTime patches message_auto_delete_time');

$td->inject_raw(q({"@type":"updateChatTheme","chat_id":-100123,"theme":{"@type":"chatTheme","name":"day"}}));
is($td->chat(-100123)->{theme}{name}, 'day', 'updateChatTheme patches theme');

# TDLib omits null object fields from JSON entirely, so for a nullable
# payload field an absent key means "now null", not "unchanged"
$td->inject_raw(q({"@type":"updateChatLastMessage","chat_id":-100123,"positions":[]}));
is($td->chat(-100123)->{last_message}, undef, 'an absent last_message clears the cache');

$td->inject_raw(q({"@type":"updateChatDraftMessage","chat_id":-100123,"draft_message":{"@type":"draftMessage"},"positions":[]}));
ok($td->chat(-100123)->{draft_message}, 'a draft is cached');
$td->inject_raw(q({"@type":"updateChatDraftMessage","chat_id":-100123,"positions":[]}));
is($td->chat(-100123)->{draft_message}, undef, 'an absent draft_message clears the cache');

$td->inject_raw(q({"@type":"updateChatBlockList","chat_id":-100123}));
is($td->chat(-100123)->{block_list}, undef, 'an absent block_list means unblocked');

$td->inject_raw(q({"@type":"updateChatPhoto","chat_id":-100123,"photo":{"@type":"chatPhotoInfo"}}));
ok($td->chat(-100123)->{photo}, 'a photo is cached');
$td->inject_raw(q({"@type":"updateChatPhoto","chat_id":-100123}));
is($td->chat(-100123)->{photo}, undef, 'an absent photo clears the cache');

$td->inject_raw(q({"@type":"updateChatActionBar","chat_id":-100123,"action_bar":{"@type":"chatActionBarReportSpam"}}));
ok($td->chat(-100123)->{action_bar}, 'an action bar is cached');
$td->inject_raw(q({"@type":"updateChatActionBar","chat_id":-100123}));
is($td->chat(-100123)->{action_bar}, undef, 'an absent action_bar clears the cache');

$td->inject_raw(q({"@type":"updateChatTheme","chat_id":-100123}));
is($td->chat(-100123)->{theme}, undef, 'an absent theme resets the theme');

$td->inject_raw(q({"@type":"updateChatPendingJoinRequests","chat_id":-100123,"pending_join_requests":{"@type":"chatJoinRequestsInfo","total_count":2}}));
is($td->chat(-100123)->{pending_join_requests}{total_count}, 2, 'pending join requests cached');
$td->inject_raw(q({"@type":"updateChatPendingJoinRequests","chat_id":-100123}));
is($td->chat(-100123)->{pending_join_requests}, undef, 'an absent pending_join_requests clears the cache');

# a non-nullable payload field stays "unchanged" when absent
$td->inject_raw(q({"@type":"updateChatNotificationSettings","chat_id":-100123,"notification_settings":{"@type":"chatNotificationSettings","mute_for":30}}));
is($td->chat(-100123)->{notification_settings}{mute_for}, 30, 'notification settings cached');
$td->inject_raw(q({"@type":"updateChatNotificationSettings","chat_id":-100123}));
is($td->chat(-100123)->{notification_settings}{mute_for}, 30, 'an absent non-nullable field leaves the cache unchanged');

my $me;
$td->me(sub { $me = [@_] });
like($sent[-1], qr/"getMe"/, 'me sends getMe');
my ($extra_me) = $sent[-1] =~ /"\@extra":"(\d+)"/;
$td->inject_raw(qq({"\@type":"user","id":7,"first_name":"Bot","\@extra":"$extra_me"}));
is($me->[0]{first_name}, 'Bot', 'me delivers the user');
is($me->[1], undef, 'me reports no error');
is($td->user(7)->{first_name}, 'Bot', 'me caches the user');

my $found;
$td->chat_by_username('@room', sub { $found = [@_] });
like($sent[-1], qr/searchPublicChat/, 'chat_by_username sends searchPublicChat');
like($sent[-1], qr/"username":"room"/, 'a leading @ is stripped');
my ($extra_found) = $sent[-1] =~ /"\@extra":"(\d+)"/;
$td->inject_raw(qq({"\@type":"chat","id":-100555,"title":"Public","\@extra":"$extra_found"}));
is($found->[0]{title}, 'Public', 'chat_by_username delivers the chat');
is($found->[1], undef, 'chat_by_username reports no error');
is($td->chat(-100555)->{title}, 'Public', 'chat_by_username caches the chat');

my $miss;
$td->chat_by_username('nosuchuser', sub { $miss = [@_] });
my ($extra_miss) = $sent[-1] =~ /"\@extra":"(\d+)"/;
$td->inject_raw(qq({"\@type":"error","code":400,"message":"USERNAME_NOT_OCCUPIED","\@extra":"$extra_miss"}));
is($miss->[0], undef, 'a failed search delivers no chat');
is($miss->[1]{code}, 400, 'a failed search delivers the error');

my $loaded;
$td->load_chats(20, sub { $loaded = [@_] });
like($sent[-1], qr/loadChats/, 'load_chats sends loadChats');
like($sent[-1], qr/"limit":20/, 'the limit goes out as a number');
my ($extra_load) = $sent[-1] =~ /"\@extra":"(\d+)"/;
$td->inject_raw(qq({"\@type":"ok","\@extra":"$extra_load"}));
ok($loaded, 'load_chats callback fired');
is($loaded->[1], undef, 'load_chats reports no error');

my $exhausted;
$td->load_chats(20, sub { $exhausted = [@_] });
my ($extra_end) = $sent[-1] =~ /"\@extra":"(\d+)"/;
$td->inject_raw(qq({"\@type":"error","code":404,"message":"Not Found","\@extra":"$extra_end"}));
ok($exhausted, 'load_chats callback fired on 404');
is($exhausted->[0], undef, 'an exhausted list has no result');
is($exhausted->[1], undef, 'TDLib end-of-list 404 is not surfaced as an error');

my $real_err;
$td->load_chats(20, sub { $real_err = [@_] });
my ($extra_err) = $sent[-1] =~ /"\@extra":"(\d+)"/;
$td->inject_raw(qq({"\@type":"error","code":400,"message":"Invalid limit","\@extra":"$extra_err"}));
is($real_err->[1]{code}, 400, 'other load_chats errors pass through');

$td->close;
$td->inject_raw(q({"@type":"updateAuthorizationState","authorization_state":{"@type":"authorizationStateClosed"}}));
is($td->auth_state, 'authorizationStateClosed', 'client closed');

# --- reading a chat field must not mutate the cache. Reading through a
# missing last_message used to autovivify it to {}, so every later
# `if ($chat->{last_message})` took the wrong branch.
{
    my $c = EV::Telegram::TDLib->new(
        api_id => 1, api_hash => 'x', database_directory => 't/tmp-cache');
    $c->inject_raw(
        q({"@type":"updateNewChat","chat":{"@type":"chat","id":-4242,"title":"Empty"}}));
    ok !exists $c->chat(-4242)->{last_message}, 'a chat with no last message';
    $c->mark_read(-4242, sub {});
    ok !$c->chat(-4242)->{last_message},
        'mark_read leaves it absent rather than autovivifying an empty hash';
}

done_testing;
