#!perl

use strict;
use warnings;

use Test::More;
use Test::Differences;
use Cwd qw(getcwd chdir);

$ENV{TEST_EXAMPLE} or plan(
    skip_all => 'Set $ENV{TEST_EXAMPLE} to run this test.'
);

plan(tests => 2);

my @data = (
    {
        test   => '11_build_header',
        path   => 'example',
        script => '-I../lib -T 11_build_header.pl',
        result => <<'EOT',
all keys:
Project-Id-Version
Report-Msgid-Bugs-To_name
Report-Msgid-Bugs-To_address
POT-Creation-Date
PO-Revision-Date
Last-Translator_name
Last-Translator_address
Language-Team_name
Language-Team_address
MIME-Version
Content-Type
charset
Content-Transfer-Encoding
Plural-Forms
extended

empty msgstr:
MIME-Version: 1.0
Content-Type: text/plain; charset=ISO-8859-1
Content-Transfer-Encoding: 8bit

some keys set:
Project-Id-Version: Testproject 1
Report-Msgid-Bugs-To: Bug1 Reporter
Last-Translator: bug1@example.org
MIME-Version: 1.0
Content-Type: text/plain; charset=ISO-8859-1
Content-Transfer-Encoding: 8bit

all possible keys set:
Project-Id-Version: Testproject 2
Report-Msgid-Bugs-To: Bug2 Reporter <bug2@example.org>
POT-Creation-Date: no POT creation date
PO-Revision-Date: no PO revision date
Last-Translator: Steffen Winkler <steffenw@example.org>
Language-Team: MyTeam <cpan@example.org>
MIME-Version: 1.0
Content-Type: text/plain; charset=utf-8
Content-Transfer-Encoding: 8bit
X-Poedit-Language: German
X-Poedit-Country: GERMANY
X-Poedit-SourceCharset: utf-8

project and charset changed:
Project-Id-Version: Testproject 3
Report-Msgid-Bugs-To: Bug2 Reporter <bug2@example.org>
POT-Creation-Date: no POT creation date
PO-Revision-Date: no PO revision date
Last-Translator: Steffen Winkler <steffenw@example.org>
Language-Team: MyTeam <cpan@example.org>
MIME-Version: 1.0
Content-Type: text/plain; charset=ISO-8859-15
Content-Transfer-Encoding: 8bit
X-Poedit-Language: German
X-Poedit-Country: GERMANY
X-Poedit-SourceCharset: utf-8

EOT
    },
    {
        test   => '12_get_header',
        path   => 'example',
        script => '-I../lib -T 12_get_header.pl',
        result => <<'EOT',
get 1 item of msgstr as scalar:
Testproject
get 0 or many items of msgstr as array:
$items = [
  'Testproject',
  'bug@example.org',
  [
    'X-Poedit-Language',
    'German',
    'X-Poedit-Country',
    'GERMANY',
    'X-Poedit-SourceCharset',
    'utf-8'
  ]
];
EOT
    },
);

for my $data (@data) {
    my $dir = getcwd();
    chdir("$dir/$data->{path}");
    my $result = qx{perl $data->{script} 2>&3};
    chdir($dir);
    eq_or_diff(
        $result,
        $data->{result},
        $data->{test},
    );
}
