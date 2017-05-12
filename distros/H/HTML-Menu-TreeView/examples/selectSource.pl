#!/usr/bin/perl -w
use showsource;
print "Content-Type: text/html$/$/" . '
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">
<html>
<head>
<title>OO Source</title>
</head>
<body><table align="left" border="0" cellpadding="0" cellspacing="0" summary="Table"><tr><td>
';
&showSource("./select.pl");
print '</td></tr></table></body></html>';

