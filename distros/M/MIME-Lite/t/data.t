#!/usr/bin/perl
use strict;
use warnings;

use MIME::Lite;
use Test::More;

# Make a tester... here are 3 different alternatives:
$MIME::Lite::VANILLA  = 1;
$MIME::Lite::PARANOID = 1;

my ($me, $str);

#------------------------------
$me = MIME::Lite->build(Type => 'text/plain',
      Data => "Hello\nWorld\n");
$str = $me->as_string;
ok(($str =~ m{Hello\nWorld\n}), "Data string");

#------------------------------
$me = MIME::Lite->build(Type => 'text/plain',
      Data => ["Hel", "lo\n", "World\n"]);
$str = $me->as_string;
ok(($str =~ m{Hello\nWorld\n}), "Data array 1");

#------------------------------
$me = MIME::Lite->build(Type => 'text/plain',
      Data => ["Hel", "lo", "\n", "", "World", "", "","\n"]);
$str = $me->as_string;
ok(($str =~ m{Hello\nWorld\n}), "Data array 2");

#------------------------------
$me = MIME::Lite->build(Type => 'text/plain',
      Path => "./testin/hello");
$str = $me->as_string;
ok(($str =~ m{Hello\r?\nWorld\r?\n}), "Data file");

done_testing;
