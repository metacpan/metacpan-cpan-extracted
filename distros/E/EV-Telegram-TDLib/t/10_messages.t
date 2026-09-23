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

sub extra_of {
    my ($json) = @_;
    my ($extra) = $json =~ /"\@extra":"(\d+)"/;
    return $extra;
}

my (@messages_seen, @updates);
my $td = EV::Telegram::TDLib->new(
    api_id   => 1,
    api_hash => 'x',
    auto_auth => 0,
    database_directory => 't/tmp-messages',
    on_message => sub { push @messages_seen, $_[0] },
);
$td->on_update(sub { push @updates, $_[0] });

# --- two-phase send: wait => 'sent' resolves on updateMessageSendSucceeded
my @done;
$td->send_message(-100123, 'hi', wait => 'sent', sub { push @done, [@_] });
like($sent[-1], qr/"sendMessage"/, 'send_message sends sendMessage');
like($sent[-1], qr/"chat_id":-100123/, 'the chat id goes out as a number');
like($sent[-1], qr/"inputMessageText"/, 'the content is inputMessageText');
like($sent[-1], qr/"text":"hi"/, 'plain text is wrapped verbatim');
my $extra = extra_of($sent[-1]);
$td->inject_raw(qq({"\@type":"message","id":1048576,"chat_id":-100123,"\@extra":"$extra"}));
is(scalar @done, 0, 'no callback yet on the temporary message');

$td->inject_raw(q({"@type":"updateMessageSendSucceeded","message":{"@type":"message","id":2097152,"chat_id":-100123},"old_message_id":1048576}));
is(scalar @done, 1, 'callback fires when the send is confirmed');
is($done[0][0]{id}, 2097152, 'the final message id is delivered');
is($done[0][1], undef, 'no error on a confirmed send');

$td->inject_raw(q({"@type":"updateMessageSendSucceeded","message":{"@type":"message","id":2097152,"chat_id":-100123},"old_message_id":1048576}));
is(scalar @done, 1, 'a repeated confirmation does not fire the callback twice');

# --- wait => 'accepted' fires on the temporary message
my @accepted;
$td->send_message(-100123, 'early', wait => 'accepted', sub { push @accepted, [@_] });
my $extra_acc = extra_of($sent[-1]);
$td->inject_raw(qq({"\@type":"message","id":3145728,"chat_id":-100123,"\@extra":"$extra_acc"}));
is(scalar @accepted, 1, 'accepted fires on the temporary message');
is($accepted[0][0]{id}, 3145728, 'the temporary message id is delivered');
$td->inject_raw(q({"@type":"updateMessageSendSucceeded","message":{"@type":"message","id":4194304,"chat_id":-100123},"old_message_id":3145728}));
is(scalar @accepted, 1, 'the later confirmation does not fire again');

# --- default wait is 'sent'
my @failed;
$td->send_message(-100123, 'doomed', sub { push @failed, [@_] });
my $extra_fail = extra_of($sent[-1]);
$td->inject_raw(qq({"\@type":"message","id":5242880,"chat_id":-100123,"\@extra":"$extra_fail"}));
is(scalar @failed, 0, 'default wait is sent, not accepted');
$td->inject_raw(q({"@type":"updateMessageSendFailed","message":{"@type":"message","id":5242880,"chat_id":-100123},"old_message_id":5242880,"error":{"@type":"error","code":400,"message":"MESSAGE_EMPTY"}}));
is(scalar @failed, 1, 'updateMessageSendFailed resolves the callback');
is($failed[0][0], undef, 'a failed send delivers no message');
is($failed[0][1]{code}, 400, 'the send error is delivered');

# --- an immediate sendMessage rejection resolves the callback too
my @rejected;
$td->send_message(-100123, 'nope', sub { push @rejected, [@_] });
my $extra_rej = extra_of($sent[-1]);
$td->inject_raw(qq({"\@type":"error","code":403,"message":"CHAT_WRITE_FORBIDDEN","\@extra":"$extra_rej"}));
is($rejected[0][0], undef, 'an immediate rejection delivers no message');
is($rejected[0][1]{code}, 403, 'an immediate rejection delivers the error');

# --- an unknown old_message_id is ignored. Asserted against a send left
# waiting: a lookup that fell back to any pending entry would resolve it,
# and an unconditional pass could not tell.
my @waiting;
$td->send_message(-100123, 'still waiting', sub { push @waiting, [@_] });
my $extra_wait = extra_of($sent[-1]);
$td->inject_raw(qq({"\@type":"message","id":6291456,"chat_id":-100123,"\@extra":"$extra_wait"}));
my $pending_before = scalar keys %{ $td->{cache}{sending} || {} };
$td->inject_raw(q({"@type":"updateMessageSendSucceeded","message":{"@type":"message","id":1,"chat_id":-100123},"old_message_id":999999}));
is(scalar @waiting, 0, 'an unknown old_message_id resolves no waiting send');
is(scalar keys %{ $td->{cache}{sending} || {} }, $pending_before,
   'and leaves the pending table untouched');

# --- options
$td->send_message(-100123, 'opts', reply_to => 1048576, silent => 1,
                  disable_preview => 1, sub {});
like($sent[-1], qr/"inputMessageReplyToMessage"/, 'reply_to builds inputMessageReplyToMessage');
like($sent[-1], qr/"message_id":1048576/, 'the replied-to message id goes out');
like($sent[-1], qr/"disable_notification":true/, 'silent maps to disable_notification');
like($sent[-1], qr/"is_disabled":true/, 'disable_preview disables the link preview');
my $extra_opts = extra_of($sent[-1]);
$td->inject_raw(qq({"\@type":"message","id":6291456,"chat_id":-100123,"\@extra":"$extra_opts"}));

ok(!eval { $td->send_message(-100123, 'x', wait => 'whenever', sub {}); 1 },
   'an unknown wait mode dies');
like($@, qr/wait/, 'the error names the option');

# --- parse_mode: synchronous parseTextEntities, no round trip
my $before = scalar @sent;
my @parsed;
$td->send_message(-100123, '*bold*', parse_mode => 'markdown', sub { push @parsed, [@_] });
is(scalar @sent, $before + 1, 'parseTextEntities adds no network round trip');
like($sent[-1], qr/"sendMessage"/, 'the parsed text goes out as sendMessage');
unlike($sent[-1], qr/parseTextEntities/, 'the parse itself is never sent');
like($sent[-1], qr/"text":"bold"/, 'the parsed text is used verbatim');
like($sent[-1], qr/"textEntityTypeBold"/, 'the entity came from parseTextEntities');
my $extra_md = extra_of($sent[-1]);
$td->inject_raw(qq({"\@type":"message","id":7340032,"chat_id":-100123,"\@extra":"$extra_md"}));

# --- a parse error is delivered to the callback, never sent
my $before_err = scalar @sent;
my @parse_err;
$td->send_message(-100123, '*bold', parse_mode => 'markdown', sub { push @parse_err, [@_] });
is(scalar @sent, $before_err, 'a parse error is not sent to the server');
is(scalar @parse_err, 1, 'a parse error fires the callback');
is($parse_err[0][0], undef, 'a parse error delivers no message');
is($parse_err[0][1]{'@type'}, 'error', 'a parse error delivers the error object');

ok(!eval { $td->send_message(-100123, 'x', parse_mode => 'bbcode', sub {}); 1 },
   'an unknown parse_mode dies');
like($@, qr/parse_mode/, 'the error names the option');

# --- on_message over updateNewMessage
$td->inject_raw(q({"@type":"updateNewMessage","message":{"@type":"message","id":8388608,"chat_id":-100123}}));
is(scalar @messages_seen, 1, 'on_message fired');
is($messages_seen[0]{id}, 8388608, 'on_message got the message');
is($updates[-1]{'@type'}, 'updateNewMessage', 'updateNewMessage still reaches on_update');

# --- history pages with from_message_id
my $hist;
$td->history(-100123, limit => 3, sub { $hist = [@_] });
like($sent[-1], qr/"getChatHistory"/, 'history sends getChatHistory');
like($sent[-1], qr/"from_message_id":0/, 'paging starts from the latest message');
like($sent[-1], qr/"limit":3/, 'the requested limit goes out');
my $eh1 = extra_of($sent[-1]);
$td->inject_raw(qq({"\@type":"messages","total_count":10,"messages":[{"\@type":"message","id":31457280},{"\@type":"message","id":20971520}],"\@extra":"$eh1"}));
is($hist, undef, 'no callback after a partial page');
like($sent[-1], qr/"from_message_id":20971520/, 'paging follows the oldest id of the batch');
like($sent[-1], qr/"limit":1/, 'only the remaining count is requested');
my $eh2 = extra_of($sent[-1]);
$td->inject_raw(qq({"\@type":"messages","total_count":10,"messages":[{"\@type":"message","id":10485760}],"\@extra":"$eh2"}));
is(scalar @{ $hist->[0] }, 3, 'history delivers once the limit is reached');
is($hist->[0][0]{id}, 31457280, 'newest message first');
is($hist->[1], undef, 'no error on a full walk');
is($hist->[2]{complete}, 1, 'reaching the limit counts as complete');
is($hist->[2]{last_message_id}, 10485760, 'reports the id it stopped at');

# --- an empty batch ends the walk
my $hist_empty;
$td->history(-100123, limit => 10, sub { $hist_empty = [@_] });
my $eh3 = extra_of($sent[-1]);
$td->inject_raw(qq({"\@type":"messages","total_count":1,"messages":[{"\@type":"message","id":20971520}],"\@extra":"$eh3"}));
my $eh4 = extra_of($sent[-1]);
$td->inject_raw(qq({"\@type":"messages","total_count":1,"messages":[],"\@extra":"$eh4"}));
is(scalar @{ $hist_empty->[0] }, 1, 'an empty batch ends the walk with what we have');
is($hist_empty->[2]{complete}, 1, 'an empty batch counts as complete');

# --- the page cap stops a chat that never exhausts
my $hist_cap;
$td->history(-100123, limit => 100, max_pages => 2, sub { $hist_cap = [@_] });
my $eh5 = extra_of($sent[-1]);
$td->inject_raw(qq({"\@type":"messages","total_count":50,"messages":[{"\@type":"message","id":20971520}],"\@extra":"$eh5"}));
is($hist_cap, undef, 'no callback before the cap is reached');
my $eh6 = extra_of($sent[-1]);
my $sent_at_cap = scalar @sent;
$td->inject_raw(qq({"\@type":"messages","total_count":50,"messages":[{"\@type":"message","id":10485760}],"\@extra":"$eh6"}));
is(scalar @{ $hist_cap->[0] }, 2, 'the page cap stops the walk');
is($hist_cap->[2]{complete}, 0, 'a capped walk is reported as incomplete');
is($hist_cap->[2]{last_message_id}, 10485760, 'reports where the capped walk stopped');
is(scalar @sent, $sent_at_cap, 'the cap stops further round trips');

# --- a history error is delivered
my $hist_err;
$td->history(-100123, sub { $hist_err = [@_] });
my $eh7 = extra_of($sent[-1]);
$td->inject_raw(qq({"\@type":"error","code":400,"message":"CHAT_ID_INVALID","\@extra":"$eh7"}));
is($hist_err->[0], undef, 'a history error delivers no messages');
is($hist_err->[1]{code}, 400, 'a history error delivers the error');

# --- edit_message
my @edited;
$td->edit_message(-100123, 2097152, 'edited', sub { push @edited, [@_] });
like($sent[-1], qr/"editMessageText"/, 'edit_message sends editMessageText');
like($sent[-1], qr/"message_id":2097152/, 'the edited message id goes out');
my $ee = extra_of($sent[-1]);
$td->inject_raw(qq({"\@type":"message","id":2097152,"chat_id":-100123,"\@extra":"$ee"}));
is($edited[0][0]{id}, 2097152, 'edit delivers the updated message');
is($edited[0][1], undef, 'edit reports no error');

my $before_edit_err = scalar @sent;
my @edit_err;
$td->edit_message(-100123, 2097152, '*broken', parse_mode => 'markdown',
                  sub { push @edit_err, [@_] });
is(scalar @sent, $before_edit_err, 'an edit parse error is not sent');
is($edit_err[0][1]{'@type'}, 'error', 'an edit parse error is delivered');

# --- delete_messages
my @deleted;
$td->delete_messages(-100123, [2097152, 3145728], sub { push @deleted, [@_] });
like($sent[-1], qr/"deleteMessages"/, 'delete_messages sends deleteMessages');
like($sent[-1], qr/"message_ids":\[2097152,3145728\]/, 'message ids go out as numbers');
like($sent[-1], qr/"revoke":true/, 'delete revokes by default');
my $ed = extra_of($sent[-1]);
$td->inject_raw(qq({"\@type":"ok","\@extra":"$ed"}));
ok($deleted[0], 'delete callback fired');
is($deleted[0][1], undef, 'delete reports no error');

# --- forward_messages
my @fwd;
$td->forward_messages(-100123, -100555, [1048576], sub { push @fwd, [@_] });
like($sent[-1], qr/"forwardMessages"/, 'forward_messages sends forwardMessages');
like($sent[-1], qr/"from_chat_id":-100555/, 'the source chat goes out');
my $ef = extra_of($sent[-1]);
$td->inject_raw(qq({"\@type":"messages","total_count":1,"messages":[{"\@type":"message","id":9437184}],"\@extra":"$ef"}));
is($fwd[0][0]{messages}[0]{id}, 9437184, 'forward delivers the new messages');

$td->close;
$td->inject_raw(q({"@type":"updateAuthorizationState","authorization_state":{"@type":"authorizationStateClosed"}}));
is($td->auth_state, 'authorizationStateClosed', 'client closed');

# TDLib counts entity offsets in UTF-16 code units, so perl's substr is wrong
# for any text containing a character outside the BMP: one perl character,
# two UTF-16 units. The helper slices correctly and leaves the wire offsets
# alone, because they travel back unchanged on forward, edit and copy.
{
    my $ft = EV::Telegram::TDLib->execute({
        '@type' => 'parseTextEntities',
        text => "\x{1F600} hi *bold* end",          # emoji is 2 UTF-16 units
        parse_mode => { '@type' => 'textParseModeMarkdown', version => 2 },
    });
    my ($e) = @{ $ft->{entities} || [] };
    ok $e, 'TDLib parsed an entity out of the markdown';

  SKIP: {
        skip 'no entity to slice', 5 unless $e;
        is(EV::Telegram::TDLib->entity_text($ft, $e), 'bold',
            'entity_text slices in UTF-16 code units');
        isnt substr($ft->{text}, $e->{offset}, $e->{length}), 'bold',
            'plain substr really does get it wrong (the reason this exists)';

        my $all = EV::Telegram::TDLib->entity_texts($ft);
        is scalar @$all, 1, 'entity_texts returns one entry per entity';
        is $all->[0]{text}, 'bold', 'entity_texts carries the sliced text';
        is $all->[0]{offset}, $e->{offset},
            'the wire offset is passed through unchanged';
    }

    # pure ASCII: both readings agree, which is why an ASCII example hides this
    my $ascii = EV::Telegram::TDLib->execute({
        '@type' => 'parseTextEntities',
        text => 'plain *bold* text',
        parse_mode => { '@type' => 'textParseModeMarkdown', version => 2 },
    });
    my ($ae) = @{ $ascii->{entities} || [] };
    if ($ae) {
        is(EV::Telegram::TDLib->entity_text($ascii, $ae), 'bold',
            'entity_text agrees with substr when the text is ASCII');
    }

    eval { EV::Telegram::TDLib->entity_text('not a ref', {}) };
    like $@, qr/needs a formattedText/, 'entity_text rejects a non-hashref';
}

# reaching through a missing entity type must not autovivify it in the
# caller's own data
{
    my $ft = { text => 'hi', entities => [ { offset => 0, length => 2 } ] };
    my $out = EV::Telegram::TDLib->entity_texts($ft);
    ok !exists $ft->{entities}[0]{type},
        'entity_texts leaves the caller\'s entity untouched';
    is $out->[0]{text}, 'hi', 'and still slices the text';
    is $out->[0]{type}, undef, 'with an undefined type rather than a fabricated one';
}

# --- a yet-unsent message id comes from a per-chat counter, so the Nth send
# to one chat and the Nth to another carry the same one. Keying the pending
# callback on the id alone dropped one and gave the other the wrong message.
{
    my @out;
    my $enc = Cpanel::JSON::XS->new->utf8;
    no warnings 'redefine';
    local *EV::Telegram::TDLib::_send = sub { push @out, $_[1] };
    my $c = EV::Telegram::TDLib->new(
        api_id => 1, api_hash => 'x', database_directory => 't/tmp-xchat');

    my @fired;
    $c->send_message(111, 'to A', sub { push @fired, 'A:' . ($_[0] ? $_[0]{chat_id} : 'err') });
    my $xa = $enc->decode($out[-1])->{'@extra'};
    $c->send_message(222, 'to B', sub { push @fired, 'B:' . ($_[0] ? $_[0]{chat_id} : 'err') });
    my $xb = $enc->decode($out[-1])->{'@extra'};

    $c->inject_raw(qq({"\@type":"message","id":1,"chat_id":111,"\@extra":"$xa"}));
    $c->inject_raw(qq({"\@type":"message","id":1,"chat_id":222,"\@extra":"$xb"}));
    is scalar(keys %{ $c->{cache}{sending} || {} }), 2,
        'two concurrent sends to different chats are tracked separately';

    $c->inject_raw(q({"@type":"updateMessageSendSucceeded","old_message_id":1,)
                  . q("message":{"@type":"message","id":900,"chat_id":111}}));
    $c->inject_raw(q({"@type":"updateMessageSendSucceeded","old_message_id":1,)
                  . q("message":{"@type":"message","id":901,"chat_id":222}}));
    is_deeply [sort @fired], ['A:111', 'B:222'],
        'and each callback receives its own chat\'s message';
}

done_testing;
