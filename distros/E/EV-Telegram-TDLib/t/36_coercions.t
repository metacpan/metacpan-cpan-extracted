use strict;
use warnings;
use Test::More;
use Cpanel::JSON::XS;

# _send is stubbed below, so no close can complete at exit
BEGIN { $ENV{EV_TDLIB_SHUTDOWN_TIMEOUT} = 0.1 }

use EV::Telegram::TDLib;

my $c = 'EV::Telegram::TDLib';

# --- MessageSender: a bare id is ambiguous until its sign is read
is_deeply $c->message_sender(42),
    { '@type' => 'messageSenderUser', user_id => 42 },
    'a positive id is a user';
is_deeply $c->message_sender(-1001234567890),
    { '@type' => 'messageSenderChat', chat_id => -1001234567890 },
    'a negative id is a chat';
is_deeply $c->message_sender({ '@type' => 'messageSenderUser', user_id => 7 }),
    { '@type' => 'messageSenderUser', user_id => 7 },
    'an explicit sender object passes through untouched';

eval { $c->message_sender(undef) };
like $@, qr/sender/, 'an undefined sender croaks';

# a non-numeric id used to numify to 0 and reach the wire as the JSON float
# 0.0, in a slot the schema declares int53, after warning from inside the module
for my $bad ('abc', '', '12x') {
    eval { $c->message_sender($bad) };
    like $@, qr/sender/, "a non-numeric sender ('$bad') croaks at the call site";
}

is_deeply $c->message_sender('-1001234567890'),
    { '@type' => 'messageSenderChat', chat_id => -1001234567890 },
    'a numeric string is still accepted, and keeps its sign';
is_deeply $c->message_sender(" -100123\n"),
    { '@type' => 'messageSenderChat', chat_id => -100123 },
    'space around a sender id is tolerated, as around every other id';

# --- ReactionType
is_deeply $c->reaction_type("\x{1F44D}"),
    { '@type' => 'reactionTypeEmoji', emoji => "\x{1F44D}" },
    'a plain string is an emoji reaction';

my $custom = $c->reaction_type({ custom_emoji_id => '5312536423851630001' });
is $custom->{'@type'}, 'reactionTypeCustomEmoji', 'a hashref is a custom emoji reaction';
ok !ref $custom->{custom_emoji_id}, 'custom_emoji_id is a plain scalar';
is $custom->{custom_emoji_id}, '5312536423851630001',
    'and keeps full int64 precision as a string';

is_deeply $c->reaction_type({ '@type' => 'reactionTypePaid' }),
    { '@type' => 'reactionTypePaid' },
    'an explicit reaction object passes through untouched';

eval { $c->reaction_type([]) };
like $@, qr/reaction/, 'anything else croaks naming the problem';

eval { $c->reaction_type(undef) };
like $@, qr/reaction/, 'an undefined reaction croaks';

# --- text arguments. A formattedText -- what translate and parse_markdown
# answer with -- goes out as it is wherever the text can carry formatting, an
# object that stringifies is text, and any other reference croaks rather than
# reaching the chat as HASH(0x...)
{
    package StringyURL;
    use overload '""' => sub { 'https://example.org/x' }, fallback => 1;
}
{
    my @sent;
    no warnings 'redefine';
    *EV::Telegram::TDLib::_send = sub { push @sent, $_[1] };
    my $J = Cpanel::JSON::XS->new->utf8;
    my $td = EV::Telegram::TDLib->new(
        api_id => 1, api_hash => 'x', database_directory => 't/tmp-coercions');
    my $ft = { '@type' => 'formattedText', text => 'Hi there',
               entities => [ { '@type' => 'textEntity', offset => 0, length => 2,
                               type => { '@type' => 'textEntityTypeBold' } } ] };
    my $last = sub { $J->decode($sent[-1]) };
    my @sites = (
        [ 'send_message text', sub { $td->send_message(-100, $_[0], wait => 'accepted', sub {}) },
          sub { $_[0]{input_message_content}{text} } ],
        [ 'send_file caption', sub { $td->send_file(-100, 'a.pdf', caption => $_[0], wait => 'accepted', sub {}) },
          sub { $_[0]{input_message_content}{caption} } ],
        [ 'send_gift text', sub { $td->send_gift('g1', 42, text => $_[0], sub {}) },
          sub { $_[0]{text} } ],
        [ 'quiz explanation', sub { $td->send_poll(-100, 'Q', ['a', 'b'], quiz => 1,
                                                   explanation => $_[0], wait => 'accepted', sub {}) },
          sub { $_[0]{input_message_content}{type}{explanation} } ],
        [ 'contact note', sub { $td->add_contact(9, first_name => 'A', note => $_[0], sub {}) },
          sub { $_[0]{contact}{note} } ],
        [ 'parse_markdown', sub { $td->parse_markdown($_[0], sub {}) }, sub { $_[0]{text} } ],
        [ 'translate', sub { $td->translate($_[0], 'de', sub {}) }, sub { $_[0]{text} } ],
        [ 'link_preview', sub { $td->link_preview($_[0], sub {}) }, sub { $_[0]{text} } ],
    );
    for my $s (@sites) {
        my ($name, $call, $slot) = @$s;
        @sent = ();
        $call->($ft);
        is_deeply $slot->($last->()), $ft, "$name: a formattedText goes out as it is";
        @sent = ();
        $call->(bless {}, 'StringyURL');
        is $slot->($last->())->{text}, 'https://example.org/x',
            "$name: an object that stringifies is sent as its string";
        @sent = ();
        eval { $call->([1]) };
        like $@, qr/must be a string or a formattedText/, "$name: an arrayref croaks";
        is scalar(@sent), 0, "$name: and nothing is sent";
    }
    eval { $td->translate({ '@type' => 'message' }, 'de', sub {}) };
    like $@, qr/must be a string or a formattedText/,
        'a hashref that is not a formattedText croaks too';

    # plain-string fields have nowhere to put entities
    for my $t (['text_entities', sub { $td->text_entities($_[0], sub {}) }],
               ['set_chat_description', sub { $td->set_chat_description(-100, $_[0], sub {}) }],
               ['set_bio', sub { $td->set_bio($_[0], sub {}) }]) {
        my ($name, $call) = @$t;
        @sent = ();
        eval { $call->($ft) };
        like $@, qr/must be a string|needs a string/, "$name refuses a formattedText";
        is scalar(@sent), 0, "and $name sends nothing";
        $call->(bless {}, 'StringyURL');
        like $sent[-1], qr{https://example\.org/x}, "$name takes an object that stringifies";
    }
}

done_testing;
