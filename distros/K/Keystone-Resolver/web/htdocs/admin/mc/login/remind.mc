%# $Id: remind.mc,v 1.4 2007-12-12 15:16:33 marc Exp $
<%args>
$email_address
</%args>
% my $site = $m->notes("site");
<%perl>
my $user = $site->user1(email_address => $email_address);
if (!defined $user) {
</%perl>
     <div class="error">
      <p>
       The email address <b><% $email_address %></b> is not recognised.
      </p>
      <p>
       Please go back and
       <a href="./login.html?email_address=<%
	uri_escape_utf8($email_address) %>">register</a>.
      </p>
     </div>
<%perl>
} else {
    $site->send_email($email_address,
		      "Password reminder for " . $site->name(),
		      $m->scomp("/mc/email/password.mc", user => $user));
</%perl>
      <p>
       A password reminder has been sent to <b><% $email_address %></b>.
      </p>
      <p>
       Please check your email and return to
       <a href="./login.html?email_address=<%
	uri_escape_utf8($email_address) %>">the login page</a>
      </p>
% }
