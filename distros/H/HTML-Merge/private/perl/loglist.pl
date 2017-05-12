#!/usr/bin/perl
##################################################################
# loglist.pl - prints the loglist.html page with the             #
#              files that are in the log directory               #
# author : Eial Solodki                                          #
# All right reserved - Raz Information Systems Ltd.(c) 1999-2001 #
# date : 15/02/2001                                              #
# updated :                                                      #
##################################################################

use HTML::Merge::Development;
use CGI qw/:standard/;
use strict;

##################################################################

ReadConfig();

my %file_list;
my @dir_list;
my $filename;
my $logfile; 
my $counter = 1;
my $ctime; 
my $key;
my $value;
my $LIST_SIZE = param('log_list_size');
my $log_dir = param('log_dir');

my $rel = param('rel_path');
$rel .= "/"  if $rel;
my $alt = param('alt');
my $from = param('from');

my $base = "$ENV{'SCRIPT_NAME'}?$extra&log_list_size=$LIST_SIZE&log_dir=$log_dir&alt=$alt&from=$from";

my $token = "$ENV{'REMOTE_ADDR'}/";
$token = "" if ($alt eq 'view');

while(glob("$log_dir/$token$rel*"))
{
	$filename = $_; # just for being it clear
	$ctime = (stat($filename))[10]; # the time of creation of the file
									# in the stat array
    # the logfile is the clean filename,without the path									
	$logfile = substr($filename,rindex($filename,'/')+1);

	if (-d $filename) {
		push(@dir_list, $logfile);
		next;
	}

	$logfile =~ s/\.\w+?$// unless ($alt eq 'view');
	# hash table which the key is the creation time
	# and the value is the cleaned file name
#	$file_list{$ctime}=$logfile;
	$file_list{$logfile} = $ctime;
}

$counter = 0;

my $title = "Log List";
my $launch = "ShowMergeErrorLog";

if ($alt eq 'view') {
	if ($from eq 'view') {
		$title = "View source";
		$launch = "ShowMergeSource";
	} elsif ($from eq 'run') {
		$title = "Run template";
		$launch = "ShowMergeRun";
	}
}

print "Content-type: text/html\n\n"; 
print <<HTML;
<HTML>
<HEAD>
<TITLE>$title</TITLE>
<STYLE>.userData { BEHAVIOR: url(#default#userdata)	} </STYLE>
<STYLE TYPE="text/css">
<!--
	A:link {color:"#003399";}
	A:visited {color:"#800080";}
	A:hover {color:"#FF3300";}
-->
</STYLE>
</HEAD>
<BODY BGCOLOR="Silver">
<SCRIPT LANGUAGE="JavaScript">
<!--
///////////////////////////////////////////////////////////////////////
function ShowMergeSource(file)
{
	var dt = new Date();
	var myWin=open("viewsource.pl?$extra&template=" + file + "&from=$from", "MergeSourcePage", "top=0,screenY=0,left=0,screenX=0,width=720,height=550,status=no,scrollbars=yes,toolbar=no,menubar=no,copyhistory=no,resizable=yes");			
	myWin.focus();
}	
///////////////////////////////////////////////////////////////////////
function ShowMergeRun(file)
{
	var dt = new Date();
	var myWin=open("viewsource.pl?$extra&template=" + file + "&from=$from", "MergeRunPage", "top=0,screenY=0,left=0,screenX=0,width=500,height=250,status=no,scrollbars=auto,toolbar=no,menubar=no,copyhistory=no,resizable=yes");			
	myWin.focus();
}	
///////////////////////////////////////////////////////////////////////
function ShowMergeErrorLog(file)
{
	var dt = new Date();
	var myWin=open("viewlog.pl?$extra&log="+file+"&dt="+dt,"MergeErrorLogPage","top=20,screenY=20,left=250,screenX=250,width=450,height=500,status=no,scrollbars=yes,toolbar=no,menubar=no,copyhistory=no,resizable=yes");			
	myWin.focus();
}	

///////////////////////////////////////////////////////////////////////
//-->
</SCRIPT>
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

if ($rel) {
	my $prev = "/$rel"; # Make sure first token can be erased
	$prev =~ s|/.*?$||;
	$prev =~ s|^/||;
	print"<tr>";
	print"<td><font face='verdana,arial,helvetica' size=1>\n";
    	print "&nbsp;&nbsp;<B><A HREF=\"$base&rel_path=$prev\">[Back]</A></B>&nbsp;<br></td>\n";
 	print"</font></tr>\n";
	print"<tr><td colspan=3 height=3></td></tr>\n";
}

foreach (@dir_list) {
	print"<tr>";
	print"<td><font face='verdana,arial,helvetica' size=1>\n";
    	print "&nbsp;&nbsp;<B><A HREF=\"$base&rel_path=$rel$_\">$_/</A></B>&nbsp;<br></td>\n";
 	print"</font></tr>\n";
	print"<tr><td colspan=3 height=3></td></tr>\n";
}

my @keys = $alt eq 'view' ? sort keys %file_list : sort {$file_list{$b} <=> $file_list{$a}} keys %file_list;
for $key (@keys)
{
	last if ($LIST_SIZE && $counter++ >= $LIST_SIZE);
	print"<tr>";
	print"<td><font face='verdana,arial,helvetica' size=1>\n";
	my $file = join("/", grep /./, ($token, $rel,
		$alt eq 'view' ? $key : "$key.html"));
	$file =~ s|//+|/|;
    	print "&nbsp;&nbsp;<A HREF=javascript:$launch('$file')>$key</A>&nbsp;<br></td>\n";
 	print"</font></tr>\n";
	print"<tr><td colspan=3 height=3></td></tr>\n";
}
print"<tr><td colspan=3 height=10></td></tr>\n";
print"<tr><td colspan=3>
      <font id='HPFrameDLTab2' face='verdana,arial,helvetica' size='1' color='#336699'>
      <A HREF='javascript:opener.focus(); close()' title='Exit'><B>Close $title</B></A>
      </font> </td></tr>\n";
print"<tr><td colspan=3 height=7></tr>\n";
print"</table>\n";
print"</div>\n";
print"</td>\n";
print"</table>\n";
print end_html();
