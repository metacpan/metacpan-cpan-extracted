#!/usr/bin/perl

use CGI qw/:standard/;
use Cwd;
use strict;

my $field = param('field');
my $dir = param('dir') || "/";

my $base = "$ENV{'SCRIPT_NAME'}?field=$field";

my $title = $dir;

if (length($title) > 20) {
	my @tokens = split(m|/|, $dir);
	$title = join("/", @tokens[0 .. 2], "...", @tokens[-2 .. -1]);
}

print "Content-type: text/html\n\n", start_html(-title => "Browsing $dir", -bgcolor => 'Silver');

print <<HTML;
<FORM>
<div id="HPFrameDLContent" style="width:100%;border-bottom:#ffffff 1px solid;border-left:#ffffff 1px solid;border-right:#ffffff 1px solid;">
<table class="HPFrameTab" width="100%" border="0" cellpadding="0" cellspacing="0">
<tr id="HPFrameDLTab" valign="middle" bgcolor="#CCCCCC">
<td align="left" width="100%" height="10">
<font id="HPFrameDLTab2" face="verdana,arial,helvetica" size="1" color="#336699">
<CENTER><B>$title</B></CENTER>
</font>
</td>
</tr>
HTML

my $curr = &getcwd;
chdir $dir;
chdir "..";
my $prev = &getcwd;
chdir $curr;

if ($prev ne $dir) {
        print"<tr>";
        print"<td><font face='verdana,arial,helvetica' size=1>\n";
        print "&nbsp;&nbsp;<A HREF=\"$base&dir=$prev\">..</A>&nbsp;<br></td>\n";
        print"</font></tr>\n";
        print"<tr><td colspan=3 height=3></td></tr>\n";
}

foreach (glob("$dir/*")) {
	next if ($_ =~ /^\./);
	next unless (-d $_);
	s|//+|/|g;
	my $item = $_;
	$item =~ s|^.*/||;

        print"<tr>";
        print"<td><font face='verdana,arial,helvetica' size=1>\n";
        print "&nbsp;&nbsp;<A HREF=\"$base&dir=$_\">$item</A>&nbsp;<br></td>\n";
        print"</font></tr>\n";
        print"<tr><td colspan=3 height=3></td></tr>\n";
}

print <<HTML;

</TABLE>
</DIV><BR>
<CENTER>
<INPUT TYPE=BUTTON onClick="opener.CallBack('$field', '$dir'); window.close();"
	VALUE="Ok">
<INPUT TYPE=BUTTON onClick="window.close();" VALUE="Cancel">
</CENTER>
</FORM>
</HTML>

HTML
