#!/usr/bin/perl

use CGI qw/:standard/;
use HTML::Merge::Development;
use HTML::Merge::Engine qw(:unconfig);
use strict;
use vars qw($dir);

&ReadConfig();
my %engines;
tie %engines, 'HTML::Merge::Engine';
my $engine = $engines{""};

my $action = param('action');
my $code = UNIVERSAL::can(__PACKAGE__, "do$action");

do "bk_lib.pl";

&backend_header;

&$code if $code;

$dir = param('dir');
print <<HTML;
<script language="JavaScript">
<!--
////////////////////////////////
function CheckAll(obj)
{
	for(i=0;document.forms[0].files[i] != null; i++)
	{
		document.forms[0].files[i].checked=obj.checked;
	}
}
////////////////////////////////
//-->
</script>
HTML
print "<B>Now at <U>", $dir || "[Root]", "</U></B>:<BR><BR>\n";
print "Subdirectories:\n<UL>\n";

if ($dir) {
	my @tokens = split(/\//, $dir);
	shift @tokens;
	my $up = join("/", @tokens);

	print qq!<LI> <A HREF="$ENV{'SCRIPT_NAME'}?$extra&dir=$up"><B>[..]</B></A>\n!;
}

my @files;

foreach (glob("$HTML::Merge::Ini::TEMPLATE_PATH/$dir/*")) {
	next if (/^\.+$/);
	my $save = $_;
	s|^$HTML::Merge::Ini::TEMPLATE_PATH/$dir/||;
	unless (-d $save) {
		push(@files, $_);
		next;
	}
	my $item = ($dir ? "$dir/" : "") . $_;
	print qq!<LI> <A HREF="$ENV{'SCRIPT_NAME'}?$extra&dir=$item">$_</A>\n!;
}

print <<HTML;
</UL>

HTML
&openform('SUBSCRIBE', 'dir');
print <<HTML;
Files:
<BR><INPUT NAME="check_all" TYPE=CHECKBOX onClick="CheckAll(this)"> Check all
<UL>
HTML


foreach (@files) {
	my $item = ($dir ? "$dir/" : "") . $_;
	print <<HTML;
<LI> <INPUT NAME="files" TYPE=CHECKBOX VALUE="$_">
<A HREF="edit.pl?$extra&file=$item">$_</A>
HTML
}
print <<HTML;
</UL>

<INPUT TYPE=RADIO NAME="what" VALUE="REALM">
Grant realms:<BR>
HTML
my @realms = $engine->GetRealms;
if (@realms) {
	print qq!<SELECT NAME="realms" SIZE=6 MULTIPLE>\n!;
	foreach (@realms) {
		print qq!<OPTION VALUE="$_">$_\n!;
	}
	print qq!</SELECT> Or:<BR>\n!;
}
print <<HTML;
Create new realm: <INPUT NAME="realms"><BR>

<INPUT TYPE=RADIO NAME="what" VALUE="SUBSITE">
Attach to subsites:<BR>
HTML
my @subsites = $engine->GetSubsites;
if (@subsites) {
	print qq!<SELECT NAME="subsites" SIZE=6 MULTIPLE>\n!;
	foreach (@subsites) {
		print qq!<OPTION VALUE="$_">$_\n!;
	}
	print "</SELECT> or:<BR>\n";
}
print <<HTML;
Create new subsite: <INPUT NAME="subsites"><BR>
<INPUT TYPE=SUBMIT VALUE="Perform">
</FORM>
<HR>
<A HREF="menu.pl?$extra">Menu</A>
HTML

&backend_footer;

sub doSUBSCRIBE {
	my $what = param('what');
	my $fun = UNIVERSAL::can(__PACKAGE__, "per$what");
	return unless $fun;
	foreach my $f (param('files')) {
		next unless $f;
		foreach my $o (param(lc($what) . 's')) {
			next unless $o;
			&$fun($f, $o);
		}
	}
}

sub perREALM {
	my ($file, $realm) = @_;
	$engine->Request($realm, $file);
	print "Realm $realm has been required from template $file.<BR>\n";
}

sub perSUBSITE {
	my ($file, $subsite) = @_;
	$engine->Attach($file, $subsite);
	print "Template $file has been attached to subsite $subsite.<BR>\n";
}
