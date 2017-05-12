#!/usr/bin/perl

use HTML::Merge::Development;
use CGI qw/:standard/;

ReadConfig();

print "Content-type: text/html\n\n";

my $r = param('r');

print <<HTML;
<HTML>
<HEAD>
<TITLE>Change password for user $HTML::Merge::Ini::ROOT_USER</TITLE>
</HEAD>
<BODY>
Change password for user $HTML::Merge::Ini::ROOT_USER:<BR>
<FORM ACTION="web_ini.pl" METHOD=POST onSubmit="return verify()">
<CENTER>
HTML

if ($r) {
	print h4("Problem: $r");
}
&HTML::Merge::Development::Transfer;

print <<HTML;
<TABLE>
<TR>
<TD>Current password:</TD>
<TD><INPUT TYPE=PASSWORD NAME="CURRENT_PASSWORD"></TD>
</TR>
<TR>
<TD>New password:</TD>
<TD><INPUT TYPE=PASSWORD NAME="ROOT_PASSWORD"></TD>
</TR>
<TR>
<TD>Retype password:</TD>
<TD><INPUT TYPE=PASSWORD NAME="DOUBLE_PASSWORD"></TD>
</TR>
</TABLE>
<INPUT TYPE=SUBMIT VALUE="Change">
<INPUT TYPE=BUTTON VALUE="Cancel">
</CENTER>
</FORM>
</BODY>
</HTML>
HTML
