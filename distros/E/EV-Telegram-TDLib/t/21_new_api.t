use strict;
use warnings;
use Test::More;

# This file stubs _send, so the END-block shutdown cannot deliver its close
# requests and would idle out the whole budget at exit. Nothing was ever sent
# to TDLib here, so there is nothing to wait for.
BEGIN { $ENV{EV_TDLIB_SHUTDOWN_TIMEOUT} = 0.1 }

use EV;
use EV::Telegram::TDLib;
use MIME::Base64 qw(decode_base64);

my @sent;
{
    no warnings 'redefine';
    *EV::Telegram::TDLib::_send = sub { push @sent, $_[1] };
}

my $td = EV::Telegram::TDLib->new(
    api_id => 1, api_hash => 'x', database_directory => 't/tmp-new-api',
);

sub last_json { $sent[-1] }

# --- retry_after parses the delay Telegram hides in the message text
is(EV::Telegram::TDLib->retry_after({ code => 429,
        message => 'Too Many Requests: retry after 108' }), 108,
    'retry_after extracts the delay');
is(EV::Telegram::TDLib->retry_after({ code => 400, message => 'retry after 5' }),
    undef, 'retry_after ignores non-429 errors');
is(EV::Telegram::TDLib->retry_after({ code => 429, message => 'slow down' }),
    undef, 'retry_after returns undef when no delay is stated');

# --- inline keyboards: TL bytes travel base64 over the JSON interface
my $kb = EV::Telegram::TDLib->inline_keyboard([
    [ { text => 'Yes', data => 'vote:yes' }, { text => 'Docs', url => 'https://example' } ],
]);
is $kb->{'@type'}, 'replyMarkupInlineKeyboard', 'keyboard is an inline markup';
my $btn = $kb->{rows}[0][0];
is $btn->{type}{'@type'}, 'inlineKeyboardButtonTypeCallback', 'callback button type';
is decode_base64($btn->{type}{data}), 'vote:yes', 'callback data is base64 encoded';
is $kb->{rows}[0][1]{type}{'@type'}, 'inlineKeyboardButtonTypeUrl', 'url button type';

# --- send_file nests the InputFile in the per-kind wrapper
my %media = (
    document   => ['inputMessageDocument',  'inputDocument',  1],
    photo      => ['inputMessagePhoto',     'inputPhoto',     1],
    video      => ['inputMessageVideo',     'inputVideo',     1],
    audio      => ['inputMessageAudio',     'inputAudio',     1],
    animation  => ['inputMessageAnimation', 'inputAnimation', 1],
    voice_note => ['inputMessageVoiceNote', 'inputVoiceNote', 1],
    video_note => ['inputMessageVideoNote', 'inputVideoNote', 0],
    sticker    => ['inputMessageSticker',   'inputSticker',   0],
);
for my $kind (sort keys %media) {
    my ($content, $wrapper, $caption) = @{ $media{$kind} };
    $td->send_file(42, '/tmp/x.bin', kind => $kind, caption => 'cap', sub {});
    my $j = last_json();
    like $j, qr/"\@type":"\Q$content\E"/, "$kind: content type";
    like $j, qr/"\@type":"\Q$wrapper\E"/, "$kind: nests the $wrapper wrapper";
    like $j, qr/"\@type":"inputFileLocal"/, "$kind: carries the InputFile";
    # these two have no caption field in the schema
    if ($caption) { like $j, qr/"caption"/, "$kind: takes a caption" }
    else          { unlike $j, qr/"caption"/, "$kind: sends no caption field" }
}

$td->send_file(42, '/tmp/x.webp', kind => 'sticker', emoji => "\x{1F600}", sub {});
like last_json(), qr/"emoji"/, 'sticker carries its emoji';

# --- reply_markup rides along on both send paths
$td->send_message(42, 'hi', reply_markup => $kb, sub {});
like last_json(), qr/replyMarkupInlineKeyboard/, 'send_message carries reply_markup';
$td->send_file(42, '/tmp/x.bin', reply_markup => $kb, sub {});
like last_json(), qr/replyMarkupInlineKeyboard/, 'send_file carries reply_markup';

# --- an unknown kind is a programming error, not a silent default
eval { $td->send_file(42, '/tmp/x.bin', kind => 'nope', sub {}) };
like $@, qr/unknown file kind/, 'send_file rejects an unknown kind';

# a hashref was waved through as an already-built inputFile whatever it was,
# so a formattedText became the file and TDLib blamed the InputFile
eval { $td->send_file(42, { '@type' => 'formattedText', text => 'x' }, sub {}) };
like $@, qr/must be a path or an inputFile/, 'send_file rejects a foreign hashref';
eval { $td->send_file(42, { path => '/tmp/x' }, sub {}) };
like $@, qr/without an \@type/, 'and one with no @type at all';
{
    @sent = ();
    $td->send_file(42, { '@type' => 'inputFileId', id => 7 }, sub {});
    like last_json(), qr/"inputFileId"/, 'but a real inputFile passes through';
}
# the photo setters had their own copy of the shortcut, so the same check
# never reached them
eval { $td->set_profile_photo({ '@type' => 'formattedText', text => 'x' }, sub {}) };
like $@, qr/must be a path or an inputFile/, 'set_profile_photo rejects a foreign hashref';
eval { $td->set_chat_photo(42, undef, sub {}) };
like $@, qr/required/, 'and a photo setter still requires a path';
eval { $td->chat_action(42, 'nope', sub {}) };
like $@, qr/unknown chat action/, 'chat_action rejects an unknown action';

# --- read state is one viewMessages, with no openChat around it
{
    @sent = ();
    my @got;
    $td->mark_read(42, message_ids => [7], sub { @got = @_ });
    is scalar @sent, 1, 'mark_read sends one request';
    like $sent[0], qr/"\@type":"viewMessages"/, 'and it is viewMessages';
    like $sent[0], qr/"force_read":true/, 'with force_read, which is what makes it stick';
    like $sent[0], qr/"messageSourceChatHistory"/, 'and an explicit source';
    # openChat writes the chat into the account's persistent recently-opened
    # list, which closeChat does not undo: a sweep evicted every real one
    unlike $sent[0], qr/openChat/, 'no chat is opened';
    my ($x) = $sent[0] =~ /"\@extra":"(\d+)"/;
    $td->inject_raw(qq({"\@type":"ok","\@extra":"$x"}));
    is scalar @sent, 1, 'and nothing follows the reply';
    is $got[0]{'@type'}, 'ok', 'the caller gets the reply';
    ok !$got[1], 'and no error';
}

# --- callback queries decode the base64 payload for the caller
my $got;
$td->on_callback_query(sub { $got = shift });
$td->inject_raw(q({"@type":"updateNewCallbackQuery","id":"99","sender_user_id":5,)
    . q("chat_id":42,"message_id":7,)
    . q("payload":{"@type":"callbackQueryPayloadData","data":"dm90ZTp5ZXM="}}));
is $got->{data}, 'vote:yes', 'callback payload is decoded from base64';
is $got->{id}, '99', 'callback id is preserved as a string';

$td->answer_callback_query('99', text => 'thanks', sub {});
like last_json(), qr/"callback_query_id":"99"/, 'answer sends the id as a string';

# --- editing keeps or replaces the buttons explicitly
$td->edit_message(42, 7, 'new text', reply_markup => $kb, sub {});
like last_json(), qr/"\@type":"editMessageText"/, 'edit_message sends editMessageText';
like last_json(), qr/replyMarkupInlineKeyboard/, 'edit_message can set reply_markup';

$td->edit_message_markup(42, 7, $kb, sub {});
like last_json(), qr/"\@type":"editMessageReplyMarkup"/,
    'edit_message_markup edits only the markup';

# --- reactions
$td->react(42, 7, "\x{1F44D}", sub {});
like last_json(), qr/"\@type":"addMessageReaction"/, 'react adds a reaction';
like last_json(), qr/"\@type":"reactionTypeEmoji"/, 'react sends an emoji reaction';
$td->react(42, 7, "\x{1F44D}", remove => 1, sub {});
like last_json(), qr/"\@type":"removeMessageReaction"/, 'react can remove';

# --- reply keyboards accept plain strings and request buttons
my $rk = EV::Telegram::TDLib->reply_keyboard(
    [ ['Yes', 'No'], [ { text => 'Number', request => 'phone' } ] ],
    one_time => 1, placeholder => 'pick');
is $rk->{'@type'}, 'replyMarkupShowKeyboard', 'reply_keyboard builds a show markup';
is $rk->{rows}[0][0]{text}, 'Yes', 'a bare string becomes a text button';
is $rk->{rows}[1][0]{type}{'@type'}, 'keyboardButtonTypeRequestPhoneNumber',
    'a request button gets its type';
is $rk->{input_field_placeholder}, 'pick', 'placeholder is carried';
is(EV::Telegram::TDLib->remove_keyboard->{'@type'}, 'replyMarkupRemoveKeyboard',
    'remove_keyboard builds a remove markup');
eval { EV::Telegram::TDLib->reply_keyboard([[ { text => 'x', request => 'nope' } ]]) };
like $@, qr/unknown button request/, 'reply_keyboard rejects an unknown request';

# --- bot command menu
$td->set_commands([ ['/start', 'Begin'], { command => 'help', description => 'Help' } ], sub {});
my $j = last_json();
like $j, qr/"\@type":"setCommands"/, 'set_commands sends setCommands';
like $j, qr/"command":"start"/, 'a leading slash is stripped from a command';
like $j, qr/"botCommandScopeDefault"/, 'a default scope is supplied';
eval { $td->set_commands([ ['only-a-name'] ], sub {}) };
like $@, qr/needs a name and a description/, 'set_commands requires a description';

# --- chat membership
$td->join_chat(42, sub {});
like last_json(), qr/"\@type":"joinChat"/, 'join_chat sends joinChat';
$td->leave_chat(42, sub {});
like last_json(), qr/"\@type":"leaveChat"/, 'leave_chat sends leaveChat';

# --- account profile actions
$td->set_name('Ada', 'Lovelace', sub {});
# JSON object key order is not stable, so never span two keys in one regex
like last_json(), qr/"\@type":"setName"/, 'set_name sends setName';
like last_json(), qr/"first_name":"Ada"/, 'set_name sends the first name';
like last_json(), qr/"last_name":"Lovelace"/, 'set_name sends the last name';
eval { $td->set_name('', sub {}) };
like $@, qr/needs a first name/, 'set_name rejects an empty first name';
$td->set_bio('hacker', sub {});
like last_json(), qr/"\@type":"setBio"/, 'set_bio sends setBio';
$td->set_username('@ada', sub {});
like last_json(), qr/"username":"ada"/, 'set_username strips a leading at-sign';

$td->set_profile_photo('/tmp/p.png', sub {});
$j = last_json();
like $j, qr/"\@type":"setProfilePhoto"/, 'set_profile_photo sends setProfilePhoto';
like $j, qr/"\@type":"inputChatPhotoStatic"/, 'a still photo is a static chat photo';
# is_public sets the fallback photo shown to users the privacy settings deny
# the main one, so defaulting it on left the photo everyone sees unchanged
like $j, qr/"is_public":false/, 'by default it is the main photo, not the public fallback';
$td->set_profile_photo('/tmp/p.png', public => 1, sub {});
like last_json(), qr/"is_public":true/, 'public => 1 sets the fallback';
$td->set_profile_photo('/tmp/p.mp4', animation => 1, main_frame_timestamp => 2, sub {});
like last_json(), qr/"\@type":"inputChatPhotoAnimation"/, 'an animated photo uses the animation type';

# --- bot profile actions address the bot by user id
$td->{cache}{options}{my_id} = 4242;
is $td->my_id, 4242, 'my_id comes from the option cache';
$td->set_bot_name('Helper', sub {});
like last_json(), qr/"bot_user_id":4242/, 'a bot action defaults to my_id';
$td->set_bot_name('Helper', bot_user_id => 77, sub {});
like last_json(), qr/"bot_user_id":77/, 'an explicit bot_user_id wins';
$td->set_bot_description('long text', sub {});
like last_json(), qr/"\@type":"setBotInfoDescription"/, 'set_bot_description sends the long text';
$td->set_bot_short_description('short', sub {});
like last_json(), qr/"\@type":"setBotInfoShortDescription"/, 'set_bot_short_description sends the short text';
$td->set_bot_photo('/tmp/p.png', sub {});
like last_json(), qr/"\@type":"setBotProfilePhoto"/, 'set_bot_photo sends setBotProfilePhoto';

delete $td->{cache}{options}{my_id};
eval { $td->set_bot_name('x', sub {}) };
like $@, qr/bot_user_id is not known/, 'a bot action without an id croaks';

# --- the option cache decodes each option value type
$td->inject_raw(q({"@type":"updateOption","name":"t_str","value":{"@type":"optionValueString","value":"s"}}));
$td->inject_raw(q({"@type":"updateOption","name":"t_int","value":{"@type":"optionValueInteger","value":7}}));
$td->inject_raw(q({"@type":"updateOption","name":"t_bool","value":{"@type":"optionValueBoolean","value":true}}));
$td->inject_raw(q({"@type":"updateOption","name":"t_none","value":{"@type":"optionValueEmpty"}}));
is $td->option('t_str'), 's', 'string option cached';
is $td->option('t_int'), 7, 'integer option cached';
is $td->option('t_bool'), 1, 'boolean option cached as 1';
is $td->option('t_none'), undef, 'an empty option is undef';

# --- pinning and chat administration
$td->pin_message(42, 7, silent => 1, sub {});
like last_json(), qr/"\@type":"pinChatMessage"/, 'pin_message sends pinChatMessage';
$td->unpin_message(42, 7, sub {});
like last_json(), qr/"\@type":"unpinChatMessage"/, 'unpin_message sends unpinChatMessage';
$td->set_chat_title(42, 'New title', sub {});
like last_json(), qr/"title":"New title"/, 'set_chat_title sends the title';
eval { $td->set_chat_title(42, '', sub {}) };
like $@, qr/needs a title/, 'set_chat_title rejects an empty title';
$td->set_chat_photo(42, '/tmp/p.png', sub {});
like last_json(), qr/"\@type":"inputChatPhotoStatic"/, 'set_chat_photo wraps the photo';
$td->add_chat_member(42, 9, sub {});
like last_json(), qr/"\@type":"addChatMember"/, 'add_chat_member sends addChatMember';

for my $st (qw(member left banned)) {
    $td->set_member_status(42, 9, $st, sub {});
    like last_json(), qr/"chatMemberStatus\u$st"/, "set_member_status: $st";
}
like last_json(), qr/"\@type":"messageSenderUser"/, 'a member is addressed as a message sender';
eval { $td->set_member_status(42, 9, 'nope', sub {}) };
like $@, qr/unknown member status/, 'set_member_status rejects an unknown status';

$td->block_user(9, sub {});
like last_json(), qr/"blockListMain"/, 'block_user blocks on the main list';
$td->block_user(9, unblock => 1, sub {});
like last_json(), qr/"block_list":null/, 'unblocking sends a null block list';

# --- polls, location, contact
$td->send_poll(42, 'Coming?', ['Yes', 'No'], sub {});
my $p = last_json();
like $p, qr/"\@type":"inputMessagePoll"/, 'send_poll sends a poll';
like $p, qr/"\@type":"inputPollOption"/, 'poll options are inputPollOption';
like $p, qr/"inputPollTypeRegular"/, 'a plain poll is a regular poll';
like $p, qr/"is_anonymous":true/, 'polls are anonymous by default';
# TDLib reads a missing allows_revoting as false: every vote was final
like $p, qr/"allows_revoting":true/, 'a vote can be changed by default';
$td->send_poll(42, 'Q', ['a','b'], revoting => 0, sub {});
like last_json(), qr/"allows_revoting":false/, 'unless revoting is turned off';
$td->send_poll(42, 'Q', ['a','b'], quiz => 1, correct => 1, sub {});
like last_json(), qr/"inputPollTypeQuiz"/, 'quiz mode selects the quiz type';
like last_json(), qr/"allows_revoting":false/, 'and a quiz answer is final';
eval { $td->send_poll(42, 'Q', ['only one'], sub {}) };
like $@, qr/at least two options/, 'send_poll needs two options';
eval { $td->send_poll(42, 'Q', 'not-an-array', sub {}) };
like $@, qr/arrayref of options/, 'send_poll needs an arrayref';

$td->send_location(42, 51.5, -0.12, sub {});
like last_json(), qr/"\@type":"inputMessageLocation"/, 'send_location sends a location';
$td->send_contact(42, '+10000000000', 'Ada', sub {});
like last_json(), qr/"\@type":"inputMessageContact"/, 'send_contact sends a contact';

# --- inline queries
my $iq;
$td->on_inline_query(sub { $iq = shift });
$td->inject_raw(q({"@type":"updateNewInlineQuery","id":"1234567890123456789",)
    . q("sender_user_id":5,"query":"cats","offset":"",)
    . q("chat_type":{"@type":"chatTypePrivate"}}));
is $iq->{query}, 'cats', 'inline query text reaches the handler';
is $iq->{id}, '1234567890123456789', 'an int64 inline query id survives as a string';

$td->answer_inline_query('1234567890123456789',
    [ { title => 'First', message => 'picked first' }, { title => 'Second' } ], sub {});
my $q = last_json();
like $q, qr/"\@type":"answerInlineQuery"/, 'answer_inline_query sends answerInlineQuery';
like $q, qr/"inline_query_id":"1234567890123456789"/, 'the id is sent as a string';
like $q, qr/"inputInlineQueryResultArticle"/, 'results are article results';
like $q, qr/"picked first"/, 'an explicit message is used as the sent text';
like $q, qr/"id":"1"/, 'a result with no id gets a generated one';
eval { $td->answer_inline_query(1, 'nope', sub {}) };
like $@, qr/arrayref of results/, 'answer_inline_query needs an arrayref';
eval { $td->answer_inline_query(1, [ {} ], sub {}) };
like $@, qr/needs a title/, 'each inline result needs a title';

# --- a missing required argument fails at the call site, not inside TDLib
my @required = (
    [ 'send_file path'        => sub { $td->send_file(1, undef, sub {}) },        qr/path is required/ ],
    [ 'react emoji'           => sub { $td->react(1, 2, undef, sub {}) },         qr/emoji is required/ ],
    [ 'send_poll question'    => sub { $td->send_poll(1, undef, ['a','b'], sub {}) }, qr/question is required/ ],
    [ 'send_location lat'     => sub { $td->send_location(1, undef, 2, sub {}) }, qr/latitude is required/ ],
    [ 'send_contact phone'    => sub { $td->send_contact(1, undef, 'A', sub {}) },qr/phone is required/ ],
    [ 'block_user user_id'    => sub { $td->block_user(undef, sub {}) },          qr/user_id is required/ ],
    [ 'pin_message message_id'=> sub { $td->pin_message(1, undef, sub {}) },      qr/message_id is required/ ],
    [ 'add_chat_member user'  => sub { $td->add_chat_member(1, undef, sub {}) },  qr/user_id is required/ ],
);
for my $r (@required) {
    my ($label, $code, $want) = @$r;
    eval { $code->() };
    like $@, $want, "$label: croaks when missing";
}

# these are meaningful empty values, not mistakes
my @allowed = (
    [ 'an empty command list clears the menu' => sub { $td->set_commands([], sub {}) } ],
    [ 'an empty keyboard is allowed'          => sub { $td->inline_keyboard([]) } ],
    [ 'undef markup removes buttons'          => sub { $td->edit_message_markup(1, 2, undef, sub {}) } ],
);
for my $a (@allowed) {
    my ($label, $code) = @$a;
    eval { $code->(); 1 } ? pass $label : fail "$label: $@";
}

# a parse failure must reach the caller instead of being embedded in the
# request, as it already does for send_message and friends
{
    my $perr;
    $td->send_poll(42, '*unclosed', ['a','b'], parse_mode => 'markdown',
        sub { $perr = $_[1] });
    ok $perr, 'send_poll reports a parse failure to the callback';
    unlike last_json(), qr/"\@type":"error"/,
        'send_poll does not send an error object to TDLib';

    my $ierr;
    $td->answer_inline_query(1, [ { title => '*unclosed' } ],
        parse_mode => 'markdown', sub { $ierr = $_[1] });
    ok $ierr, 'answer_inline_query reports a parse failure to the callback';
}

# an unencodable request croaks, and must not leave a pending entry behind
# that later fires a bogus timeout for a request that was never sent
{
    my $td2 = EV::Telegram::TDLib->new(
        api_id => 1, api_hash => 'x', database_directory => 't/tmp-encode',
    );
    my $lived = eval { $td2->send({ '@type' => 'x', bad => sub {} }, sub {}); 1 };
    ok !$lived, 'an unencodable request croaks at the call site';
    is scalar keys %{ $td2->{pending} }, 0, 'no pending entry is orphaned';
}

done_testing;
