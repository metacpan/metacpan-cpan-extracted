# -*- Mode: Perl; -*-

use Test::More 'no_plan';
use strict;

use HTML::FillInForm;
 
my $html =<<"__HTML__";
<HTML>
<BODY>
<FORM action="test.cgi" method="POST">
<INPUT type="hidden" name="hidden" value="&gt;&quot;">
<INPUT type="text" name="text" value="&lt;&gt;&quot;&otilde;"><BR>
<INPUT type="radio" name="radio" value="&quot;&lt;&gt;">test<BR>
<INPUT type="checkbox" name="checkbox" value="&quot;&lt;&gt;">test<BR>
<INPUT type="checkbox" name="checkbox" value="&quot;&gt;&lt;&gt;">test<BR>
<SELECT name="select">
<OPTION value="&lt;&gt;">&lt;&gt;
<OPTION value="&gt;&gt;">&gt;&gt;
<OPTION value="&otilde;">&lt;&lt;
<OPTION>&gt;&gt;&gt;
</SELECT><BR>
<TEXTAREA name="textarea" rows="5">&lt;&gt;&quot;</TEXTAREA><P>
<INPUT type="submit" value=" OK ">
</FORM>
</BODY>
</HTML>
__HTML__

my %fdat = ();

my $output = HTML::FillInForm->fill( \$html, \%fdat);

# FIF changes order of HTML attributes, so split strings and sort
my $strings_output = join("\n", sort split(/[\s><]+/, lc($output)));
my $strings_html = join("\n", sort split(/[\s><]+/, lc($html)));

is($strings_output,$strings_html);

