%# $Id: doit.mc,v 1.2 2007-06-11 16:04:51 mike Exp $
<%args>
$user
</%args>
% my $session = $m->notes("session");
<%perl>
# Store the new user object for lmenu.mc to see later
$m->notes(user => $user);
$session->update(user_id => $user->id());
</%perl>
