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
<B>Add users</B>:<BR>
<FORM ACTION="$ENV{'SCRIPT_NAME'}" onSubmit="return confirm_it();"
	NAME="form" METHOD=POST>

HTML
&HTML::Merge::Development::Transfer;
print <<HTML;
Username: <INPUT NAME="user"><BR>
Password: <INPUT NAME="pass" TYPE=PASSWORD><BR>
Password again: <INPUT NAME="pass2" TYPE=PASSWORD><BR>
<INPUT TYPE=HIDDEN NAME="action" VALUE="ADD">
<INPUT TYPE=SUBMIT VALUE="Add user/change password">
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
<A HREF="menu.pl?$extra">Menu</A>
HTML

&backend_footer;

sub doADD {
	my $user;
	eval {
		$engine->AddUser($user = param('user'), param('pass'));
	};
	unless ($@) {
		print "User $user updated.<BR>\n";
	} else {
		print "Error: $@.<BR>\n";
	}
}
