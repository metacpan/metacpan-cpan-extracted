#!/usr/bin/env perl
# Try Lexicon PO modifications

use warnings;
use strict;
use utf8;

use Test::More tests => 29;
use_ok('Log::Report::Lexicon::PO');
use_ok('Log::Report::Lexicon::POT');

#
# Create header
#

$Log::Report::VERSION = 'SOME_VERSION';
my $pot = Log::Report::Lexicon::POT->new
 ( textdomain => 'log-report'
 , version    => '2.3'
 , charset    => 'UTF-8'
 , date       => 'DUMMY'   # don't want this to change during test
 );

is($pot->msgstr(''), <<'__HEADER');
Project-Id-Version: log-report 2.3
Report-Msgid-Bugs-To:
POT-Creation-Date: DUMMY
PO-Revision-Date: DUMMY
Last-Translator:
Language-Team:
MIME-Version: 1.0
Content-Type: text/plain; charset=UTF-8
Content-Transfer-Encoding: 8bit
Plural-Forms: nplurals=2; plural=(n!=1);
__HEADER

is($pot->msgid('')->toString, <<'__HEAD');
#. Header generated with Log::Report::Lexicon::POT SOME_VERSION
msgid ""
msgstr ""
"Project-Id-Version: log-report 2.3\n"
"Report-Msgid-Bugs-To:\n"
"POT-Creation-Date: DUMMY\n"
"PO-Revision-Date: DUMMY\n"
"Last-Translator:\n"
"Language-Team:\n"
"MIME-Version: 1.0\n"
"Content-Type: text/plain; charset=UTF-8\n"
"Content-Transfer-Encoding: 8bit\n"
"Plural-Forms: nplurals=2; plural=(n!=1);\n"
__HEAD

cmp_ok($pot->nrPlurals, "==", 2);

is($pot->header('mime-version'), '1.0');
is($pot->header('mime-version', '3.14'), '3.14');
is($pot->header('mime-version'), '3.14');
is($pot->header('mime-version', undef), undef);
is($pot->header('new-field', 'some value'), 'some value');

$pot->updated('NEWDATE');

is($pot->msgid('')->toString, <<'__HEAD');
#. Header generated with Log::Report::Lexicon::POT SOME_VERSION
msgid ""
msgstr ""
"Project-Id-Version: log-report 2.3\n"
"Report-Msgid-Bugs-To:\n"
"POT-Creation-Date: DUMMY\n"
"PO-Revision-Date: NEWDATE\n"
"Last-Translator:\n"
"Language-Team:\n"
"Content-Type: text/plain; charset=UTF-8\n"
"Content-Transfer-Encoding: 8bit\n"
"Plural-Forms: nplurals=2; plural=(n!=1);\n"
"new-field: some value\n"
__HEAD

#
# Create non-plural
#

my $po = Log::Report::Lexicon::PO->new
 ( msgid      => 'aap'
 , references => 'aap.pm:10'
 );

is($po->toString, <<'__AAP', 'no translation');
#: aap.pm:10
msgid "aap"
msgstr ""
__AAP

$po->addReferences('monkey.pm:12 aap.pm:3');
$po->msgstr(0, 'monkey');
is($po->toString, <<'__AAP', 'with translation');
#: aap.pm:10 aap.pm:3 monkey.pm:12
msgid "aap"
msgstr "monkey"
__AAP

is($po->plural("apen"), 'apen', 'add plural');
ok($po->fuzzy(1), 'is fuzzy');

is($po->toString, <<'__AAP');
#: aap.pm:10 aap.pm:3 monkey.pm:12
#, fuzzy
msgid "aap"
msgid_plural "apen"
msgstr[0] "monkey"
msgstr[1] ""
__AAP

is($po->toString(nr_plurals => $pot->nrPlurals), <<'__AAP');
#: aap.pm:10 aap.pm:3 monkey.pm:12
#, fuzzy
msgid "aap"
msgid_plural "apen"
msgstr[0] "monkey"
msgstr[1] ""
__AAP

$po->msgstr(1, 'monkeys');
$po->fuzzy(0);
cmp_ok($po->removeReferencesTo('aap.pm'), '==', 1);

is($po->toString(nr_plurals => $pot->nrPlurals), <<'__AAP');
#: monkey.pm:12
msgid "aap"
msgid_plural "apen"
msgstr[0] "monkey"
msgstr[1] "monkeys"
__AAP

#
# Index
#

ok(!$pot->msgid('aap'));
is($pot->add($po), $po, 'add');
is($pot->msgid('aap'), $po);

is($pot->msgstr('aap', 0), 'monkeys');
is($pot->msgstr('aap', 1), 'monkey');
is($pot->msgstr('aap', 2), 'monkeys');

#
# disable/enable
#

cmp_ok($po->removeReferencesTo('monkey.pm'), "==", 0, 'rm last ref');
is($po->toString(nr_plurals => $pot->nrPlurals), <<'__AAP');
#~ msgid "aap"
#~ msgid_plural "apen"
#~ msgstr[0] "monkey"
#~ msgstr[1] "monkeys"
__AAP

$po->addReferences('noot.pm:12', 'aap.pm:42');
is($po->toString(nr_plurals => $pot->nrPlurals), <<'__AAP');
#: aap.pm:42 noot.pm:12
msgid "aap"
msgid_plural "apen"
msgstr[0] "monkey"
msgstr[1] "monkeys"
__AAP

#
# Write
#

my $text = '';
open TEXT, '>:utf8', \$text;
$pot->write(\*TEXT);
close TEXT;

is($text, <<'__ALL')
#. Header generated with Log::Report::Lexicon::POT SOME_VERSION
msgid ""
msgstr ""
"Project-Id-Version: log-report 2.3\n"
"Report-Msgid-Bugs-To:\n"
"POT-Creation-Date: DUMMY\n"
"PO-Revision-Date: NEWDATE\n"
"Last-Translator:\n"
"Language-Team:\n"
"Content-Type: text/plain; charset=UTF-8\n"
"Content-Transfer-Encoding: 8bit\n"
"Plural-Forms: nplurals=2; plural=(n!=1);\n"
"new-field: some value\n"

#: aap.pm:42 noot.pm:12
msgid "aap"
msgid_plural "apen"
msgstr[0] "monkey"
msgstr[1] "monkeys"
__ALL
