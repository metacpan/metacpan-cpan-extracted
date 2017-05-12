%# $Id: welcome.mc,v 1.1 2007-05-16 12:41:15 mike Exp $
<%args>
$user
</%args>
% my $site = $m->notes("site");
Dear <% $user->name() %>,

Thank you for registering with <% $site->name() %>,
	http://<% $ENV{HTTP_HOST} %>/

Your registration details are as follows:

            Name: <% $user->name() %>
           Email: <% $user->email_address() %>
        Password: <% $user->password() %>

If you should need to change any of this information, please visit
	http://<% $ENV{HTTP_HOST} %>/user/details.html

