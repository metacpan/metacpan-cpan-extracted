#!perl

use strict;
use warnings;

use Test::More tests => 15;

BEGIN{ use_ok('HTML::FillInForm::Lite') }

my %q = (
	foo => 'bar',
);

my $o = HTML::FillInForm::Lite->new();

my $x = qr{<option \s+ selected="selected"> \s*bar\s* </option>}xmsi;

my $output;

like $o->fill(\ qq{<select name="foo"><option>bar</option></select>}, \%q),
	$x,
	  	  "select an option (no white-space)";

like $o->fill(\ qq{<select name='foo'><option>bar</option></select>}, \%q),
	$x,
	  	  "select an option (single-quoted name)";

like $o->fill(\ qq{<select name=foo><option>bar</option></select>}, \%q),
	$x,
	  	  "select an option (unquoted name)";

like $o->fill(\ qq{<select name="foo">
			<option>
				bar
			</option>
		</select>}, \%q),
	$x,
	  	  "select an option (including many white spaces)";



is $o->fill(\ qq{<select name="foo"><option>bar</option></select>}, {foo => undef}),
	      qq{<select name="foo"><option>bar</option></select>},
	  	  "nothing with undef data";

is $o->fill(\ qq{<select name="foo"><option value="bar">ok</option></select>}, \%q),
	      qq{<select name="foo"><option value="bar" selected="selected">ok</option></select>},
	 	   "select an option with 'value=' attribute";

is $o->fill(\ qq{<select name="foo"><option value="bar">ok</option><option value="baz" selected="selected">ng</option></select>}, \%q),
	      qq{<select name="foo"><option value="bar" selected="selected">ok</option><option value="baz">ng</option></select>},
	    	"chenge the selected";

like $o->fill(\ qq{<SELECT NAME="foo"><OPTION>bar</OPTION></SELECT>}, \%q),
	$x,
	  	  "select an option (UPPER CASE)";

# select-one / select-multi

$output = $o->fill(\ qq{<select name="foo" multiple="multiple">
			<option value="bar">ok</option>
			<option value="baz" selected="selected">ok</option>
		</select>}, { foo => [qw(bar baz)] });

my(@options) = grep{ /option/ } split /\n/, $output;

like $options[0], qr/bar/;
like $options[0], qr/selected/, "bar is selected";

like $options[1], qr/baz/;
like $options[1], qr/selected/, "baz is selected";

#re-fill

my $s = q{<select name="foo"><option>bar</option></select>};
$output = $o->fill(\$s, { foo => 'bar' });

is $o->fill(\$output, { foo => 'bar' }), $output, "re-fill with the same data";
is $o->fill(\$output, { foo => 'baz' }), $s,      "re-fill to the original";
