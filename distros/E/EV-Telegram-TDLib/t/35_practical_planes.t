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
    api_id => 1, api_hash => 'x', database_directory => 't/tmp-practical');

# --- messages
$td->send_album(-100, [ { '@type' => 'inputMessagePhoto' } ], topic => 7, sub {});
my $r = last_req();
is $r->{'@type'}, 'sendMessageAlbum', 'send_album sends sendMessageAlbum';
is scalar @{ $r->{input_message_contents} }, 1, 'with its contents';
is $r->{topic_id}{forum_topic_id}, 7, 'and honours the topic option';

$td->edit_message_caption(-100, 55, 'new cap', sub {});
$r = last_req();
is $r->{'@type'}, 'editMessageCaption', 'edit_message_caption works';
is $r->{caption}{text}, 'new cap', 'the caption is a formattedText';

$td->edit_message_media(-100, 55, { '@type' => 'inputMessagePhoto' }, sub {});
is last_req()->{'@type'}, 'editMessageMedia', 'edit_message_media works';

$td->reschedule(-100, 55, 1800000000, sub {});
$r = last_req();
is $r->{'@type'}, 'editMessageSchedulingState', 'reschedule works';
is $r->{scheduling_state}{send_date}, 1800000000, 'with the new date';
$td->reschedule(-100, 55, sub {});
ok !exists last_req()->{scheduling_state}, 'and no date sends it now';

# the timing fields belong inside the liveLocation wrapper, as for the inline form
$td->edit_message_location(-100, 55, { '@type' => 'location' }, live_period => 60, sub {});
$r = last_req();
is $r->{location}{'@type'}, 'liveLocation', 'the location is wrapped';
is $r->{location}{live_period}, 60, 'with live_period inside the wrapper';
ok !exists $r->{live_period}, 'and not at the top level';
$td->edit_message_location(-100, 55, sub {});
ok !defined last_req()->{location},
    'edit_message_location without location sends null location to stop sharing';

$td->resend_messages(-100, [1, 2], sub {});
is_deeply last_req()->{message_ids}, [1, 2], 'resend_messages works';

for my $t ([ message_thread => 'getMessageThread' ], [ read_date => 'getMessageReadDate' ],
           [ message_viewers => 'getMessageViewers' ],
           [ message_properties => 'getMessageProperties' ],
           [ open_content => 'openMessageContent' ]) {
    my ($m, $type) = @$t;
    $td->$m(-100, 55, sub {});
    is last_req()->{'@type'}, $type, "$m sends $type";
}

$td->thread_history(-100, 55, limit => 5, sub {});
is last_req()->{limit}, 5, 'thread_history passes its limit';
$td->message_by_date(-100, 1700000000, sub {});
is last_req()->{'@type'}, 'getChatMessageByDate', 'message_by_date works';
$td->unpin_all(-100, sub {});
is last_req()->{'@type'}, 'unpinAllChatMessages', 'unpin_all works';
$td->read_all_mentions(-100, sub {});
is last_req()->{'@type'}, 'readAllChatMentions', 'read_all_mentions works';

$td->delete_messages_by_sender(-100, 42, sub {});
$r = last_req();
is $r->{'@type'}, 'deleteChatMessagesBySender', 'delete_messages_by_sender works';
is $r->{sender_id}{'@type'}, 'messageSenderUser', 'the sender is typed';

$td->delete_messages_by_date(-100, 1700000000, 1700003600, sub {});
like last_json(), qr/"revoke":true/, 'deleting by date revokes by default';

$err = do { local $@; eval { $td->send_album(-100, [], sub {}) }; $@ };
like $err, qr/at least one/, 'an empty album is refused';

# an album's reply carries one message per item, so there is no single
# send-succeeded to wait for. Only the modes it cannot honour are refused:
# 'accepted' describes what it already does, and croaking on that broke
# callers who were stating the behaviour rather than asking to change it.
for my $w (qw(sent typo)) {
    my $e = do { local $@; eval {
        $td->send_album(-100, [ { '@type' => 'inputMessagePhoto' } ],
                        wait => $w, sub {}) }; $@ };
    like $e, qr/cannot wait/, "send_album refuses wait => '$w'";
}
ok eval { $td->send_album(-100, [ { '@type' => 'inputMessagePhoto' } ],
                          wait => 'accepted', sub {}); 1 },
    "send_album accepts wait => 'accepted', which is what it does anyway"
    or diag $@;

# --- text utilities
$td->parse_markdown('*bold*', sub {});
$r = last_req();
is $r->{'@type'}, 'parseMarkdown', 'parse_markdown works';
is $r->{text}{'@type'}, 'formattedText', 'wrapping the text as a formattedText';

$td->text_entities('see https://example.com', sub {});
is last_req()->{'@type'}, 'getTextEntities', 'text_entities works';

$td->translate('hello', 'de', sub {});
$r = last_req();
is $r->{'@type'}, 'translateText', 'translate works';
is $r->{to_language_code}, 'de', 'with the target language';
is $r->{text}{'@type'}, 'formattedText', 'and a formattedText, not a bare string';

$td->link_preview('https://example.com', sub {});
is last_req()->{'@type'}, 'getLinkPreview', 'link_preview works';
$td->search_hashtags('perl', sub {});
is last_req()->{'@type'}, 'searchHashtags', 'search_hashtags works';

$err = do { local $@; eval { $td->markdown_text('x', sub {}) }; $@ };
like $err, qr/formattedText hashref/, 'markdown_text refuses a bare string';

# --- files
$td->file(7, sub {});
is last_req()->{'@type'}, 'getFile', 'file works';
$td->remote_file('abc', file_type => 'Photo', sub {});
$r = last_req();
is $r->{'@type'}, 'getRemoteFile', 'remote_file works';
is $r->{file_type}{'@type'}, 'fileTypePhoto', 'a short file type is expanded';
$td->add_to_downloads(7, -100, 55, sub {});
is last_req()->{'@type'}, 'addFileToDownloads', 'add_to_downloads works';
$td->pause_download(7, sub {});
like last_json(), qr/"is_paused":true/, 'pause_download defaults to pausing';
$td->storage_statistics(sub {});
is last_req()->{'@type'}, 'getStorageStatisticsFast', 'storage_statistics works';
$td->optimize_storage(size => 100, sub {});
$r = last_req();
is $r->{'@type'}, 'optimizeStorage', 'optimize_storage works';
is $r->{ttl}, -1, 'unset limits are -1, which TDLib reads as no limit';

# --- search and chats
$td->search_chats('bob', sub {});
is last_req()->{'@type'}, 'searchChats', 'search_chats works';
$td->search_public_chats('news', sub {});
is last_req()->{'@type'}, 'searchPublicChats', 'search_public_chats works';
$td->top_chats('bots', sub {});
$r = last_req();
is $r->{'@type'}, 'getTopChats', 'top_chats works';
is $r->{category}{'@type'}, 'topChatCategoryBots', 'the category is typed';
$td->recommended_chats(sub {});
is last_req()->{'@type'}, 'getRecommendedChats', 'recommended_chats works';
$td->check_chat_username(-100, 'name', sub {});
is last_req()->{'@type'}, 'checkChatUsername', 'check_chat_username works';
$td->report_chat(-100, text => 'spam', sub {});
is last_req()->{'@type'}, 'reportChat', 'report_chat works';

$err = do { local $@; eval { $td->top_chats('wizards', sub {}) }; $@ };
like $err, qr/unknown top chat category/, 'an unknown category is refused';

# --- users and privacy
$td->search_by_phone('+15550001', sub {});
is last_req()->{'@type'}, 'searchUserByPhoneNumber', 'search_by_phone works';
$td->my_link(sub {});
is last_req()->{'@type'}, 'getUserLink', 'my_link works';
$td->toggle_username('alt', sub {});
like last_json(), qr/"is_active":true/, 'toggle_username defaults to activating';

$td->privacy('status', sub {});
$r = last_req();
is $r->{'@type'}, 'getUserPrivacySettingRules', 'privacy works';
is $r->{setting}{'@type'}, 'userPrivacySettingShowStatus', 'the setting is typed';

$td->set_privacy('status', [ { '@type' => 'userPrivacySettingRuleAllowAll' } ], sub {});
$r = last_req();
is $r->{'@type'}, 'setUserPrivacySettingRules', 'set_privacy works';
is $r->{rules}{'@type'}, 'userPrivacySettingRules', 'rules are wrapped';

$err = do { local $@; eval { $td->privacy('mind', sub {}) }; $@ };
like $err, qr/unknown privacy setting/, 'an unknown privacy setting is refused';

# --- bots menu button
$td->set_menu_button(42, text => 'Shop', url => 'https://example.com', sub {});
$r = last_req();
is $r->{'@type'}, 'setMenuButton', 'set_menu_button works';
is $r->{menu_button}{'@type'}, 'botMenuButton', 'the button is typed';
is $r->{menu_button}{text}, 'Shop', 'with its text';
# an empty text is refused unless the url is "default", and only a null
# button brings the commands list back
$td->set_menu_button(42, commands => 1, sub {});
like last_json(), qr/"menu_button":null/, 'commands => 1 puts the commands list back';
$td->set_menu_button(42, sub {});
is last_req()->{menu_button}{url}, 'default', 'and a bare call the default button';
# an empty text with any other url is refused by TDLib, so a url alone must
# not fall through to the default button and wipe the one that is set
my $mb_err = do { local $@; eval { $td->set_menu_button(42, url => 'https://x/', sub {}) }; $@ };
like $mb_err, qr/needs a text/, 'a url with no text croaks rather than resetting the button';
$td->menu_button(42, sub {});
is last_req()->{'@type'}, 'getMenuButton', 'menu_button works';

# --- connection, proxies, account
$td->add_proxy({ server => '1.2.3.4', port => 1080, type => 'socks5' }, sub {});
$r = last_req();
is $r->{'@type'}, 'addProxy', 'add_proxy works';
is $r->{proxy}{'@type'}, 'proxy', 'the proxy is typed';
is $r->{proxy}{type}{'@type'}, 'proxyTypeSocks5', 'and so is its type';
is $r->{proxy}{port}, 1080, 'with the port';

$td->add_proxy({ server => 'h', port => 8080, type => 'mtproto', secret => 'ss' }, sub {});
is last_req()->{proxy}{type}{secret}, 'ss', 'an mtproto proxy carries its secret';

$td->proxies(sub {});
is last_req()->{'@type'}, 'getProxies', 'proxies works';
$td->enable_proxy(1, sub {});
is last_req()->{'@type'}, 'enableProxy', 'enable_proxy works';
$td->disable_proxy(sub {});
is last_req()->{'@type'}, 'disableProxy', 'disable_proxy works';
$td->remove_proxy(1, sub {});
is last_req()->{'@type'}, 'removeProxy', 'remove_proxy works';

$td->set_network_type('wifi', sub {});
is last_req()->{type}{'@type'}, 'networkTypeWiFi', 'set_network_type works';
$td->network_statistics(sub {});
is last_req()->{'@type'}, 'getNetworkStatistics', 'network_statistics works';

$td->log_out(sub {});
is last_req()->{'@type'}, 'logOut', 'log_out works';
$td->password_state(sub {});
is last_req()->{'@type'}, 'getPasswordState', 'password_state works';
$td->set_password('old', 'new', hint => 'h', sub {});
$r = last_req();
is $r->{'@type'}, 'setPassword', 'set_password works';
like last_json(), qr/"set_recovery_email_address":false/,
    'no recovery email means the flag is off';

# reading and writing share one method, told apart by the argument
$td->account_ttl(sub {});
is last_req()->{'@type'}, 'getAccountTtl', 'account_ttl with no days reads';
$td->account_ttl(365, sub {});
$r = last_req();
is $r->{'@type'}, 'setAccountTtl', 'and with days it writes';
is $r->{ttl}{days}, 365, 'wrapping the days in an accountTtl';

$td->register_device({ '@type' => 'deviceTokenApplePush' }, sub {});
is last_req()->{'@type'}, 'registerDevice', 'register_device works';

$err = do { local $@; eval { $td->set_network_type('moon', sub {}) }; $@ };
like $err, qr/unknown network type/, 'an unknown network type is refused';

# --- regression: a method whose last positional is optional must not swallow
# the callback. Before the fix, close_topic($chat,$topic,$cb) bound $cb to the
# is_closed flag, left @rest empty, and silently registered a no-op instead --
# the caller's callback never fired and nothing said so.
{
    my @fired;
    for my $case (
        [ 'close_topic'   => sub { $_[0]->close_topic(-100, 55, $_[1]) } ],
        [ 'pin_chat'      => sub { $_[0]->pin_chat(-100, $_[1]) } ],
        [ 'mark_unread'   => sub { $_[0]->mark_unread(-100, $_[1]) } ],
        [ 'folder_tags'   => sub { $_[0]->folder_tags($_[1]) } ],
        [ 'reschedule'    => sub { $_[0]->reschedule(-100, 55, $_[1]) } ],
        [ 'account_ttl'   => sub { $_[0]->account_ttl($_[1]) } ],
        [ 'mute'          => sub { $_[0]->mute(-100, $_[1]) } ],
        [ 'protect_content' => sub { $_[0]->protect_content(-100, $_[1]) } ],
    ) {
        my ($name, $call) = @$case;
        my $ran = 0;
        %{ $td->{pending} } = ();
        $call->($td, sub { $ran++ });
        my ($pending) = values %{ $td->{pending} };
        $pending->{cb}->(undef, undef) if $pending;
        push @fired, $name unless $ran;
    }
    is "@fired", '', 'no method with an optional trailing argument drops its callback'
        or diag "dropped by: @fired";
}

# and the optional argument still defaults correctly when omitted
$td->reschedule(-100, 55, sub {});
ok !exists last_req()->{scheduling_state},
    'reschedule with only a callback still means "send now"';
$td->account_ttl(sub {});
is last_req()->{'@type'}, 'getAccountTtl',
    'account_ttl with only a callback still reads rather than writes';

done_testing;
