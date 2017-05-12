#!/usr/bin/perl

use CGI qw/:standard/;
use HTML::Merge::Development;
use HTML::Merge::Engine qw(:unconfig);
use strict;

&ReadConfig();
my %engines;
tie %engines, 'HTML::Merge::Engine';
my $engine = $engines{""};

my $action = param('action');
my $code = UNIVERSAL::can(__PACKAGE__, "do$action");

do "bk_lib.pl";

&backend_header;

$file = param('file');

unless ($file) {
	print "No file chosen.\n";
	&backend_footer;
	exit;
}

&$code if $code;
print <<HTML;
<B>Editing <U>$file</U></B>:<BR>

HTML

openform('UPDATE', 'file');

my $dbh = $engine->DBH;

my %realms = $engine->GetAllRealms;
my @req = $engine->Required($file);

@realms{@req} = ("*") x scalar(@req);

foreach (sort keys %realms) {
	my $chk = $realms{$_} eq "*" ? ' CHECKED' : '';
	print <<HTML;
	<INPUT TYPE=CHECKBOX$chk NAME="require" VALUE="$_">
        $_<BR>
HTML
}

print <<HTML;
<INPUT TYPE=SUBMIT VALUE="Reasses limits">
</FORM>

Subsites:<BR>
HTML

my %subsites = $engine->GetAllSubsites;

my @subsites = $engine->Links('template' => $file, 'subsite');
if (@subsites) {
	print "<UL>\n";
	foreach (@subsites) {
		delete $subsites{$_};
		print <<HTML;
	<LI> $_ <A HREF="$ENV{'SCRIPT_NAME'}?$extra&file=$file&subsite=$_&action=DEL_SUBSITE">Detach</A>
HTML
	}
	print "</UL>\n";
} else {
	print "<B>None</B><BR>";
}

if (%subsites) {
	openform('ADD_SUBSITES', 'file');
	print "<SELECT SIZE=6 MULTIPLE NAME=\"subsites\">\n";

	foreach (sort keys %subsites) {
		print "	<OPTION VALUE=\"$_\">$_\n";
	}
	print <<HTML;
</SELECT><BR>
<INPUT TYPE=SUBMIT VALUE="Attach to subsites">
</FORM>
HTML
}
openform('ADD_SUBSITES', 'file');
my @tokens = split(/\//, $file);
pop @tokens;
my $back =join("/", @tokens);
print <<HTML;
Add to new subsite: <INPUT NAME="subsites"><BR>
<INPUT TYPE=SUBMIT VALUE="Create subsite">
</FORM>
<HR>
<A HREF="temps.pl?$extra&dir=$back">Back to templates</A>
HTML

&backend_footer;

sub doUPDATE {
	my $req = join(",", param("require"));
	$engine->Require($file, $req);
	print "Permissions updated.<BR>\n";
}

sub doADD_SUBSITES {
	foreach (param('subsites')) {
		$engine->Attach($file, $_); 
		print "Template $file attached to subsite $_.<BR>\n";
	}
}

sub doDEL_SUBSITE {
	my $subsite = param('subsite');
	$engine->Detach($file, $subsite);
	print "Template $file attached rom subsite $subsite.<BR>\n";
}
