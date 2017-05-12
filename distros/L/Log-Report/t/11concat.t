#!/usr/bin/env perl
# Try concatenation

use warnings;
use strict;
use lib 'lib', '../lib';

use Test::More tests => 15;

use Log::Report;   # no domains, no translator
use Scalar::Util qw/refaddr/;

### examples from Log::Report::Message and more

my $a = __"Hello";
isa_ok($a, 'Log::Report::Message');
my $b = $a . " World!\n";
isa_ok($b, 'Log::Report::Message');
cmp_ok(refaddr $a, '!=', refaddr $b);  # must clone
is("$b", "Hello World!\n");

my $c = 'a' . 'b' . __("c") . __("d") . "e" . __("f");
isa_ok($c, 'Log::Report::Message');
is("$c", "abcdef");
is($c->prepend, 'ab');
isa_ok($c->append, 'Log::Report::Message');
is($c->msgid, 'c');
is($c->untranslated->toString, 'abcdef');

my $d = __("Hello")->concat(' ')->concat(__"World!")->concat("\n");
isa_ok($d, 'Log::Report::Message');
is("$d", "Hello World!\n");
is($d->untranslated->toString, "Hello World!\n");

my $h = __"Hello";
my $w = __"World!";
my $e =  "$h $w\n";
isa_ok($e, 'Log::Report::Message');
is("$e", "Hello World!\n");
