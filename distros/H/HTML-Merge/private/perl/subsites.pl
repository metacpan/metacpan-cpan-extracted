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
&$code if $code;
print <<HTML;
<B>Group manager</B>:<BR>
<UL>
HTML

my %subsites;
my $dbh = $engine->DBH;
my $sql = "SELECT subsitename 
	FROM $HTML::Merge::Ini::SESSION_DB.subsites 
	ORDER BY subsitename";
my $sth = $dbh->prepare($sql);
$sth->execute;

while (my ($subsite) = $sth->fetchrow_array) {
	$subsites{$subsite}++;
	print <<HTML;
	<LI> <A HREF="onesubsite.pl?$extra&subsite=$subsite">Manage subsite $subsite</A>
HTML
}
print <<HTML;
</UL>
HTML

$sql = "SELECT A.subsitename, Count(B.template_id) AS templates
        FROM $HTML::Merge::Ini::SESSION_DB.subsites A,
        $HTML::Merge::Ini::SESSION_DB.containers B 
	WHERE B.subsite_id = A.id
        GROUP BY subsitename";
$sth = $dbh->prepare($sql);
$sth->execute;

while (my ($subsite) = $sth->fetchrow_array) {
	delete $subsites{$subsite};
}
if (%subsites) {
	print <<HTML;
</UL>
Empty subsites:
<UL>
HTML
	foreach (sort keys %subsites) {
		print <<HTML;
		<LI> $_ <A HREF="$ENV{'SCRIPT_NAME'}?$extra&action=DESTROY&subsite=$_">Destroy</A>
HTML
	}
	print <<HTML;
</UL>
HTML
}

print <<HTML;
<HR>
HTML
openform("CREATE");
print <<HTML;
New subsite name:
<INPUT NAME="subsite">
<INPUT TYPE=SUBMIT VALUE="Create new subsite">
</FORM>
<A HREF="menu.pl?$extra">Menu</A>
HTML

&backend_footer;

sub doDESTROY {
	my $subsite = param('subsite');
	my $dbh = $engine->DBH;
	my $sql = "SELECT id 
		FROM $HTML::Merge::Ini::SESSION_DB.subsites
                WHERE subsitename = '$subsite'";
	my ($id) = $dbh->selectrow_array($sql);
	return unless $id;
	$sql = "DELETE FROM $HTML::Merge::Ini::SESSION_DB.delegation
                WHERE subsite_id = $id";
	$dbh->do($sql);
	$sql = "DELETE FROM $HTML::Merge::Ini::SESSION_DB.security
                WHERE subsite_id = $id";
	$dbh->do($sql);
	$sql = "DELETE FROM $HTML::Merge::Ini::SESSION_DB.subsites
                WHERE id = $id";
	$dbh->do($sql);
	print "Group $subsite erased.<BR>\n";
}

sub doCREATE {
	my $subsite = param('subsite');
	$engine->GetSubsiteID($subsite);
	print "Subsite $subsite created.<BR>\n";
}
