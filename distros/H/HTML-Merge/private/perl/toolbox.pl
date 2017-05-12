#!/usr/bin/perl

use CGI qw/:standard/;
use HTML::Merge::Development;
use strict;

ReadConfig();

print "Content-type: text/html\n\n";

my $winstuff = ",status=no,scrollbars=yes,toolbar=no,menubar=no,copyhistory=no,resizable=no";
print <<HTML;

<HTML>
<HEAD>
	<TITLE>ToolBox</TITLE>
<META HTTP-EQUIV="Content-Type" CONTENT="text/html;charset=windows-1255">
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
// Global variabels
var merge_path = '$HTML::Merge::Ini::MERGE_PATH';
var merge_absolute_path = '$merge_absolute_path';
var log_dir = '$merge_absolute_path/$HTML::Merge::Ini::MERGE_ERROR_LOG_PATH';
var src_dir = '$HTML::Merge::Ini::TEMPLATE_PATH';
var log_list_size = '$HTML::Merge::Ini::LOG_LIST_SIZE';
var merge_script = '$HTML::Merge::Ini::MERGE_SCRIPT';

//////////////////////////////////////////////////////////////////////
function ShowLogsList()
{
	var dt = new Date() - 1;
	var myWin=open("loglist.pl?$extra&log_dir=" + log_dir + "&log_list_size=" + log_list_size + "&dt=" + dt, "LogList", "screenY=90,top=90,screenX=90,left=90,width=150,height=245$winstuff");
	myWin.focus();
}
//////////////////////////////////////////////////////////////////////
function ShowSourceList(from)
{
	var dt = new Date() - 1;
	var myWin=open("loglist.pl?$extra&log_dir=" + src_dir + "&log_list_size=0&from=" + from + "&dt=" + dt + "&alt=view", "SourceList", "screenY=90,top=90,screenX=90,left=90,width=150,height=245$winstuff");
	myWin.focus();
}

//////////////////////////////////////////////////////////////////////
function iniHtml()
{
	var dt = new Date() - 1;
	var myWin = open("pre_web_ini.pl?$extra&dt=" + dt ,"iniHtml","screenY=100,top=100,screenX=90,left=90,width=400,height=400$winstuff");
	myWin.focus();
}
//////////////////////////////////////////////////////////////////////
function EraseLogs()
{
	var myWin=open("dellogs.pl?$extra",
		"dellogs",
		"screenY=0,stop=0,screenX=0,left=0,width=60,height=40$winstuff");
	focus();
}
//////////////////////////////////////////////////////////////////////
function EraseCache()
{
	var myWin=open("delcache.pl?$extra",
		"delcache",
		"screenY=0,top=0,screenX=0,left=0,width=60,height=40$winstuff");
	focus();
}
//////////////////////////////////////////////////////////////////////
function WebToWeb()
{
	alert("Under Construction");
}
//////////////////////////////////////////////////////////////////////
function Exit()
{
	window.close();
}
//////////////////////////////////////////////////////////////////////
function Backend()
{
	var dt = new Date() - 1;
	var myWin = open("menu.pl?$extra&dt=" + dt, "backend","screenY=100,top=100,screenX=90,left=90,width=400,height=400$winstuff");
	myWin.focus();
}
//////////////////////////////////////////////////////////////////////
function Help()
{
	var myWin = open("help.pl?$extra", "help", "screenY=100,top=100,screenX=90,left=90,width=600,height=480$winstuff");
	myWin.focus();
}
//////////////////////////////////////////////////////////////////////
function ChangePass()
{
	var dt = new Date() - 1;
	var myWin = open("chpass.pl?$extra&dt=" + dt, "backend","screenY=100,top=100,screenX=90,left=90,width=500,height=300$winstuff");
	myWin.focus();
}
//////////////////////////////////////////////////////////////////////
function Freeze()
{
	var dt = new Date() - 1;
	var myWin = open("freeze.pl?$extra&dt=" + dt, "backend","screenY=100,top=100,screenX=90,left=90,width=50,height=30$winstuff");
	myWin.focus();
}
//////////////////////////////////////////////////////////////////////
function Defreeze()
{
	var dt = new Date() - 1;
	var myWin = open("defreeze.pl?$extra&dt=" + dt, "backend","screenY=100,top=100,screenX=90,left=90,width=50,height=30$winstuff");
	myWin.focus();
}


//-->
</SCRIPT>

<FORM METHOD="GET" NAME="ToolBox">
<table class="HPFrameTab" width="100%" border="0" cellpadding="0" cellspacing="0" >
<tr id="HPFrameDLTab" valign="middle" bgcolor="#CCCCCC">
<td></td>
<td align="left" width="100%" height="10">
<font id="HPFrameDLTab2" face="verdana,arial,helvetica" size="1" color="#336699">
<CENTER><B>ToolBox</B></CENTER>
</font>
</td>
<td></td>
</tr>
</table>
<div id="HPFrameDLContent" style="width:100%;border-bottom:#ffffff 1px solid;border-left:#ffffff 1px solid;border-right:#ffffff 1px solid;">
<table cellspacing="0" cellpadding="0">
HTML

my $data = <<DATA;
ShowLogsList()|Merge Logs|The logs of the last pages viewed. (only if Development set to True)
ShowSourceList('view')|Template source|View source code of templates.
ShowSourceList('run')|Run Template|Run templates.
iniHtml()|Merge configuration|A page which generates the configuration file.
Backend()|Merge security backend|Configure permissions for using the application.
WebToWeb()|Web Development|This feature is under construction.
Help()|Online Help|Documentation about Merge tags.
EraseLogs()|Erase Logs|Erase the log files.
EraseCache()|Erase Cache|Erase the cached precompiled pages.
ChangePass()|Change Password|Chaneg the toolbox password
Freeze()|Freeze Compiled Templates|Compile all templates and freeze the compiled version
Defreeze()|Defreeze Compiled Templates|Remove all templates from the precompiled directory
DATA

foreach (split(/\n/, $data)) {
	chop;
	my ($js, $title, $tip) = split(/\|/);
	print <<HTML;
<tr><td colspan="3" height="5"></tr>
<tr><td valign="TOP"></td>
<td width="3px"></td>
<td><font face="verdana,arial,helvetica" size="1">
<li><A TITLE="$tip" HREF="javascript:$js">$title</A><br>
</font>
</td>
HTML
}
print <<HTML;
<tr VALIGN="TOP">
<td colspan="2">
<td nowrap=""><font face="verdana,arial,helvetica" size="1">
<br>
<A HREF="javascript:Exit()" title="Exit"><B>Close ToolBox</B></A>
</font>
</td>
</tr>
<tr><td colspan="3" height="5"></tr>
</table>
</div>
</td></tr>
</table>
</FORM>
</BODY>
</HTML>
HTML
