#!perl

use strict;
use warnings;

use Test::Requires qw(CGI);
use FindBin qw($Bin);
use Fatal qw(open close);

use Test::More tests => 95;

BEGIN{ use_ok('HTML::FillInForm::Lite') }

my $t = "$Bin/test.html";

my %q = (
	foo => 'bar',

	a => ['A', 'B', 'C'],

	s => 'A',

	b => q{"bar"},
	c => q{<bar>},
	d => q{'bar'},

	default => ['on'],
);

my $x     = qr{value="bar"};
my $x_s   = qr{value="A"};
my $x_b   = qr{value="&quot;bar&quot;"};
my $x_c   = qr{value="&lt;bar&gt;"};
my $x_d   = qr{value="'bar'"};

my $unchanged = qr{value="null"};
my $empty     = qr{value=""};

my $checked  = qr{checked="checked"};

sub my_param{
	my($key) = @_;
	return $q{$key};
}

use CGI;
my $q = CGI->new(\%q);


my $s = q{<input name="foo" value="null" />};

my $o = HTML::FillInForm::Lite->new();

isa_ok $o, 'HTML::FillInForm::Lite';

like $o->fill(\$s,  $q),  $x, "fill in scalar ref";
like $o->fill([$s], $q),  $x, "in array ref";
like $o->fill(['', $s], $q), $x, "in array ref(2)";
like $o->fill($t, $q), $x, "in file";

like $o->fill(do{ open my($fh), $t;  *$fh     }, $q), $x, "in filehandle";
like $o->fill(do{ open my($fh), $t; \*$fh     }, $q), $x, "in filehandle ref";
like $o->fill(do{ open my($fh), $t;  *$fh{IO} }, $q), $x, "in IO object";

use Tie::Handle;
use IO::Handle;

SKIP:{
	skip "on 5.6.x", 1 if($] < 5.008);

	like $o->fill(do{
		my $fh = IO::Handle->new();
		tie *$fh, 'Tie::StdHandle', $t or die "Cannot open '$t': $!";
		*$fh;
	}, $q), $x, 'in tied filehandle (*FH)';
}
like $o->fill(do{
	my $fh = IO::Handle->new();
	tie *$fh, 'Tie::StdHandle', $t or die "Cannot open '$t': $!";
	$fh;
}, $q), $x, 'in tied filehandle (\*FH)';


like $o->fill(\$s,  \%q),        $x, "with hash";
like $o->fill(\$s, [\%q]),       $x, "with array";
like $o->fill(\$s, [ {}, \%q ]), $x, "with array";
like $o->fill(\$s, \&my_param),  $x, "with subroutine";
like $o->fill(\$s, [ {}, \&my_param]), $x, "with complex array";

like(HTML::FillInForm::Lite->fill(\$s, \%q), $x, "fill() as class methods");

like $o->fill(\$s, { foo => undef }),
	     $unchanged, "nothing with undef data";
like $o->fill(\$s, { }),
	     $unchanged, "with empty data";

like $o->fill(\$s, { foo => ''}), $empty, "clear data";

like $o->fill(\ q{<input type="text" name="foo" />}, $q), $x, "add value attribute";

my $y = q{<input type="hidden" name="foo" value="baz" />};
like $o->fill(\$y, $q), $x, "hidden";
like $o->fill(\$y, $q), qr/type="hidden"/, "remains a hidden";

# ignore_type

$y = q{<input type="submit" name="foo" value="null" />};
is $o->fill(\$y, $q), $y, "ignore submit";

$y = q{<input type="reset" name="foo" value="xxx" />};
is $o->fill(\$y, $q), $y, "ignore reset";

$y = q{<input type="button" name="foo" value="xxx" />};
is $o->fill(\$y, $q), $y, "ignore button";

$y = q{<input type="image" name="foo" value="xxx" />};
is $o->fill(\$y, $q), $y, "ignore image";

$y = q{<input type="file" name="foo" value="xxx" />};
is $o->fill(\$y, $q), $y, "ignore file";

# doesn't ignore

$y = q{<input type="SUBMIT" name="foo" value="xxx" />};
like $o->fill(\$y, $q), $x, "doesn't ignore SUBMIT";



$y = q{<input type="text" value="" />};
is $o->fill(\$y, $q), $y, "ignore null named";

$y = q{<input type="text" value="" name="" />};
is $o->fill(\$y, $q), $y, "ignore empty name";


# Ignore options

$y = q{<input type="password" name="foo" value="null" />};
like $o->fill(\$y, $q),                     $unchanged, "don't fill in password by default";
like $o->fill(\$y, $q, fill_password => 1), $x,         "fill_password => 1";
like $o->fill(\$y, $q, fill_password => 0), $unchanged, "fill_password => 0";
like $o->fill(\$y, $q),                     $unchanged, "options effects only the call";

like $o->fill(\$s, $q, ignore_fields  => ['foo']),  $unchanged, "ignore_fields";

# new/fill with options

like(HTML::FillInForm::Lite->new(ignore_fields => ['foo'])
		->fill(\$s, $q, ignore_fields => []),
		$unchanged, "new() and fill() with ignore_fields");


like(HTML::FillInForm::Lite->new(ignore_fields => [])
		->fill(\$s, $q, ignore_fields => ['foo']),
		$unchanged, "new() and fill() with ignore_fields");

# multi-fields

my $mult = <<'EOT';
<input name="foo"/>
<input name="foo"/>
EOT

like(HTML::FillInForm::Lite->fill(\$mult, { foo => [qw(a b)] }),
	qr{ value="a" .* value="b" }xms, "multi-fields");

$mult = <<'EOT';
<input name="foo" value="x"/>
<input name="foo" value="x"/>
<input name="foo" value="x"/>
<input name="foo" value="x"/>
EOT

like(HTML::FillInForm::Lite->fill(\$mult, { foo => [qw(a b)] }),
	qr{ value="a" .* value="b" .* value="x" .* value="x"}xms, "multi-fields");

# chexbox

like $o->fill(\ q{<input type="checkbox" name="foo" value="bar" />}, $q),
	      $checked, "checkbox on";
like $o->fill(\ q{<input type="checkbox" name="foo" value="bar" checked="checked" />}, $q),
	      $checked, "checkbox on";
like $o->fill(\ q{<input type="checkbox" name="foo" value="bar" checked='checked'/>}, $q),
	      qr/checked/, "checkbox on";



unlike $o->fill(\ q{<input type="checkbox" name="foo" value="xxx" checked="checked" />}, $q),
	      $checked, "checkbox off";
unlike $o->fill(\ q{<input type="checkbox" name="foo" value="xxx" checked='checked' />}, $q),
	      $checked, "checkbox off";

unlike $o->fill(\ q{<input type="checkbox" name="foo" value="xxx" />}, $q),
	      $checked, "checkbox off";

# multiple values

like $o->fill(\ q{<input name="a" value="A" type="checkbox" />}, $q),
	$checked, "on (multiple values)";

like $o->fill(\ q{<input name="a" type="checkbox" value="B" checked="checked" />}, $q),
	$checked, "on (multiple values)";


my $xx = $o->fill(\ <<'EOT', $q);
<input name="a" value="A" type="checkbox" />
<input name="a" value="B" type="checkbox" />
<input name="a" value="C" type="checkbox" />
<input name="a" value="D" type="checkbox" />
EOT

like   $xx, qr/value="A" [^>]* $checked/oxms, "multi-checks(A)";
like   $xx, qr/value="B" [^>]* $checked/oxms, "multi-checks(B)";
like   $xx, qr/value="C" [^>]* $checked/oxms, "multi-checks(C)";
unlike $xx, qr/value="D" [^>]* $checked/oxms, "multi-checks(D)";

unlike $o->fill(\ q{<input type="checkbox" name="a" value="Z" checked="checked" />}, $q),
	$checked, "off (multiple values)";

unlike $o->fill(\ q{<input type="checkbox" value="a" />}, $q),
	$checked, "ignore undefined name";

unlike $o->fill(\ q{<input type="checkbox" name="a" />}, $q),
	$checked, "ignore undefined value";

like $o->fill(\ q{<input type="checkbox" name="zero" value="0" />}, { zero => 0 }),
    $checked, "zero value in checkbox";

# radio

like $o->fill(\ q{<input type="radio" name="s" value="A" />}, $q),
	$checked, "select radio button";
unlike $o->fill(\ q{<input type="radio" name="s" value="B" checked="checked" />}, $q),
	$checked, "unselect radio button";
like $o->fill(\ q{<input type="radio" name="s" value="A" checked="checked" />}, $q),
	$checked, "remains checked";
unlike $o->fill(\ q{<input type="radio" name="s" value="B" />}, $q),
	$checked, "remains unchecked";

unlike $o->fill(\ q{<input type="radio" name="s" value="Z" checked='checked'/>}, $q),
	qr/checked/, "unchecked";
unlike $o->fill(\ q{<input type="radio" name="s" value="Z" checked=checked/>}, $q),
	qr/checked/, "unchecked";

unlike $o->fill(\ q{<input type="radio" value="A" />}, $q),
	$checked, "ignore undefined name";
unlike $o->fill(\ q{<input type="radio" name="s" />}, $q),
	$checked, "ignore undefined value";

like $o->fill(\ q{<input type="radio" name="default" />}, $q),
	$checked, "default radio button to on";

like $o->fill(\ q{<input type="radio" name="zero" value="0" />}, { zero => "0" }),
    $checked, "zero value in radio";

# HTML escape

like $o->fill(\ q{<input type="text" value="" name="b" />}, $q),
	$x_b, "HTML escape";
like $o->fill(\ q{<input type="text" value="" name="c" />}, $q),
	$x_c, "HTML escape";


like $o->fill(\ q{<input type="text" value="" name="c" />}, $q, escape => undef),
	$x_c, "escape => undef (default)";


like $o->fill(\ q{<input type="text" value="" name="c" />}, $q, escape => 1),
	$x_c, "escape => 1";

like $o->fill(\ q{<input type="text" value="" name="c" />}, $q, escape => 0),
	qr/value="<bar>"/, "escape => 0";

like $o->fill(\ q{<input type="text" value="" name="c" />}, $q, escape => sub{ 'XXX' }),
	qr/value="XXX"/, "escape => sub{ ... }";


# Legacy HTML tests

$s = q{<INPUT name="foo" />};
like $o->fill(\$s, $q),$x , "Legacy HTML (capital tagname)";

$s = q{<input NAME="foo" />};
like $o->fill(\$s, $q),$x , "Legacy HTML (capital attrname)";

$s = q{<input name="foo">};
like $o->fill(\$s, $q), $x, "Legacy HTML (unclosed input tag)";

$s = q{<input name=foo />};
like $o->fill(\$s, $q), $x, "Legacy HTML (unquoted attr)";

$s = q{<input name=foo>};
like $o->fill(\$s, $q), $x, "Legacy HTML (unclosed input tag and unquoted attr)";

$s = q{<input name=foo/>};
like $o->fill(\$s, $q), $x, "Invalid HTML (closed input tag and unquoted attr)";


$s = q{<INPUT NAME=foo>};
like $o->fill(\$s, $q), $x, "Legacy HTML (capital tag and unclosed, unquoted, capital attr)";

# Strange HTML

$s = q{<input name="foo" value="
there are new lines
">};
like $o->fill(\$s, $q), $x, "new lines in value";

$s = q{<input name="foo" value="\0 ascii nul \0">};
like $o->fill(\$s, $q), $x, "NUL in value";

$s = q{<input
		name="foo"
		value="null"
>};
like $o->fill(\$s, $q), $x, "new lines between attributes";


# Invalid input fields

$y = q{<a name="foo" value="" />};
is $o->fill(\$y, $q), $y, "no inputable";

$y = q{<input name="foo"value="" />};
is $o->fill(\$y, $q), $y, "no space between attributes";

$y = q{<input +Hello+ name="foo" value="" />};
is $o->fill(\$y, $q), $y, "rubbish in tag";

$y = q{<input name="foo" value=""};
is $o->fill(\$y, $q), $y, "unclosed tag";

$y = q{input name="foo" value=""/>};
is $o->fill(\$y, $q), $y, "unopened tag";

$y = q{<input name="foo' />};
is $o->fill(\$y, $q), $y, "unmatched quote (1)";

$y = q{<input name='foo" />};
is $o->fill(\$y, $q), $y, "unmatched quote (2)";


$y = q{name="foo" value="null"};
is $o->fill(\$y, $q), $y, "no HTML";

# empty source

is $o->fill(\'', {}), '', "empty string";
is $o->fill([],  {}), '', "empty array";

# re-fill

my $output = $o->fill(\$s, $q);
for(1 .. 2){
	is $o->fill(\$output, $q), $output, "re-fill($_)";
}

is $o->fill(\$s, $q, disable_fields => ['foo']), $output,
	"disable_fields raises no error";

#END
