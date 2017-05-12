#!perl -T

use strict;
use warnings;

use Test::More tests => 5 + 1;
use Test::NoWarnings;
use Test::Differences;
BEGIN {
    use_ok('Locale::File::PO::Header');
}

my $obj = Locale::File::PO::Header->new;

# read keys
eq_or_diff(
    [ $obj->all_keys ],
    [ qw(
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
    ) ],
    'all_keys',
);

eq_or_diff(
    $obj->msgstr . "\n",
    << 'EOT',
MIME-Version: 1.0
Content-Type: text/plain; charset=ISO-8859-1
Content-Transfer-Encoding: 8bit
EOT
    'default msgstr',
);

eq_or_diff(
    do {
        $obj->data({
            'Project-Id-Version'           => 'Testproject',
            'Report-Msgid-Bugs-To_name'    => 'Bug Reporter',
            'Report-Msgid-Bugs-To_address' => 'bug@example.org',
            'POT-Creation-Date'            => 'no POT creation date',
            'PO-Revision-Date'             => 'no PO revision date',
            'Last-Translator_name'         => 'Steffen Winkler',
            'Last-Translator_address'      => 'steffenw@example.org',
            'Language-Team_name'           => 'MyTeam',
            'Language-Team_address'        => 'cpan@example.org',
            'MIME-Version'                 => '1.0',
            'Content-Type'                 => 'text/plain',
            charset                        => 'UTF-8',
            'Content-Transfer-Encoding'    => '8bit',
            'Plural-Forms'                 => 'nplurals=1; plural=0',
            extended                       => [
                'X-Poedit-Language'      => 'German',
                'X-Poedit-Country'       => 'GERMANY',
                'X-Poedit-SourceCharset' => 'utf-8',
            ],
        });
        $obj->msgstr . "\n";
    },
    << 'EOT',
Project-Id-Version: Testproject
Report-Msgid-Bugs-To: Bug Reporter <bug@example.org>
POT-Creation-Date: no POT creation date
PO-Revision-Date: no PO revision date
Last-Translator: Steffen Winkler <steffenw@example.org>
Language-Team: MyTeam <cpan@example.org>
MIME-Version: 1.0
Content-Type: text/plain; charset=UTF-8
Content-Transfer-Encoding: 8bit
Plural-Forms: nplurals=1; plural=0
X-Poedit-Language: German
X-Poedit-Country: GERMANY
X-Poedit-SourceCharset: utf-8
EOT
    'set data',
);

$obj->msgstr(<<'EOT');
Project-Id-Version: Testproject
Report-Msgid-Bugs-To: Bug Reporter
Last-Translator: test@example.org
MIME-Version: 1.1
Content-Type: text/plain; charset=ISO-8859-15
Content-Transfer-Encoding: 7bit
X-Poedit-Language: English
myMIME-Version: 1.2
EOT
eq_or_diff(
    $obj->msgstr . "\n",
    <<'EOT',
Project-Id-Version: Testproject
Report-Msgid-Bugs-To: Bug Reporter
Last-Translator: test@example.org
MIME-Version: 1.1
Content-Type: text/plain; charset=ISO-8859-15
Content-Transfer-Encoding: 7bit
X-Poedit-Language: English
myMIME-Version: 1.2
EOT
    'set msgstr',
);
