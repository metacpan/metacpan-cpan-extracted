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

sub options {
	my ($user, $name) = @_;
	print <<HTML;
        <INPUT TYPE=CHECKBOX NAME="users" VALUE="$user"> $user
	[
        <A HREF="$ENV{'SCRIPT_NAME'}?$extra&user=$user&action=DEL_USER">Erase from system</A> |
	<A HREF="oneuser.pl?$extra&user=$user">edit</A> ]
	<BR>
HTML
	print "<B>$name</B><BR>\n" if $name;
}

print <<HTML;
<B>User manager</B>:<BR>
HTML
openform('ADD');

my @users = $engine->GetUsers;

foreach (@users) {
	my $realname = $engine->GetUserName($_);
	options($_, $realname);
}

print <<HTML;
<INPUT TYPE=RADIO NAME="what" VALUE="GROUP">
Join groups:<BR>
HTML
my @groups = $engine->GetGroups;

if (@groups) {
	print qq!<SELECT NAME="groups" SIZE=6 MULTIPLE>\n!;
	foreach (@groups) {
		print qq!<OPTION VALUE="$_">$_\n!;
}
	print "</SELECT><BR>Or:\n";
}
print <<HTML;
Create group:
<INPUT NAME="groups"><BR>

<INPUT TYPE=RADIO NAME="what" VALUE="REALM">
Grant realms:<BR>
HTML

my @realms = $engine->GetRealms;
if (@realms) {
	print qq!<SELECT NAME="realms" SIZE=6 MULTIPLE>\n!;
	foreach (@realms) {
		print qq!<OPTION VALUE="$_">$_\n!;
	}
	print "</SELECT>\nOr:<BR>\n";
}

print <<HTML;
Create realm:
<INPUT NAME="realms"><BR>
<INPUT TYPE=SUBMIT VALUE="Perform">
</FORM>
<HR>
<A HREF="menu.pl?$extra">Menu</A>
HTML

&backend_footer;

sub doADD {
	my $what = param('what');
	my $fun = UNIVERSAL::can(__PACKAGE__, "per$what");
	return unless $fun;
	foreach my $u (param('users')) {
		next unless $u;
		foreach my $o (param(lc($what) . 's')) {
			next unless $o;
			&$fun($u, $o);
		}
	}
}

sub perREALM {
	my ($user, $realm) = @_;
	$engine->GrantUser($user, $realm);
	print "User $user has been granted realm $realm.<BR>\n";
}

sub perGROUP {
	my ($user, $group) = @_;
	$engine->JoinGroup($user, $group);
	print "User $user has joined group $group.<BR>\n";
}

sub doJOIN {
die "deprecated";
	my $group = param(param("create") ? "newgroup" : "group");
	unless ($group) {
		print "No group chosen.<BR>\n";
		return;
	}
	foreach (param("users")) {
		$engine->JoinGroup($_, $group);
		print "User $_ has joined group $group.<BR>\n";
	}
}

sub doGRANT {
die "deprecated";
	my $realm = param(param("create") ? "newrealm" : "realm");
	unless ($realm) {
		print "No realm chosen.<BR>\n";
		return;
	}
	foreach (param("users")) {
		$engine->GrantUser($_, $realm);
		print "User $_ has been granted realm $realm.<BR>\n";
	}
}

sub doDEL_USER {
	my $user = param("user");
	$engine->DelUser($user);
	print "Erased user $user.<BR>\n";
}
