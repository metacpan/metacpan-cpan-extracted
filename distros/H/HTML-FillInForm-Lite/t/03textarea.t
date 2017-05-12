#!perl

use strict;
use warnings;

use Test::More tests => 18;

BEGIN{ use_ok('HTML::FillInForm::Lite') }


my %q = (
	foo => 'bar',
);


my $o = HTML::FillInForm::Lite->new();


is $o->fill(\qq{<textarea name="foo">xxx</textarea>}, \%q),
	     qq{<textarea name="foo">bar</textarea>}, "fill textarea";

is $o->fill(\qq{<TEXTAREA NAME="foo">xxx</TEXTAREA>}, \%q),
	     qq{<TEXTAREA NAME="foo">bar</TEXTAREA>}, "fill textarea (UPPER CASE)";

is $o->fill(\qq{<textarea name="foo"></textarea>}, \%q),
	     qq{<textarea name="foo">bar</textarea>}, "fill empty textarea";

is $o->fill(\qq{<textarea name='foo'>xxx</textarea>}, \%q),
	     qq{<textarea name='foo'>bar</textarea>}, "fill textarea (single-quoted name)";

is $o->fill(\qq{<textarea name=foo>xxx</textarea>}, \%q),
	     qq{<textarea name=foo>bar</textarea>}, "fill textarea (unquoted name)";

is $o->fill(\qq{<textarea name="foo">xxx</textarea>}, [{}, \%q]),
	     qq{<textarea name="foo">bar</textarea>}, "fill textarea with array data";

	     
is $o->fill(\qq{<textarea name="bar">xxx</textarea>}, \%q),
	     qq{<textarea name="bar">xxx</textarea>}, "doesn't fill textarea with unmatched name";

is $o->fill(\qq{<textarea name="foo">xxx</textarea>}, { foo => '<foo> & <bar>' }),
	     qq{<textarea name="foo">&lt;foo&gt; &amp; &lt;bar&gt;</textarea>}, "html-escape";

is $o->fill(\qq{<textarea name="foo">xxx</textarea>}, { foo => '' }),
	     qq{<textarea name="foo"></textarea>}, "empty textarea";

is $o->fill(\qq{<textarea name="foo">xxx</textarea>}, { foo => undef }),
	     qq{<textarea name="foo">xxx</textarea>}, "{ NAME => undef } is ignored";

is $o->fill(\qq{<textarea name="foo">xxx}, \%q),
	     qq{<textarea name="foo">xxx}, "ignore syntax error";


my $s = <<'EOT';
<form id="bar">
<textarea name="foo" id="0">0</textarea>
<textarea name="foo" id="1">1</textarea>
<textarea name="foo" id="2">2</textarea>
<form>
EOT

$q{foo} = [qw(foo0 foo1)];

is $o->fill(\$s, \%q, target => "foo"), $s, "target => _";
my $output = $o->fill(\$s, \%q);

like $output, qr/ id="0"[^>]* >foo0< /xms, "multi-textareas(0)";
like $output, qr/ id="1"[^>]* >foo1< /xms, "multi-textareas(1)";
like $output, qr/ id="2"[^>]* >2< /xms,    "multi-textareas(2) - out of range";

# re-fill
$s = qq{<textarea name="foo">xxx</textarea>};
$output = $o->fill(\$s, \%q);

for(1 .. 2){
	is $o->fill(\$output, \%q), $output, "re-fill ($_)";
}
