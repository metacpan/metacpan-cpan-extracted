#!perl
use strict;
use warnings;

use HTML::FillInForm::Lite::Compat;

my $fif = HTML::FillInForm->new();

my $html = <<'EOD';
<input type="checkbox" name="hoge" value="on" />
<input type="checkbox" name="fuga" value="on" checked="checked" />

<input type="radio" name="foo" value="r1" checked="checked" />
<input type="radio" name="foo" value="r2" />
<input type="radio" name="foo" value="r3" />
EOD

print "Before:\n", $html, "\n";

print "After:\n", $fif->fill(\$html, {
	hoge => 'on',

	foo => 'r2',
});
