#!/usr/bin/env perl
# Try Lexicon POT

use warnings;
use strict;
use lib 'lib', '../lib';
use utf8;

use Test::More tests => 44;
use File::Basename        qw/dirname/;
use File::Spec::Functions qw/catfile/;
use Encode                qw/is_utf8/;

use_ok('Log::Report::Lexicon::PO');
use_ok('Log::Report::Lexicon::POT');

my $sl_po = catfile(dirname(__FILE__), 'hello-world-slovak.po');

#
# Try reading complex example
# slightly modified from gettext examples in slovak
#

my $pot = Log::Report::Lexicon::POT->read($sl_po,
  charset => 'utf-8');

ok(defined $pot, "read pot file");
isa_ok($pot, 'Log::Report::Lexicon::POT');

#
# header
#

is($pot->header('mime-version'), '1.0', 'access to header');

#
# plurals
#

cmp_ok($pot->nrPlurals, '==', 4, 'test plural evaluation');
cmp_ok($pot->pluralIndex(0), '==', 0);
cmp_ok($pot->pluralIndex(1), '==', 1);
cmp_ok($pot->pluralIndex(2), '==', 2);
cmp_ok($pot->pluralIndex(3), '==', 3);
cmp_ok($pot->pluralIndex(4), '==', 3);
cmp_ok($pot->pluralIndex(5), '==', 0);
cmp_ok($pot->pluralIndex(6), '==', 0);
cmp_ok($pot->pluralIndex(101), '==', 1);

#
# extended single case
#

my $po = $pot->msgid('Hello, world!');
ok(defined $po, "got greeting");
isa_ok($po, 'Log::Report::Lexicon::PO');
is($po->msgid, 'Hello, world!');
ok(!defined $po->plural);

is($po->comment, 'translator comment
translator comment line 2
');

is($po->automatic, 'automatic comment
automatic comment line 2
');

my @refs = sort $po->references;
cmp_ok(scalar @refs, '==', 4);
is($refs[0], 'bis');
is($refs[1], 'hello-1.pl.in:18');
is($refs[2], 'hello-1.pl.in:20');
is($refs[3], 'hello-2.pl.in:13');

is($po->msgstr, "Pozdravljen, svet!");
is($po->msgstr(0), "Pozdravljen, svet!");
is($po->msgstr(1), "Pozdravljen, svet!");  # index gets ignored

is($pot->msgstr("Hello, world!"), "Pozdravljen, svet!");
is($pot->msgstr("Hello, world!", 0), "Pozdravljen, svet!");

is($po->toString, <<'__DUMP');
#  translator comment
#  translator comment line 2
#. automatic comment
#. automatic comment line 2
#: bis hello-1.pl.in:18 hello-1.pl.in:20 hello-2.pl.in:13
msgid "Hello, world!"
msgstr "Pozdravljen, svet!"
__DUMP

#
# with plurals
#

is($pot->msgstr('Aap', 0), 'A', 'msgstr by plural');
is($pot->msgstr('Aap', 1), 'B');
is($pot->msgstr('Aap', 2), 'C');
is($pot->msgstr('Aap', 3), 'D');
is($pot->msgstr('Aap', 4), 'D');
is($pot->msgstr('Aap', 5), 'A');
is($pot->msgstr('Aap', 6), 'A');
is($pot->msgstr('Aap', 100), 'A');
is($pot->msgstr('Aap', 101), 'B');

is($pot->msgid('Aap')->plural, 'Apen');

#
# with multi-lines and utf
#

my $po2 = $pot->msgid("This program is running as process number {pid}.multi-line\n");
ok(defined $po2, 'test multi');

my $po2t = $po2->msgstr;
is($po2t, "Ta program teče kot proces številka {pid}.multi\tline\n");
ok(is_utf8($po2t), 'is utf8');

