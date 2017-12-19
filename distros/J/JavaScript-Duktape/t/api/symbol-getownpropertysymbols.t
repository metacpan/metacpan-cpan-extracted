use lib './lib';
use strict;
use warnings;
use JavaScript::Duktape;
use Data::Dumper;

require './t/helper.pl';

my $js = JavaScript::Duktape->new();
my $duk = $js->duk;

sub test_basic {
    $duk->eval_string(
		"(function (o) {\n"
		. "    Object.getOwnPropertySymbols(o).forEach(function (sym, idx) {\n"
		. "        print(idx, String(sym), o[sym]);\n"
		. "    });\n"
		. "})\n");

	$duk->push_object();

	$duk->push_string("\xFF" . "applicationHidden");
	$duk->push_uint(101);
	$duk->put_prop(-3);

	$duk->push_string("\x80" . "global");
	$duk->push_uint(102);
	$duk->put_prop(-3);

	$duk->push_string("\x81" . "local" . "\xFF" . "unique");
	$duk->push_uint(103);
	$duk->put_prop(-3);

	$duk->push_string("\x81" . "\xFF" . "unique");  # local, empty description */
	$duk->push_uint(104);
	$duk->put_prop(-3);

	$duk->push_string("\x81" . "\xFF" . "unique" . "\xFF");  # local, undefined description */
	$duk->push_uint(105);
	$duk->put_prop(-3);

	$duk->push_string("\x81" . "wellknown" . "\xFF");
	$duk->push_uint(106);
	$duk->put_prop(-3);

	$duk->push_string("\x82" . "duktapeHidden");
	$duk->push_uint(107);
	$duk->put_prop(-3);

	## 0x83 to 0xBF are reserved but currently not interpreted as symbols.
	## Sample some values.

	$duk->push_string("\x83" . "notSymbol");
	$duk->push_uint(201);
	$duk->put_prop(-3);
	$duk->push_string("\x84" . "notSymbol");
	$duk->push_uint(202);
	$duk->put_prop(-3);
	$duk->push_string("\x85" . "notSymbol");
	$duk->push_uint(203);
	$duk->put_prop(-3);
	$duk->push_string("\x86" . "notSymbol");
	$duk->push_uint(204);
	$duk->put_prop(-3);
	$duk->push_string("\x87" . "notSymbol");
	$duk->push_uint(205);
	$duk->put_prop(-3);
	$duk->push_string("\x88" . "notSymbol");
	$duk->push_uint(206);
	$duk->put_prop(-3);
	$duk->push_string("\x89" . "notSymbol");
	$duk->push_uint(207);
	$duk->put_prop(-3);
	$duk->push_string("\x8A" . "notSymbol");
	$duk->push_uint(208);
	$duk->put_prop(-3);
	$duk->push_string("\x8B" . "notSymbol");
	$duk->push_uint(209);
	$duk->put_prop(-3);
	$duk->push_string("\x8C" . "notSymbol");
	$duk->push_uint(210);
	$duk->put_prop(-3);
	$duk->push_string("\x8D" . "notSymbol");
	$duk->push_uint(211);
	$duk->put_prop(-3);
	$duk->push_string("\x8E" . "notSymbol");
	$duk->push_uint(212);
	$duk->put_prop(-3);
	$duk->push_string("\x8F" . "notSymbol");
	$duk->push_uint(213);
	$duk->put_prop(-3);
	$duk->push_string("\x9F" . "notSymbol");
	$duk->push_uint(214);
	$duk->put_prop(-3);
	$duk->push_string("\xAF" . "notSymbol");
	$duk->push_uint(215);
	$duk->put_prop(-3);
	$duk->push_string("\xBF" . "notSymbol");
	$duk->push_uint(216);
	$duk->put_prop(-3);

	# [ func obj ]

	$duk->call(1);  # -> [ res ]

	printf("final top: %ld\n", $duk->get_top());
	return 0;
}

TEST_SAFE_CALL($duk, \&test_basic, 'test_basic');

test_stdout();

__DATA__
*** test_basic (duk_safe_call)
0 Symbol(global) 102
1 Symbol(local) 103
2 Symbol() 104
3 Symbol() 105
4 Symbol(wellknown) 106
final top: 1
==> rc=0, result='undefined'
