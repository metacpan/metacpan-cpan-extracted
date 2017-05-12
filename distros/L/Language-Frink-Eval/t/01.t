#!/usr/bin/perl

use strict;
use warnings;
use Test::More tests => 20;

use Language::Frink::Eval;

my $frink = Language::Frink::Eval->new(Restricted => 1);

require_ok('Params::Validate');
isa_ok($frink, 'Language::Frink::Eval');

eval { $frink->eval('if ( line =~ %r/Alan/i )') };
like($@, qr/reg.+exp.+not.+allowed/i, "regex disabled");

eval { $frink->eval('blah := x > 0') };
like($@, qr/function.+not.+allowed/i, "functions declarations disabled");

eval { $frink->eval('electric_potential :-> "volts"') };
like($@, qr/display.+format.+not.+changed/i, "display format changes disabled"); 

eval { $frink->eval('while i<1000 {') };
like($@, qr/while.+not.+allow/i, "while disabled");

eval { $frink->eval(' for i = 1 to 10000') };
like($@, qr/for.+not.+allow/i, "for disabled");

eval { $frink->eval(' #### G yyyy-MM-dd hh:mm:ss.SSS a (E) zzzz ####') };
like($@, qr/redefine.+default.+time/i, "default time format change disabled");

eval { $frink->eval('  isEven = { |x| x mod 2 == 0 }') };
like($@, qr/procedure.+block.+not.+allowed/i, "procedure blocks disabled");

eval { $frink->eval('  use sun.frink') };
like($@, qr/inclusion.+not.+allowed/i, "inclusion disabled");

eval { $frink->eval(' class mine') };
like($@, qr/class.+not.+allowed/i, "classes disabled");

eval { $frink->eval(' x = lines["http://www.oneill.net"]') };
like($@, qr/function.*not.*allowed/i, "functions filtered");

is($frink->eval("2+2"), 4, "2+2 = 4");
like($frink->eval("now[]"), qr/\d{2}:\d{2}:\d{2}/, "now[]");
is($frink->eval("1 dollar_1920"), "9.485 dollar (currency)", "1920 dollar");
is($frink->eval('"hello" -> fr'), "bonjour", "english -> french");

# this test should probably be more generalized
my $errortext = q{ Conformance error
   Left side is: 201168/125 (exactly 1609.344) m (length)
  Right side is: 473176473/16000000000000 (exactly 2.95735295625e-5) m^3 (volume)
     Suggestion: multiply left side by area

 For help, type: units[area]
                   to list known units with these dimensions.};
is($frink->eval('miles -> floz'), $errortext, "errortext");

is($frink->restricted(0), 1, "restrict == 1");
is($frink->restricted(), 0, "restrict == 0");

my $val;
eval { $val = $frink->eval('"test" =~ %r/test/') };
is($val, "[]", "regex allowed");
