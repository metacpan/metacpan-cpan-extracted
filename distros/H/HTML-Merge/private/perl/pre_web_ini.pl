#!/usr/bin/perl
##################################################################
# web_ini.pl - gets the data to update in the ini.pm             #
#              from the Merge Configuration Web page             #
# author : Eial Solodki                                          #
# All right reserved - Raz Information Systems Ltd.(c) 1999-2001 #
# date : 07/05/2001                                              #
# updated :                                                      #
##################################################################

use HTML::Merge::Engine qw(:unconfig);
use HTML::Merge::Development;

use CGI qw/:standard/;
use strict qw(vars subs);
use vars qw($tab);

ReadConfig();

##################################################################

my $date = localtime();
my $value;
	
sub GetParam {
	my $field = shift;
	return $HTML::Merge::Ini::DB_PASSWORD if ($field eq 'DB_PASSWORD');
	
	my $candidate = join(",", grep /./, param($field));
	return $candidate if (param($field)); # $candidate is defined anyways
	${"HTML::Merge::Ini::$field"};
}

$HTML::Merge::Ini::DB_PASSWORD = param('DB_PASSWORD');

$HTML::Merge::Ini::DB_PASSWORD 
	= HTML::Merge::Engine::Convert($HTML::Merge::Ini::DB_PASSWORD2)
	unless defined($HTML::Merge::Ini::DB_PASSWORD);

$HTML::Merge::Ini::DB_PASSWORD 
	= $HTML::Merge::Ini::DB_PASSWORD 
	unless defined($HTML::Merge::Ini::DB_PASSWORD);

print "Content-type: text/html\n\n";

my @tokens = split(/\//, $file);

if (@tokens > 5) {
	@tokens = ('...' , @tokens[-4 .. -1]);
}
my $asif = join("/", @tokens);

print <<HTML;
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 3.2 Final//EN">
<HTML>
<HEAD>
<TITLE>Configuration: $asif</TITLE>
<META HTTP-EQUIV="Content-Type" CONTENT="text/html;charset=windows-1255">
<STYLE TYPE="text/css">
<!--
	.bText
	{
		font-size : 9pt;
		font-weight : bold;
		color : #000000;
		font-family : Arial;	
		text-decoration : none;
	}
	
	.sText
	{
		font-size : 9pt;
		font-weight : normal;
		color : #000000;
		font-family : Arial (hebrew);	
		text-decoration : none;
}
-->
</STYLE>
</HEAD>

<BODY BGCOLOR="Silver">
<FORM action="web_ini.pl" method="GET" target="_self" name="iniForm">

HTML

print <<HTML;
<table class="HPFrameTab" width="100%" border="0" cellpadding="0" cellspacing="0">
<tr id="HPFrameDLTab" valign="middle" bgcolor="#CCCCCC">
<td></td>
<td align="left" width="100%" height="10">
<font id="HPFrameDLTab2" face="verdana,arial,helvetica" size="1" color="#336699">
<BIG><CENTER><B>Merge Configuration Web page</B></CENTER></BIG>
</font>
</td>
</tr>
</table>
<BR>
<div id="HPFrameDLContent" style="width:100%;border-bottom:#ffffff 1px solid;border-left:#ffffff 1px solid;border-right:#ffffff 1px solid;">
<SCRIPT>
<!--

var description;
var checkon;
var save;

function SetSafety(name, desc) {
	checkon = name;
	description = desc;
	save = document.iniForm[name].value;
}

function WarnSafety(name) {
	var response = true;
	var newval = document.iniForm[name].value;
	if (name == checkon && newval != save) {
		var what = confirm("Changing the value of '"
			+ description + "' from '" + save + "' to '"
			+ newval + "' may make the backend cease working. " +
			"Proceed?");
		if (!what) {
			document.iniForm[name].value = save;
			response = false;
		}
	}
	description = "";
	checkon = "*";
	return response;
}

function Browse(field) {
	var win = open("navi.pl?field=" + field + "&dir=" + 
		document.iniForm[field].value, 'browse',
		'width=200,height=400,tatus=no,scrollbars=yes,toolbar=no,menubar=no,copyhistory=no,resizable=no');
	win.focus();
}

function CallBack(field, value) {
	document.iniForm[field].value = value;
	if (field == checkon) WarnSafety(field);
	document.iniForm[field].focus();
}

var saveChars = new Object;

function Put(layer, text) {
	if (document.all) {
		document.all[layer].innerHTML = text;
	}
	return;
	if (document.layers) {
		var obj = document.layers[layer].document;
		obj.open();
		obj.writeln(text);
		obj.close();
	}
}

function Rewrite(layer) {
	var text = document.iniForm[layer].value;
	if (saveChars[layer] == text) return;
	saveChars[layer] = text;
	var s = "<B><FONT SIZE=4>" + text + "</FONT></B>";
	Put("big_" + layer, s);
}

function CharPress(layer, e) {
	var scan = e.keyCode;
	if (scan >= 32 && scan < 255 && scan != 127) {
		document.iniForm[layer].value = String.fromCharCode(scan);
		Rewrite(layer);
	}
}

// -->
</SCRIPT>
<TABLE BORDER=0 WIDTH=100% ALIGN="LEFT" CELLSPACING=0 cellpadding="0">
HTML

open(I, "input.frm");
while (<I>) {
	chop;
	my ($desc, $name, $type, $extra) = split(/\|/);
	my $fun = "fun" . uc($type);
	next unless (UNIVERSAL::can(__PACKAGE__, $fun));
	my $val = GetParam($name);
	&$fun($desc, $name, $val, $extra);

}

foreach (qw(MERGE_SCRIPT DB_PASSWORD2)) {
	print "<INPUT TYPE=\"HIDDEN\" NAME=\"$_\" VALUE=\"${qq!HTML::Merge::Ini::$_!}\">\n";
}

foreach (qw(merge_script merge_absolute_path)) {
	print "<INPUT TYPE=\"HIDDEN\" NAME=\"$_\" VALUE=\"" . param($_) . "\">\n";
}

print <<HTML;
<SCRIPT>
<!--
	function SendTemp() {
		document.iniForm.action = '$ENV{"SCRIPT_NAME"}';
		document.iniForm.submit();
	}
// -->
</SCRIPT>
<TR>
        <TD ALIGN="LEFT" COLSPAN=8 HEIGHT=10></TD>
</TR>
<TR>
        <TD ALIGN="LEFT"></TD>
	<TD ALIGN="CENTER" COLSPAN=2>
		<TABLE BORDER=0 CELLPADDING=0 CELLSPACING=0 WIDTH=100%>
			<TR>
        <TD ALIGN="CENTER"><input type="Submit" value="Save"></TD>
        <TD ALIGN="CENTER"><input type="Button" value="Close" onClick="opener.focus(); window.close()"></TD>
        <TD ALIGN="CENTER"><input type="Button" value="Revert" onClick="if (confirm('Do you want to revert to factory settings?')) location='restore.pl?$extra';"></TD>
			</TR>
		</TABLE>
	</TD>
        <TD ALIGN="LEFT"></TD>
</TR>
<TR>
        <TD ALIGN="LEFT" COLSPAN=8 HEIGHT=5></TD>
</TR>
</TABLE>
</FORM>
</BODY>
</HTML>
HTML

sub funS {
	my ($desc) = @_;
	print <<HTML;
<tr id="HPFrameDLTab" valign="middle" bgcolor="#CCCCCC">
<td></td>
<td align="left" width="100%" height="10" colspan=2>
<font id="HPFrameDLTab2" face="verdana,arial,helvetica" size="1" color="#336699">
<BIG><CENTER><B>$desc</B></CENTER></BIG>
</font>
</td>
<td></td>
</tr>
HTML
}

sub funT {
	my ($desc, $name, $val, $opts) = @_;
	$tab++;
	if ($opts =~ /Z/i) {
		$val = "" unless $val;
	}
	print <<HTML;
<tr>
<td></td>
<td><div class="bText">$desc</div></td>
<td><div class="sText"><INPUT NAME="$name" VALUE="$val" SIZE=25 MAXLENGTH=100 TABINDEX=$tab></div></td>
<td></td>
</tr>
HTML
}

sub funO {
	my ($desc, $name, $val) = @_;
	$tab++;
	print <<HTML;
<tr>
<td></td>
<td><div class="bText">$desc</div></td>
<td><span class="sText"><INPUT NAME="$name" VALUE="$val" SIZE=1 MAXLENGTH=1 TABINDEX=$tab onChange="Rewrite('$name');" onKeyPress="CharPress('$name', event);"></span>
<span id="big_$name"></span>
<SCRIPT>
<!--
Rewrite('$name');
// -->
</SCRIPT>
</td>
<td></td>
</tr>
HTML
}


sub funH {
	my ($desc, $name, $val) = @_;
}


sub funP {
	my ($desc, $name, $val) = @_;
	$tab++;
	print <<HTML;
<tr>
<td></td>
<td><div class="bText">$desc</div></td>
<td><div class="sText"><INPUT TYPE=PASSWORD NAME="$name" VALUE="$val" SIZE=25 MAXLENGTH=100 TABINDEX=$tab></div></td>
<td></td>
</tr>
HTML
}


sub funB {
	my ($desc, $name, $val) = @_;
	my ($on, $off) = ('', ' CHECKED');
	($off, $on) = ($on, $off) if $val;
	my $tab1 = ++$tab;
	my $tab2 = ++$tab;
	print <<HTML;
<tr>
<td></td>
<td><div class="bText">$desc</div></td>
<td><div class="sText">
<INPUT NAME="$name" TYPE=RADIO VALUE="0"$off> No
<INPUT NAME="$name" TYPE=RADIO VALUE="1"$on> Yes
</div></td>
<td></td>
</tr>
HTML
}

sub funC {
	my ($desc, $name, $val, $opts) = @_;
	my %hash;
	foreach (split(/,\s*/, $val)) {
		$hash{$_}++;
	}
        print <<HTML;
<tr>
<td></td>
<td><div class="bText">$desc</div></td>
<td><div class="sText">
HTML
        foreach(split(/,\s*/, $opts)) {
                $tab++;
                my $it = ucfirst(lc($_));
                my $chk = $hash{$_} ? " CHECKED" : "";
                print "<INPUT TYPE=CHECKBOX NAME=\"$name\" VALUE=\"$_\"$chk TABINDEX=$tab> $it\n";
        }
        print <<HTML;
<INPUT TYPE=HIDDEN NAME="$name" VALUE="">
</div></td>
<td></td>
</tr>
HTML
}

sub funR {
	my ($desc, $name, $val, $opts) = @_;
	print <<HTML;
<tr>
<td></td>
<td><div class="bText">$desc</div></td>
<td><div class="sText">
HTML
	foreach(split(/,\s*/, $opts)) {
		$tab++;
		my $it = ucfirst(lc($_));
		my $chk = $_ eq $val ? " CHECKED" : "";
		print "<INPUT TYPE=RADIO NAME=\"$name\" VALUE=\"$_\"$chk TABINDEX=$tab> $it\n";
	}
	print <<HTML;
</div></td>
<td></td>
</tr>
HTML
}
	
sub funL {
	my ($desc, $name, $val, $opts, $onchange) = @_;
	$tab++;
	my $extra;
	$extra = " onChange=\"SendTemp();\"" if $onchange;
	print <<HTML;
<tr>
<td></td>
<td><div class="bText">$desc</div></td>
<td><div class="sText">
<SELECT NAME="$name" TABINDEX=$tab$extra>
HTML
	foreach(split(/,\s*/, $opts)) {
		my ($key, $data) = split(/:\s*/, $_);
		my $sel = $val eq $key ? ' SELECTED' : '';
		print "<OPTION VALUE=\"$key\"$sel>$data\n";
	}
        print <<HTML;
</SELECT>
</div></td>
<td></td>
</tr>
HTML

}

sub funX {
	my ($desc, $name, $val, $opts) = @_;
	if (uc($opts) eq 'DBI') {
		eval 'require DBI;';
		my @drivers;
		eval '@drivers = DBI->available_drivers;';
		unless (@drivers) {
			funH($desc, $name, "");
			return;
		}
		my $list = join(",", ":", map {"$_:$_"} @drivers);
		funL($desc, $name, $val, $list, 1);
		return;
	}
	if (uc($opts) eq 'DB') {
		my @db;
		require DBI;
		my $typ = GetParam('DB_TYPE');
		eval '@db =DBI->data_sources($typ) if $typ;';
		if (@db) {
			my $list = join(",", ":", map {s/^dbi:\w+://i; "$_:$_"} @db);
			funL($desc, $name, $val, $list);
			return;
		}
		funT($desc, $name, $val);
	}
}

sub funD {
	my ($desc, $name, $val, $opts) = @_;
	$tab++;
	my $extra;
	$extra = " onFocus=\"SetSafety('$name', '$desc');\" onBlur=\"return WarnSafety('$name')\"" if ($opts =~ /W/);
	my $extra2;
	$extra2 = "SetSafety('$name', '$desc'); " if ($opts =~ /W/);
	print <<HTML;
<tr>
<td></td>
<td><div class="bText">$desc</div></td>
<td><div class="sText"><INPUT NAME="$name" VALUE="$val" SIZE=20 MAXLENGTH=100 TABINDEX=$tab $extra>
<INPUT TYPE=BUTTON onClick="${extra2}Browse('$name')" VALUE="...">
</div></td>
<td></td>
</tr>
HTML
}


