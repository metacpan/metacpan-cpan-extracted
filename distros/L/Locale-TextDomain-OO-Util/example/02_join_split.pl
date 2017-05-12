#!perl ## no critic (TidyCode)

use strict;
use warnings;

use Data::Dumper ();
use Locale::TextDomain::OO::Util::JoinSplitLexiconKeys;
use charnames qw(:full);

our $VERSION = 0;

my $key_util = Locale::TextDomain::OO::Util::JoinSplitLexiconKeys->instance;

() = print {*STDOUT} Data::Dumper ## no critic (LongChainsOfMethodCalls)
    ->new(
        [
            [
                # join lexicon key
                # all optional, language defaults to i-default
                $key_util->join_lexicon_key({}),
                # more real
                $key_util->join_lexicon_key({
                    language => 'de-de',
                }),
                # all keys
                $key_util->join_lexicon_key({
                    language => 'de-de',
                    category => 'my category',
                    domain   => 'my domain',
                    project  => 'my project',
                }),
                # project and subprojects
                $key_util->join_lexicon_key({
                    language => 'de-de',
                    project  => 'my project',
                }),
                $key_util->join_lexicon_key({
                    language => 'de-de',
                    project  => 'my project:my subproject',
                }),

                # split lexicon key
                # all optional, should not warn
                $key_util->split_lexicon_key,
                # more real
                $key_util->split_lexicon_key('de-de::'),
                # all keys
                $key_util->split_lexicon_key('de-de:my category:my domain:my project'),
                # project and subproject
                $key_util->split_lexicon_key('de-de:::my project'),
                $key_util->split_lexicon_key('de-de:::my project:my subproject'),

                # message key
                # should not warn
                $key_util->join_message_key({}),
                $key_util->split_message_key,
                # all
                $key_util->join_message_key(
                    {
                        msgctxt      => 'my context',
                        msgid        => 'my singular',
                        msgid_plural => 'my plural',
                    },
                ),
                $key_util->join_message_key(
                    {
                        msgctxt      => 'my context',
                        msgid        => 'my singular',
                        msgid_plural => 'my plural',
                    },
                    'JSON',
                ),
                $key_util->split_message_key(
                    "my singular\N{NULL}my plural\N{END OF TRANSMISSION}my context",
                ),
                $key_util->split_message_key(
                    'my singular{PLURAL_SEPARATOR}my plural{MSG_KEY_SEPARATOR}my context',
                    'JSON',
                ),

                # message (key and value)
                $key_util->join_message(
                    "my singular\N{NULL}my plural\N{END OF TRANSMISSION}my context",
                    {
                        msgstr_plural => [ 'tr singular', 'tr plural' ],
                    },
                ),
                [
                    $key_util->split_message(
                        {
                            msgctxt       => 'my context',
                            msgid         => 'my singular',
                            msgid_plural  => 'my plural',
                            msgstr_plural => [ 'tr singular', 'tr plural' ],
                        },
                    ),
                ],
                $key_util->join_message(
                    'my singular{PLURAL_SEPARATOR}my plural{MSG_KEY_SEPARATOR}my context',
                    {
                        msgstr_plural => [ 'tr singular', 'tr plural' ],
                    },
                    'JSON',
                ),
                [
                    $key_util->split_message(
                        {
                            msgctxt       => 'my context',
                            msgid         => 'my singular',
                            msgid_plural  => 'my plural',
                            msgstr_plural => [ 'tr singular', 'tr plural' ],
                        },
                        'JSON',
                    ),
                ],
            ],
        ],
    )
    ->Indent(1)
    ->Quotekeys(0)
    ->Sortkeys(1)
    ->Terse(1)
    ->Useqq(1)
    ->Dump;

# $Id: 02_join_split.pl 597 2015-06-29 18:27:08Z steffenw $

__END__

Output:

[
  "i-default::",
  "de-de::",
  "de-de:my category:my domain:my project",
  "de-de:::my project",
  "de-de:::my project:my subproject",
  {},
  {
    category => "",
    domain => "",
    language => "de-de"
  },
  {
    category => "my category",
    domain => "my domain",
    language => "de-de",
    project => "my project"
  },
  {
    category => "",
    domain => "",
    language => "de-de",
    project => "my project"
  },
  {
    category => "",
    domain => "",
    language => "de-de",
    project => "my project:my subproject"
  },
  "",
  {},
  "my singular\0my plural\4my context",
  "my singular{PLURAL_SEPARATOR}my plural{MSG_KEY_SEPARATOR}my context",
  {
    msgctxt => "my context",
    msgid => "my singular",
    msgid_plural => "my plural"
  },
  {
    msgctxt => "my context",
    msgid => "my singular",
    msgid_plural => "my plural"
  },
  {
    msgctxt => "my context",
    msgid => "my singular",
    msgid_plural => "my plural",
    msgstr_plural => [
      "tr singular",
      "tr plural"
    ]
  },
  [
    "my singular\0my plural\4my context",
    {
      msgstr_plural => [
        "tr singular",
        "tr plural"
      ]
    }
  ],
  {
    msgctxt => "my context",
    msgid => "my singular",
    msgid_plural => "my plural",
    msgstr_plural => [
      "tr singular",
      "tr plural"
    ]
  },
  [
    "my singular{PLURAL_SEPARATOR}my plural{MSG_KEY_SEPARATOR}my context",
    {
      msgstr_plural => [
        "tr singular",
        "tr plural"
      ]
    }
  ]
]
