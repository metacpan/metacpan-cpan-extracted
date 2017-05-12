%# $Id: submitted.mc,v 1.4 2008-01-29 14:49:02 mike Exp $
% my $site = $m->notes("site");
<%perl>
my %data;
foreach my $key (utf8param($r)) {
    $data{$key} = utf8param($r, $key);
}

# Check benignly for duplicate registration
my $email_address = utf8param($r, "email_address");
my $olduser = $site->user1(email_address => $email_address);
if (defined $olduser) {
</%perl>
     <p>
      The email address you requested,
      <b><% $email_address %></b>,
      is already registered on this site.
     </p>
     <p>
      If this is your email address, then you can request a
      <a href="login.html?remind=1&amp;email_address=<%
	uri_escape_utf8($email_address) %>">password reminder</a>
     </p>
<%perl>
    return;
}

my($user, $errmsg) = $site->add_user(%data,
				     password => utf8param($r, "password1"));
if (!defined $user) {
    return $m->comp("/debug/fatal.mc", errmsg => $errmsg);
}

$site->send_email($email_address,
		   "Welcome to " . $site->name() . "!",
		   $m->scomp("/mc/email/welcome.mc", user => $user));
</%perl>
<& /mc/login/doit.mc, user => $user &>
     <p>
      Thank you for registering!
     </p>
     <p>
      A confirmation email has been sent.
     </p>
% my $dest = $m->notes("session")->dest();
% if (defined $dest) {
      <p>
       <a href="<% $dest %>">Continue</a>
      </p>
% }
