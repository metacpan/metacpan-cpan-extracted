%# $Id: password.mc,v 1.1 2007-05-16 12:41:15 mike Exp $
<%args>
$user
</%args>
% my $site = $m->notes("site");
Dear <% $user->name() %>,

You have asked us to email you a reminder of your password for
<% $site->name() %>,
	http://<% $ENV{HTTP_HOST} %>/

Your password is: "<% $user->password() %>"

Because email communication is not secure, you may now wish to login
and change your password, at:
	http://<% $ENV{HTTP_HOST} %>/user/password.html

