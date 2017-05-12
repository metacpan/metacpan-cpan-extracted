%# $Id: user.mc,v 1.1 2007-05-16 15:44:35 mike Exp $
<%args>
$require => 0
</%args>
<%perl>
my $user = $m->notes("user");
return $user if defined $user || !$require;

# Just-In-Time login if $require is set
$m->comp("/mc/login/login.mc", dest => $ENV{REQUEST_URI});
return undef;
</%perl>
