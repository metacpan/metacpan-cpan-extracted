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

my $td = EV::Telegram::TDLib->new(
    api_id => 1, api_hash => 'x', database_directory => 't/tmp-reactions');

# --- the shipped emoji path must not regress
$td->react(-100, 5, "\x{1F44D}", sub {});
my $r = last_req();
is $r->{'@type'}, 'addMessageReaction', 'react still adds';
is $r->{reaction_type}{'@type'}, 'reactionTypeEmoji', 'a string is still an emoji reaction';
like last_json(), qr/"update_recent_reactions":true/,
    'update_recent still defaults to true';

$td->react(-100, 5, "\x{1F44D}", remove => 1, sub {});
is last_req()->{'@type'}, 'removeMessageReaction', 'remove => 1 still removes';

$td->react(-100, 5, "\x{1F44D}", update_recent => 0, sub {});
like last_json(), qr/"update_recent_reactions":false/,
    'the shipped update_recent option name still works';

# --- new: custom emoji reactions
$td->react(-100, 5, { custom_emoji_id => '5312536423851630001' }, sub {});
is last_req()->{reaction_type}{'@type'}, 'reactionTypeCustomEmoji',
    'a hashref is a custom emoji reaction';
like last_json(), qr/"custom_emoji_id":"5312536423851630001"/,
    'custom_emoji_id crosses as a JSON string';

# --- setMessageReactions takes a list through the same coercion
$td->set_reactions(-100, 5, ["\x{1F44D}", { custom_emoji_id => 9 }], sub {});
$r = last_req();
is $r->{'@type'}, 'setMessageReactions', 'set_reactions sends setMessageReactions';
is scalar @{ $r->{reaction_types} }, 2, 'both reactions are passed';
is $r->{reaction_types}[1]{'@type'}, 'reactionTypeCustomEmoji',
    'the list is coerced element by element';
like last_json(), qr/"custom_emoji_id":"9"/, 'and int64 still crosses as a string';

# --- MessageSender coercion
$td->delete_reactions_from_sender(-100, 5, 42, sub {});
$r = last_req();
is $r->{'@type'}, 'deleteMessageReactionsFromSender', 'delete_reactions_from_sender';
is $r->{sender_id}{'@type'}, 'messageSenderUser', 'a positive id is a user sender';

$td->clear_recent_reactions(sub {});
is last_req()->{'@type'}, 'clearRecentReactions', 'clear_recent_reactions';

# --- chat level
$td->read_all_reactions(-100, sub {});
is last_req()->{'@type'}, 'readAllChatReactions', 'read_all_reactions';

$td->set_reaction_notifications(
    message_reaction_source => 'contacts',
    story_reaction_source   => 'all',
    poll_vote_source        => 'none',
    sound_id                => '1234567890123456789',
    show_preview            => 1,
    sub {});
$r = last_req();
is $r->{'@type'}, 'setReactionNotificationSettings', 'set_reaction_notifications';
is $r->{notification_settings}{message_reaction_source}{'@type'},
    'reactionNotificationSourceContacts', 'source strings coerce to their union arm';
like last_json(), qr/"sound_id":"1234567890123456789"/,
    'sound_id crosses as a JSON string';

# --- forum level
$td->read_all_topic_reactions(-100, 55, sub {});
$r = last_req();
is $r->{'@type'}, 'readAllForumTopicReactions', 'read_all_topic_reactions';
is $r->{forum_topic_id}, 55, 'topic id passed through';

# --- paid reactions go through the pending/commit pair, never addMessageReaction
$td->add_paid_reaction(-100, 5, 10, sub {});
$r = last_req();
is $r->{'@type'}, 'addPendingPaidMessageReaction',
    'a paid reaction uses the pending call, not addMessageReaction';
is $r->{star_count}, 10, 'star_count is int53 and stays numeric';
like last_json(), qr/"star_count":10\b/, 'and is not stringified';
is $r->{type}{'@type'}, 'paidReactionTypeRegular', 'the default paid type is regular';

$td->add_paid_reaction(-100, 5, 3, type => 'anonymous', sub {});
is last_req()->{type}{'@type'}, 'paidReactionTypeAnonymous', 'anonymous paid type';

$td->add_paid_reaction(-100, 5, 3, type => -1001234, sub {});
$r = last_req();
is $r->{type}{'@type'}, 'paidReactionTypeChat', 'a chat id gives the chat paid type';
is $r->{type}{chat_id}, -1001234, 'and carries the chat id';

$td->commit_paid_reactions(-100, 5, sub {});
is last_req()->{'@type'}, 'commitPendingPaidMessageReactions', 'commit_paid_reactions';

$td->remove_paid_reactions(-100, 5, sub {});
is last_req()->{'@type'}, 'removePendingPaidMessageReactions', 'remove_paid_reactions';

$td->set_paid_reaction_type(-100, 5, 'anonymous', sub {});
$r = last_req();
is $r->{'@type'}, 'setPaidMessageReactionType', 'set_paid_reaction_type';
is $r->{type}{'@type'}, 'paidReactionTypeAnonymous', 'and coerces its type';

$td->paid_reaction_senders(-100, sub {});
is last_req()->{'@type'}, 'getChatAvailablePaidMessageReactionSenders',
    'paid_reaction_senders';

# --- the caller's callback must not be swallowed by an optional positional
my $called = 0;
$td->react(-100, 5, "\x{1F44D}", sub { $called++ });
my $extra = last_req()->{'@extra'};
$td->inject_raw(qq({"\@type":"ok","\@extra":"$extra"}));
is $called, 1, "react's callback is invoked, not bound to a trailing positional";

# --- the reaction readers take the same forms as react(), so a custom emoji
# works there too rather than only a plain one
{
    $td->set_default_reaction({ custom_emoji_id => '5312536423851630001' }, sub {});
    my $r = last_req();
    is $r->{'@type'}, 'setDefaultReactionType', 'set_default_reaction';
    is $r->{reaction_type}{'@type'}, 'reactionTypeCustomEmoji',
        'and accepts a custom emoji';
    like last_json(), qr/"custom_emoji_id":"5312536423851630001"/,
        'with the id as a string';

    $td->message_reactions(-100, 5, reaction => { custom_emoji_id => 9 }, sub {});
    is last_req()->{reaction_type}{'@type'}, 'reactionTypeCustomEmoji',
        'message_reactions filters by a custom emoji too';
}

done_testing;
