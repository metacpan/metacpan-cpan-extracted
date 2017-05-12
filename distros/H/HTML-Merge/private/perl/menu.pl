#!/usr/bin/perl

use CGI qw/:standard/;
use HTML::Merge::Development;
use strict;

&ReadConfig();

do "bk_lib.pl";

&backend_header;

my $action=param('action');
my $eng;

# refresh template list 
if ($action eq 'REFRESH')
{
	require HTML::Merge::Engine;
	$eng=HTML::Merge::Engine->CreateObject();
	$eng->GetTemplates();
	print "Template list updated. <br>\n"; 	
}

print <<HTML;
<B>Menu</B>:
<UL>
	<LI> <A HREF="adduser.pl?$extra">Add users or change passwords</A>
	<LI> <A HREF="users.pl?$extra">User manager</A>
	<LI> <A HREF="many.pl?$extra&type=group">Group manager</A>
	<LI> <A HREF="perm.pl?$extra">Permission manager</A>
	<LI> <A HREF="many.pl?$extra&type=realm">Realm manager</A>
	<LI> <A HREF="many.pl?$extra&type=subsite">Subsite manager</A>
	<LI> <A HREF="temps.pl?$extra">Template manager</A>
	<LI> <A HREF="$ENV{'SCRIPT_NAME'}?$extra&action=REFRESH">Refresh template list</A>
	<LI> <A HREF="javascript: opener.focus(); close();">Close</A>
</UL>
HTML

&backend_footer;
