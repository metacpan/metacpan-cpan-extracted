#!/usr/bin/perl

use CGI qw/:standard/;
use HTML::Merge::Development;
use HTML::Merge::Engine qw(:unconfig);
use strict;
use vars qw($realm);

&ReadConfig();
my %engines;
tie %engines, 'HTML::Merge::Engine';
my $engine = $engines{""};

my $action = param('action');
my $code = UNIVERSAL::can(__PACKAGE__, "do$action");

$realm = param(param('create') ? 'newrealm' : 'realm');


do "bk_lib.pl";
&backend_header;

if (param('newrealm') && !param('create')) {
	print "New realm entered but checkbox not clicked.<BR>\n";
	$action = "";
	$code = undef;
}

&$code if $code;
print <<HTML;
<B>Permission manager</B>:<BR>
Users:
HTML
openform('ADD_USER');

my $dbh = $engine->DBH;

foreach ($engine->GetUsers) {
	print qq!<INPUT TYPE=CHECKBOX NAME="users" VALUE="$_"> $_<BR>\n!;
}

print qq!<SELECT NAME="realm">\n!;

my @realms = $engine->GetRealms;
foreach (@realms) {
	print qq!<OPTION VALUE="$_">$_\n!;
}
print <<HTML;
</SELECT>
<INPUT TYPE=CHECKBOX NAME="create" VALUE="1">
or create realm:
<INPUT NAME="newrealm"><BR>
<INPUT TYPE=HIDDEN NAME="action" VALUE="ADD_USER">
<INPUT TYPE=SUBMIT VALUE="Grant realm to users">
</FORM>

Groups:
HTML
openform('ADD_GROUP');

foreach ($engine->GetGroups) {
	print qq!<INPUT TYPE=CHECKBOX NAME="groups" VALUE="$_"> $_<BR>\n!;
}
print qq!<SELECT NAME="realm">\n!;

foreach (@realms) {
	print qq!<OPTION VALUE="$_">$_\n!;
}

print <<HTML;
</SELECT>
<INPUT TYPE=CHECKBOX NAME="create" VALUE="1">
or create realm:
<INPUT NAME="newrealm"><BR>
<INPUT TYPE=SUBMIT VALUE="Grant realm to groups">
</FORM>

<HR>
<A HREF="menu.pl?$extra">Menu</A>
HTML

&backend_footer;

sub doADD_GROUP {
	unless ($realm) {
		print "No realm chosen.<BR>\n";
		return;
	}
	foreach (param('groups')) {
		$engine->GrantGroup($_, $realm);
		print "Group $_ has been granted realm $realm.<BR>\n";
	}
}

sub doADD_USER {
	unless ($realm) {
		print "No realm chosen.<BR>\n";
		return;
	}
	foreach (param('users')) {
		$engine->GrantUser($_, $realm);
		print "User $_ has been granted realm $realm.<BR>\n";
	}
}
