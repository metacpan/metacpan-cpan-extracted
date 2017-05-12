#!perl -T ## no critic (TidyCode)

use strict;
use warnings;

our $VERSION = 0;

require Locale::File::PO::Header;

my $obj = Locale::File::PO::Header->new;

# get all keys
() = print
    "all keys:\n",
    ( join "\n", $obj->all_keys ),
    "\n\n";

# build an empty msgstr
() = print
    "empty msgstr:\n",
    $obj->msgstr,
    "\n\n";

# build a customized msgstr
# 3 possible ways:
# - from string
# - from hash
# - item by item

# from string
$obj->msgstr(<<'EOT');
Project-Id-Version: Testproject 1
Report-Msgid-Bugs-To: Bug1 Reporter
Last-Translator: bug1@example.org
EOT
() = print
    "some keys set:\n",
    $obj->msgstr,
    "\n\n";

# from hash
$obj->data({
    'Project-Id-Version'           => 'Testproject 2',
    'Report-Msgid-Bugs-To_name'    => 'Bug2 Reporter',
    'Report-Msgid-Bugs-To_address' => 'bug2@example.org',
    'POT-Creation-Date'            => 'no POT creation date',
    'PO-Revision-Date'             => 'no PO revision date',
    'Last-Translator_name'         => 'Steffen Winkler',
    'Last-Translator_address'      => 'steffenw@example.org',
    'Language-Team_name'           => 'MyTeam',
    'Language-Team_address'        => 'cpan@example.org',
    'MIME-Version'                 => '1.0',
    'Content-Type'                 => 'text/plain',
    'charset'                      => 'utf-8',
    'Content-Transfer-Encoding'    => '8bit',
    'extended'                     => [
        'X-Poedit-Language'      => 'German',
        'X-Poedit-Country'       => 'GERMANY',
        'X-Poedit-SourceCharset' => 'utf-8',
    ],
});
() = print
    "all possible keys set:\n",
    $obj->msgstr,
    "\n\n";

# item by item
$obj->item('Project-Id-Version' => 'Testproject 3');
$obj->item(charset  => 'ISO-8859-15');
$obj->item(extended => undef);
() = print
    "project and charset changed:\n",
    $obj->msgstr,
    "\n\n";

# $Id: 12_build_header.pl 602 2011-11-13 13:49:23Z steffenw $

__END__

Output:

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
