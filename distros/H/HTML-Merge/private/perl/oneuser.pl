#!/usr/bin/perl

use CGI qw/:standard/;
use HTML::Merge::Development;
use HTML::Merge::Engine qw(:unconfig);
use strict;
use vars qw($user);

&ReadConfig();
my %engines;
tie %engines, 'HTML::Merge::Engine';
my $engine = $engines{""};

my $action = param('action');
my $code = UNIVERSAL::can(__PACKAGE__, "do$action");

$user = param('user');

do "bk_lib.pl";
&backend_header;

unless ($user) {
	print "No user selected.\n";
	&backend_footer;
	exit;
}

&$code if $code;
print <<HTML;
<B>Managing user <U>$user</U></B>:<BR><BR>

HTML
my ($name, $tag) = $engine->GetUserName($user);
openform('EDIT', 'user');
print <<HTML;
Name: <INPUT NAME="name" VALUE="$name"><BR>
Tag: <INPUT NAME="tag" VALUE="$tag"><BR>
<INPUT TYPE=SUBMIT VALUE="Update details">
</FORM>

<FORM ACTION="$ENV{'SCRIPT_NAME'}" onSubmit="return confirm_it();"
        NAME="form" METHOD=POST>
<INPUT NAME="user" VALUE="$user" TYPE=HIDDEN>
<INPUT NAME="action" VALUE="CHPASS" TYPE=HIDDEN>
HTML
HTML::Merge::Development::Transfer;

print <<HTML;
Password: <INPUT NAME="pass" TYPE=PASSWORD><BR>
Password (again): <INPUT NAME="pass2" TYPE=PASSWORD><BR>
<INPUT TYPE=SUBMIT VALUE="Change password">
</FORM>
<SCRIPT>
<!--
        function confirm_it() {
                var form = document.form;
                if (form.pass.value != form.pass2.value) {
                        alert("Password mismatch");
                        return false;
                }
                return true;
        }
// -->
</SCRIPT>
<HR>
<A HREF="users.pl?$extra">Back to users</A>
HTML

&backend_footer;

sub doEDIT {
	my ($name, $tag) = (param('name'), param('tag'));
	eval {
		$engine->SetDBField('user' => $user, 'description' => $name);
		$engine->SetDBField('user' => $user, 'tag' => $tag);
	};
	if ($@) {
		print "Error: $@<BR>\n";
		return;
	}
	print "User $user updated.<BR>\n";
}

sub doCHPASS {
        eval {
                $engine->AddUser($user, param('pass'));
        };
        unless ($@) {
                print "User $user updated.<BR>\n";
        } else {
                print "Error: $@<BR>\n";
        }
}
