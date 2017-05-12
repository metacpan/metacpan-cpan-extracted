#!/usr/local/bin/perl -T
#
#   Prog Name: wx.cgi
# Description: New wx.cgi with WeatherNOAA v4
#      Author: Mark Solomon <msolomon@seva.net>
#        Date: 01/19/99
#    Revision: $Id: wx.cgi,v 1.2 1999/02/18 20:12:21 msolomon Exp $
#

use Geo::WeatherNOAA;

use CGI;

BEGIN { $ENV{'PATH'} 	= '';
		$ENV{'ENV'}		= '';
		$ENV{'CDPATH'}	= '';
}


$VERSION = do { my @r = (q$Revision: 1.2 $ =~ /\d+/g); sprintf "%d."."%02d" x $#r, @r };

$q = new CGI;

# Get city state from browser
$Tcity 		= $q->param('city') 	|| 'newport news';
$Tstate		= $q->param('state')	|| 'va';
$Tbgcolor	= $q->param('bgcolor')	|| 'ffffff';

# Untaint
$city = ( $Tcity =~ /(^[\w\s]+)/ )[0];
$state = ( $Tstate =~ /^(\w\w)/ )[0];
$bgcolor = ( $Tbgcolor =~ /^(\w{6})/ )[0];

# Make constraint table with data
$out = $q->header . "\n";
$out .= $q->start_html(-title=>"Mark's Local Weather Page for $city, $state",-bgcolor=>"#$bgcolor") . "\n";
$out .= "<CENTER>\n";
$out .= "<HR NOSHADE WIDTH=\"600\">\n";
$out .= "<TABLE CELLPADDING=0 CELLSPACING=0 BORDER=0 WIDTH=600><TR><TD>\n";
$out .= "<IMG SRC=/icons/blank.gif WIDTH=2 HEIGHT=1 ALT=\"\">\n";
$out .= "<FONT FACE=\"Helvetica, Lucida, Ariel\"> Weather for $city, $state" .
		"</FONT>\n";
# Get wx data (dont save it)
$out .= make_noaa_table($city,$state,'','get');

# End table
$out .= "</TD></TR></TABLE>\n";
$out .= "<HR NOSHADE WIDTH=\"600\">\n";

# Print input form for new city, state
$out .=<<END1;
<FONT SIZE="2" FACE="Helvetica, Lucida, Ariel">
wx.cgi v$VERSION
<FORM METHOD="GET">
	New City <INPUT NAME="city" SIZE=20 VALUE="$city">
	State <INPUT SIZE=3 MAXLENGTH=2 NAME="state" TYPE=text VALUE="$state">
	<INPUT TYPE=SUBMIT VALUE="Get Wx">
</FORM>
</FONT>
END1

$out .= "</CENTER>\n";

# End html
$out .= $q->end_html;

# Flush out buffer
print $out;
