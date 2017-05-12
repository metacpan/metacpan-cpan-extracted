#!perl

use strict;
use warnings;
use Test::More tests => 21;
use FindBin qw($Bin);

BEGIN{ use_ok('HTML::FillInForm::Lite') }

my $s = <<'HTML';
	<form id="foo">
	<input name="bar" value="null"/>
	</form>
HTML
my $x = qr/(?: \s+ (?: name="bar" | value="ok" ) ){2}/xmsi;


like(  HTML::FillInForm::Lite->fill("$Bin/test.html", {foo => "bar"}, target => "form1"),
	qr/value="bar"/, "fill in file with target");
unlike(HTML::FillInForm::Lite->fill("$Bin/test.html", {foo => "bar"}, target => "form2"),
	qr/value="bar"/, "!fill in file with target");


like(HTML::FillInForm::Lite->fill(\$s, { bar => "ok" }, target => "foo"),
	$x, "class method fill() with target");

like(HTML::FillInForm::Lite->new(target => 'foo')->fill(\$s, { bar => "ok" }),
	$x, "new() with target");

is(HTML::FillInForm::Lite->fill(\$s, { bar => "ok" }, target => "no_foo"),
	$s, "class method fill() with different target");

is(HTML::FillInForm::Lite->new(target => "no_foo")->fill(\$s, { bar => "ok" }),
	$s, "new() with different target (no op)");

like(HTML::FillInForm::Lite->new(target => "no_foo")->fill(\$s, { bar => "ok" }, target => "foo"),
	$x, "target overriding in fill()");

is(HTML::FillInForm::Lite->new(target => 0)->fill(\$s, { bar => "ok"}),
	$s, "target => 0 (no-op)");


my $o = HTML::FillInForm::Lite->new();

like $o->fill(\$s, { bar => "ok" }, target => "foo"), $x,
	"instance method fill() with target";

is $o->fill(\$s, { bar => "ok" }, target => "no_foo"), $s,
	"different target (no-op)";

$s = <<'HTML';
	<form id='foo'>
	<input name="bar" value="null"/>
	</form>
HTML

$o = HTML::FillInForm::Lite->new(target => "foo");

like $o->fill(\$s, { bar => "ok" }), $x, "single-quoted id";

$s = <<'HTML';
	<form id=foo>
	<input name="bar" value="null"/>
	</form>
HTML

like $o->fill(\$s, { bar => "ok" }), $x, "unquoted id";

$s = <<'HTML';
	<form id="0">
	<input name="bar" value="null" />
	</form>
HTML

like   $o->fill(\$s, { bar => "ok" }, target => 0), $x, 'id="0"';
unlike $o->fill(\$s, { bar => "ok" }, target => 1), $x, 'id="0" (no-op)';

$s =~ s{ id = "0" }{name="foo"}xms;

unlike $o->fill(\$s, { bar => "ok" }, target => "foo"), $x, "undefined id(1)";
unlike $o->fill(\$s, { bar => "ok" }, target => 0),     $x, "undefined id(2)";

is $o->fill(\q{
	<form id="foo">
	<input name="bar" value="null"/>
	</form>
	<form id="not_foo">
	<input name="bar" value="null"/>
	</form>}, { bar => "ok" }, target => "foo"),

	q{
	<form id="foo">
	<input name="bar" value="ok"/>
	</form>
	<form id="not_foo">
	<input name="bar" value="null"/>
	</form>}, "the target only";

is $o->fill(\q{
	<form id="not_foo">
	<input name="bar" value="null"/>
	</form>
	<form id="foo">
	<input name="bar" value="null"/>
	</form>}, { bar => "ok" }, target => "foo"),

	q{
	<form id="not_foo">
	<input name="bar" value="null"/>
	</form>
	<form id="foo">
	<input name="bar" value="ok"/>
	</form>}, "ignore different target";

$s = <<'HTML';
	<FORM ID="foo">
	<INPUT NAME="bar" VALUE="null"/>
	</FORM>
HTML

like   $o->fill(\$s, {bar => "ok"}, target => "foo"),     $x, "UPPER CASE(match)";
unlike $o->fill(\$s, {bar => "ok"}, target => "not_foo"), $x, "UPPER CASE(unmatch)";

