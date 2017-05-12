#!/usr/bin/env perl
# Try Lexicon POTcompact
# Structure of parsed result has also been checked manually, using
# Data::Dumper (MO 2007/05/11)

use warnings;
use strict;
use lib 'lib', '../lib';
use utf8;

use Test::More tests => 21;

use File::Basename        qw/dirname/;
use File::Spec::Functions qw/catfile/;

use_ok('Log::Report::Lexicon::POTcompact');

my $sl_po = catfile(dirname(__FILE__), 'hello-world-slovak.po');

#
# Try reading complex example
# slightly modified from gettext examples in slovak
#

my $pot = Log::Report::Lexicon::POTcompact->read($sl_po,
  charset => 'utf-8');

ok(defined $pot, "read pot file");
isa_ok($pot, 'Log::Report::Lexicon::POTcompact');

#
# header
#

is($pot->header('mime-version'), '1.0', 'access to header');

#
# extended single case
#

my $po = $pot->msgid('Hello, world!');
ok(defined $po, "got greeting");
ok(!ref $po, "one translation only");
is($po, "Pozdravljen, svet!");

is($pot->msgstr("Hello, world!"), "Pozdravljen, svet!");
is($pot->msgstr("Hello, world!", 0), "Pozdravljen, svet!");
is($pot->msgstr("Hello, world!", 5), "Pozdravljen, svet!");

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

#
# with multi-lines and utf
#

my $po2 = $pot->msgid("This program is running as process number {pid}.multi-line\n");
ok(defined $po2, 'test multi');
is($po2, "Ta program teče kot proces številka {pid}.multi\tline\n");

