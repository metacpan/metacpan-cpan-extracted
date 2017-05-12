%# $Id: submitted.mc,v 1.3 2007-12-12 15:16:33 marc Exp $
<%args>
$email_address
$password
</%args>
% my $site = $m->notes("site");
% my $session = $m->notes("session");
<%perl>
my $user = $site->user1(email_address => $email_address,
			password => $password);
if (!defined $user) {
</%perl>
     <div class="error">
      <p>
       The email address <b><% $email_address %></b> and the password
       you entered do not match.
      </p>
      <p>
       Please go back and
       <a href="./login.html?email_address=<%
	uri_escape_utf8($email_address) %>">try again</a>.
      </p>
     </div>
<%perl>
    return;
}
</%perl>
<& /mc/login/doit.mc, user => $user &>
% my $dest = $session->dest();
<%doc>
### Better than providing the link below would be to redirect to the
    destination URL.  And better still would be to directly invoke the
    components corresponding to that URL.
</%doc>
      <p>
       Welcome back, <b><% $user->name() %></b>.
      </p>
% if (defined $dest) {
      <p>
       <a href="<% $dest %>">Continue</a>
      </p>
% }
