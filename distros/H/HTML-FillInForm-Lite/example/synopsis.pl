#!perl -w
# $ perl -Ilib example/synopsis.pl "foo=the value of foo" bar=a

use strict;

use HTML::FillInForm::Lite;
use CGI;

my $html = <<'EOD';

<form>
	<input type="text" name="foo" value="" />
	<input type="checkbox" name="bar" value="a" />
	<input type="checkbox" name="bar" value="b" />
</form>
EOD

print 'BEFORE:', $html;

my $q = CGI->new();
$html = HTML::FillInForm::Lite->fill(\$html, $q);

print 'AFTER:', $html;

