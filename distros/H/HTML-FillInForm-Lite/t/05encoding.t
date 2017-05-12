#!perl

use strict;
use warnings;
use Test::More;

BEGIN{
	require utf8; # probably noop
	if(not defined &utf8::is_utf8){
		plan skip_all => "require utf8::is_utf8()";
	}
	else{
		plan tests => 8;
	}
}

BEGIN{ use_ok('HTML::FillInForm::Lite') }

my $o = HTML::FillInForm::Lite->new();

my $u1  = "\x{99f1}\x{99dd}";         # "camel" in Japanese kanji
my $u2  = "\x{30e9}\x{30af}\x{30c0}"; # "camel" in Japanese katakana

my $x = qr{value="$u1"};

my $s1 = q{<input name="camel" value="xxx" />};
like $o->fill(\$s1,
	{ camel => $u1 }), $x, "Unicode value";

like $o->fill(\qq{<input name="$u2" value="xxx" />},
	{ $u2 => 'camel' }), qr/value="camel"/, "Unicode name";

my $s2 =  qq{<input name="$u2" value="xxx" />};
like $o->fill(\$s2, { $u2 => $u1 }),
	$x, "Unicode name/value";

my %q;
$q{utf8}  = "\x{99f1}\x{99dd}";         # UTF-8 flagged
$q{bytes} = "\xe9\xa7\xb1\xe9\xa7\x9d"; # UTF-8 bytes


my $foo = q{<input name="utf8" />};
my $bar = q{<input name="bytes" />};

utf8::upgrade($foo);
utf8::upgrade($bar);

like $o->fill(\$foo, \%q),
	qr/\Q$q{utf8}\E/xms, "fill in utf8 with utf8";
like $o->fill(\$bar, \%q),
	qr/\Q$q{utf8}\E/xms, "fill in utf8 with bytes";

utf8::downgrade($foo);
utf8::downgrade($bar);

like $o->fill(\$foo, \%q),
	qr/$q{utf8}/xms, "fill in bytes with utf8";

like $o->fill(\$bar, \%q),
	qr/$q{bytes}/xms, "fill in bytes with bytes";

