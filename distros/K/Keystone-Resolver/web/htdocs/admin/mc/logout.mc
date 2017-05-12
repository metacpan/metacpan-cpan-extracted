%# $Id: logout.mc,v 1.2 2007-06-11 16:04:51 mike Exp $
% my $user = $m->notes("user");
% my $session = $m->notes("session");
<%perl>
if (!defined $user) {
    print qq[<p class="error">You are not logged in!</p>\n];
} else {
    # Note the destruction of the user object for lmenu.mc to see later
    $m->notes(user => 0);
    $session->update(user_id => 0);
</%perl>
      <p>
       Goodbye, <b><% $user->name() %></b>.
      </p>
% }
