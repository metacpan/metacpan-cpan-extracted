#!perl

use strict;
use warnings;

use Test::More;
use Test::Differences;
use Cwd qw(getcwd chdir);
use English qw(-no_match_vars $CHILD_ERROR);

$ENV{AUTHOR_TESTING}
    or plan skip_all => 'Set $ENV{AUTHOR_TESTING} to run this test.';

my @data = (
    {
        test   => '01_constants',
        path   => 'example',
        script => '-I../lib 01_constants.pl',
        result => <<'EOT',
$constants = {
  lexicon_key_separator => ":",
  msg_key_separator => "\4",
  plural_separator => "\0"
};
EOT
    },
    {
        test   => '02_join_split',
        path   => 'example',
        script => '-I../lib 02_join_split.pl',
        result => <<'EOT',
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
EOT
    },
    {
        test   => '03_extract_header',
        path   => 'example',
        script => '-I../lib 03_extract_header.pl',
        result => <<'EOT',
$extract = {
  charset => "UTF-8",
  lexicon_class => "Foo::Bar",
  nplurals => 2,
  plural => "n != 1",
  plural_code => sub { "DUMMY" }
};
EOT
    },
);

plan tests => scalar @data;

for my $data (@data) {
    my $dir = getcwd;
    chdir("$dir/$data->{path}");
    my $result = qx{perl $data->{script} 2>&1};
    $CHILD_ERROR
        and die "Couldn't run $data->{script} (status $CHILD_ERROR)";
    chdir($dir);
    eq_or_diff
        $result,
        $data->{result},
        $data->{test};
}
