#!perl -T

use strict;
use warnings;

use Test::More tests => 23;
use Test::NoWarnings;
use Test::Differences;

BEGIN {
    use_ok 'Locale::TextDomain::OO::Util::JoinSplitLexiconKeys';
}

my $key_util = Locale::TextDomain::OO::Util::JoinSplitLexiconKeys->instance;

LEXICON_KEY: {
    is
        $key_util->join_lexicon_key,
        'i-default::',
        'join empty lexicon key';
    eq_or_diff
        $key_util->split_lexicon_key,
        {},
        'split undef lexicon key';
    is
        $key_util->join_lexicon_key({
            language => 'de-de',
            category => 'my category',
            domain   => 'my domain',
            project  => 'my project:my subproject',
        }),
        'de-de:my category:my domain:my project:my subproject',
        'join lexicon key';
    eq_or_diff
        $key_util->split_lexicon_key('de-de:my category:my domain'),
        {
            language => 'de-de',
            category => 'my category',
            domain   => 'my domain',
        },
        'split lexicon key';
    eq_or_diff
        $key_util->split_lexicon_key(':::my project:my subproject'),
        {
            language => q{},
            category => q{},
            domain   => q{},
            project  => 'my project:my subproject',
        },
        'split lexicon key';
}

MESSAGE_KEY: {
    is
        $key_util->join_message_key({}),
        q{},
        'join empty message key';
    eq_or_diff
        $key_util->split_message_key,
        {},
        'split undef message key';
    eq_or_diff
        $key_util->join_message_key({
            msgctxt      => 'my context',
            msgid        => 'my singular',
            msgid_plural => 'my plural',
        }),
        "my singular\x00my plural\x04my context",
        'join message key';
    eq_or_diff
        $key_util->split_message_key("my singular\x00my plural\x04my context"),
        {
            msgctxt      => 'my context',
            msgid        => 'my singular',
            msgid_plural => 'my plural',
        },
        'split message key';
}

MESSAGE_KEY_JSON: {
    is
        $key_util->join_message_key(undef, 'JSON'),
        q{},
        'join empty JSON message key';
    eq_or_diff
        $key_util->split_message_key(undef, 'JSON'),
        {},
        'split undef JSON message key';
    eq_or_diff
        $key_util->join_message_key(
            {
                msgctxt      => 'my context',
                msgid        => 'my singular',
                msgid_plural => 'my plural',
            },
            'JSON',
        ),
        "my singular{PLURAL_SEPARATOR}my plural{MSG_KEY_SEPARATOR}my context",
        'join JSON message key';
    eq_or_diff
        $key_util->split_message_key(
            'my singular{PLURAL_SEPARATOR}my plural{MSG_KEY_SEPARATOR}my context',
            'JSON',
        ),
        {
            msgctxt      => 'my context',
            msgid        => 'my singular',
            msgid_plural => 'my plural',
        },
        'split JSON message key';
}

MESSAGE: {
    eq_or_diff
        $key_util->join_message,
        { msgid => q{} },
        'join empty message';
    eq_or_diff
        [ $key_util->split_message ],
        [ q{}, {} ],
        'split no message';
    eq_or_diff
        $key_util->join_message(
            "my singular\x00my plural\x04my context",
            {
                msgstr_plural => [ 'tr singular', 'tr plural' ],
                reference     => { 'dir/file:123' => undef },
            },
        ),
        {
                msgctxt       => 'my context',
                msgid         => 'my singular',
                msgid_plural  => 'my plural',
                msgstr_plural => [ 'tr singular', 'tr plural' ],
                reference     => { 'dir/file:123' => undef },
        },
        'join message';
    eq_or_diff
        [
            $key_util->split_message({
                msgctxt       => 'my context',
                msgid         => 'my singular',
                msgid_plural  => 'my plural',
                msgstr_plural => [ 'tr singular', 'tr plural' ],
                reference     => { 'dir/file:123' => undef },
            })
        ],
        [
            "my singular\x00my plural\04my context",
            {
                msgstr_plural => [ 'tr singular', 'tr plural' ],
                reference     => { 'dir/file:123' => undef },
            },
        ],
        'split message';
}

MESSAGE_JSON: {
    eq_or_diff
        $key_util->join_message(undef, undef, 'JSON'),
        { msgid => q{} },
        'join empty JSON message';
    eq_or_diff
        [ $key_util->split_message(undef, 'JSON') ],
        [ q{}, {} ],
        'split no JSON message';
    eq_or_diff
        $key_util->join_message(
            'my singular{PLURAL_SEPARATOR}my plural{MSG_KEY_SEPARATOR}my context',
            {
                msgstr_plural => [ 'tr singular', 'tr plural' ],
                reference     => { 'dir/file:123' => undef },
            },
            'JSON',
        ),
        {
                msgctxt       => 'my context',
                msgid         => 'my singular',
                msgid_plural  => 'my plural',
                msgstr_plural => [ 'tr singular', 'tr plural' ],
                reference     => { 'dir/file:123' => undef },
        },
        'join JSON message';
    eq_or_diff
        [
            $key_util->split_message(
                {
                    msgctxt       => 'my context',
                    msgid         => 'my singular',
                    msgid_plural  => 'my plural',
                    msgstr_plural => [ 'tr singular', 'tr plural' ],
                    reference     => { 'dir/file:123' => undef },
                },
                'JSON',
            )
        ],
        [
            'my singular{PLURAL_SEPARATOR}my plural{MSG_KEY_SEPARATOR}my context',
            {
                msgstr_plural => [ 'tr singular', 'tr plural' ],
                reference     => { 'dir/file:123' => undef },
            },
        ],
        'split JSON message';
}
