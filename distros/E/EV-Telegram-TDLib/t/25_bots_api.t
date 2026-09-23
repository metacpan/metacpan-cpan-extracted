use strict;
use warnings;
use Test::More;

BEGIN { $ENV{EV_TDLIB_SHUTDOWN_TIMEOUT} = 0.1 }

use EV;
use EV::Telegram::TDLib;
use Cpanel::JSON::XS;
use MIME::Base64 qw(decode_base64);

# _send receives the encoded JSON string, not the request hashref
my @sent;
{
    no warnings 'redefine';
    *EV::Telegram::TDLib::_send = sub { push @sent, $_[1] };
}
sub last_json { $sent[-1] }
sub last_req  { Cpanel::JSON::XS->new->decode($sent[-1]) }

my $err;
my $td = EV::Telegram::TDLib->new(
    api_id => 1, api_hash => 'x', database_directory => 't/tmp-bots-api');
# my_id comes from the option cache; there is no {my_id} slot
$td->{cache}{options}{my_id} = 777;

# --- command and profile getters
$td->commands(sub {});
my $r = last_req();
is $r->{'@type'}, 'getCommands', 'commands sends getCommands';
is $r->{scope}{'@type'}, 'botCommandScopeDefault', 'defaults to the default scope';

$td->delete_commands(sub {});
is last_req()->{'@type'}, 'deleteCommands', 'delete_commands sends deleteCommands';

$td->bot_name(sub {});
$r = last_req();
is $r->{'@type'}, 'getBotName', 'bot_name sends getBotName';
is $r->{bot_user_id}, 777, 'defaults to our own id';

$td->bot_description(sub {});
is last_req()->{'@type'}, 'getBotInfoDescription', 'bot_description sends its method';

$td->bot_short_description(sub {});
is last_req()->{'@type'}, 'getBotInfoShortDescription',
    'bot_short_description sends its method';

$td->bot_name(bot_user_id => 42, sub {});
is last_req()->{bot_user_id}, 42, 'an explicit bot id overrides our own';

# --- inline message editing
$td->edit_inline_text('abc123', 'new text', sub {});
$r = last_req();
is $r->{'@type'}, 'editInlineMessageText', 'edit_inline_text sends its method';
is $r->{inline_message_id}, 'abc123', 'inline id passed through';
is $r->{input_message_content}{'@type'}, 'inputMessageText', 'text wrapped as content';
is $r->{input_message_content}{text}{text}, 'new text', 'text reaches the formatted text';

$td->edit_inline_caption('abc123', 'cap', sub {});
$r = last_req();
is $r->{'@type'}, 'editInlineMessageCaption', 'edit_inline_caption sends its method';
is $r->{caption}{text}, 'cap', 'caption is a formatted text';

$td->edit_inline_markup('abc123', { '@type' => 'replyMarkupInlineKeyboard' }, sub {});
$r = last_req();
is $r->{'@type'}, 'editInlineMessageReplyMarkup', 'edit_inline_markup sends its method';
is $r->{reply_markup}{'@type'}, 'replyMarkupInlineKeyboard', 'markup passed through';

$td->edit_inline_media('abc123', { '@type' => 'inputMessagePhoto' }, sub {});
is last_req()->{'@type'}, 'editInlineMessageMedia', 'edit_inline_media sends its method';

# the timing fields live inside the liveLocation wrapper
$td->edit_inline_location('abc123', { '@type' => 'location' }, live_period => 60, sub {});
$r = last_req();
is $r->{'@type'}, 'editInlineMessageLiveLocation', 'edit_inline_location sends its method';
is $r->{location}{'@type'}, 'liveLocation', 'the location is wrapped as a liveLocation';
is $r->{location}{live_period}, 60, 'live period sits inside the wrapper';
ok !exists $r->{live_period}, 'and not at the top level, where TDLib would drop it';
$td->edit_inline_location('abc123', sub {});
ok !defined last_req()->{location},
    'edit_inline_location without location sends null location to stop sharing';

# a parse failure reaches the caller instead of TDLib
my $before = scalar @sent;
my ($pres, $perr);
$td->edit_inline_text('abc123', '*unclosed', parse_mode => 'markdown',
    sub { ($pres, $perr) = @_ });
is scalar @sent, $before, 'a text that fails to parse is never sent';
is +($perr->{'@type'} // ''), 'error', 'the parse error reaches the callback';

$err = do { local $@; eval { $td->edit_inline_text(undef, 'x', sub {}) }; $@ };
like $err, qr/required/, 'a missing inline id is refused';

# --- press, inline queries, bot start, attachment menu
$td->press(-100, 55, 'vote:yes', sub {});
$r = last_req();
is $r->{'@type'}, 'getCallbackQueryAnswer', 'press sends getCallbackQueryAnswer';
is $r->{chat_id}, -100, 'chat id passed through';
is $r->{message_id}, 55, 'message id passed through';
is $r->{payload}{'@type'}, 'callbackQueryPayloadData', 'payload is a data payload';
is decode_base64($r->{payload}{data}), 'vote:yes', 'payload data is base64 encoded';

$td->inline_query(42, 'weather', sub {});
$r = last_req();
is $r->{'@type'}, 'getInlineQueryResults', 'inline_query sends getInlineQueryResults';
is $r->{bot_user_id}, 42, 'bot id passed through';
is $r->{query}, 'weather', 'query passed through';

$td->send_inline_result(-100, '918273', 'res1', sub {});
$r = last_req();
is $r->{'@type'}, 'sendInlineQueryResultMessage', 'send_inline_result sends its method';
is $r->{result_id}, 'res1', 'result id passed through';
like last_json(), qr/"query_id":"918273"/, 'query id crosses as a JSON string';

$td->start_bot(42, 'ref9', sub {});
$r = last_req();
is $r->{'@type'}, 'sendBotStartMessage', 'start_bot sends sendBotStartMessage';
is $r->{parameter}, 'ref9', 'start parameter passed through';
is $r->{chat_id}, 42, 'the bot chat is the default target';

$td->attachment_menu_bot(42, sub {});
is last_req()->{'@type'}, 'getAttachmentMenuBot', 'attachment_menu_bot sends its method';

$td->toggle_attachment_menu(42, 1, sub {});
is last_req()->{'@type'}, 'toggleBotIsAddedToAttachmentMenu', 'toggle sends its method';
like last_json(), qr/"is_added":true/, 'is_added crosses as a JSON boolean';

$err = do { local $@; eval { $td->press(undef, 55, 'x', sub {}) }; $@ };
like $err, qr/required/, 'a missing chat id is refused';

# --- every other list argument checks its element shape; this one did not,
# so a plain string died inside the builder naming a line in the module
{
    my $err = '';
    eval { $td->answer_inline_query('1', ['not a hashref'], sub {}); 1 }
        or $err = $@;
    like $err, qr/must be a hashref/, 'a non-hashref inline result croaks';
    unlike $err, qr/Can't use string/,
        'rather than dying inside the builder';
}

done_testing;
