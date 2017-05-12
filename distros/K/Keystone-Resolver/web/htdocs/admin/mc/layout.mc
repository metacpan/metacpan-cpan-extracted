%# $Id: layout.mc,v 1.25 2008-04-02 12:51:46 mike Exp $
<%args>
$debug => undef
$title
$component
</%args>
<%once>
use Encode;
use URI::Escape qw(uri_escape_utf8 uri_unescape);
use HTML::Entities;
use Keystone::Resolver::Admin;
use Keystone::Resolver::Utils qw(encode_hash decode_hash utf8param);
</%once>
<%perl>
$r->content_type("text/html; charset=utf-8");
my $admin = Keystone::Resolver::Admin->admin();
my $host = $ENV{HTTP_HOST}; # Or we could use SERVER_NAME
my $tag = $admin->hostname2tag($host);
my $site;
eval {
    $site = $admin->site($tag);
}; if ($@) {
    print <<__EOT__;
It was not possible to connect to the Keystone Resolver database.<br/>
Please see <tt>/usr/share/libkeystone-resolver-perl/db/README</tt><br/>
<br/>
Detailed error message follows, but you can probably ignore it:
<hr/>
<pre>$@</pre>
__EOT__
    return;
}
if (!defined $site) {
    print <<__EOT__;
Unknown Keystone Resolver site '$tag' (host $host)</br>
Please see <tt>/usr/share/libkeystone-resolver-perl/db/README.sites</tt><br/>
__EOT__
    return;
}
$m->notes(site => $site);

# Totally chiropteral-excrementally crazy ... you have to use a
# different cookie API depending on whether you're running under
# Apache 1.x or 2.x.  And the fetch() and bake() methods in Apache 2
# have different parameters from the same methods in Apache 1.
# Thanks, Apache guys!  I'm sure you know best!
#
my $cookiePackage;
my $api = $ENV{MOD_PERL_API_VERSION};
if ($api && $api == 2) {
    $cookiePackage = "Apache2::Cookie";
} else {
    $cookiePackage = "Apache::Cookie";
}
my $cookieModule = $cookiePackage;
$cookieModule =~ s/::/\//g;
require "$cookieModule.pm";
my $cookies = $cookiePackage->fetch($cookiePackage eq 'Apache2::Cookie' ? $r : ());
my $cookie = $cookies->{session};
#warn "cookieModule=[$cookieModule], cookies=[$cookies], cookie=[$cookie]";

my $session = undef;
my $user = undef;

if (defined $cookie) {
    my $cval = $cookie->value();
    $session = $site->session1(cookie => $cval);
    if (!defined $session) {
	# Old cookie for a session that's no longer around.  We just
	# delete the cookie, silently logging the user out if he was
	# logged in.
	$site->log(1, "expiring old session $cval");
	my $cookie = new $cookiePackage($r, -name => "session",
					-value => $cval, -expires => '-1d');
	$cookie->bake($cookiePackage eq 'Apache2::Cookie' ? $r : ());
    }
}

if (!defined $session) {
    $session = $site->create_session();
    my $cookie = new $cookiePackage($r, -name => "session",
				    -value => $session->cookie());
    $cookie->bake($cookiePackage eq 'Apache2::Cookie' ? $r : ());
}
$m->notes(session => $session);

my $uid = $session->user_id();
if ($uid) {
    $user = $site->user1(id => $uid);
    die "Invalid user-ID '$uid'" if !defined $user;
    $m->notes(user => $user);
}

# Generate the text of the client area before emitting the framework:
# this allows it to affect the state, so that for example a login or
# logout $component can set or unset $user.
my $text;
eval {
    $text = $m->scomp($component, %ARGS);
}; if ($@ && (!ref $@ || $@->isa("HTML::Mason::Exception")) && $@ =~ /Unknown column/) {
    print <<__EOT__;
A column was missing from a table in the Keystone Resolver database.<br/>
This probably means that the structure of your database is out of date<br/>
Please see <tt>/usr/share/libkeystone-resolver-perl/db/README.update</tt><br/>
<br/>
Detailed error message follows, but you can probably ignore it:
<hr/>
<pre>$@</pre>
__EOT__
    return;
} elsif ($@) {
    die $@;
}
$user = $m->notes("user");
</%perl>
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE html 
     PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN"
    "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en" lang="en">
 <head>
  <title>Keystone Resolver: <% encode_entities($title) %></title>
  <link rel="stylesheet" type="text/css" href="./style.css"/>
 </head>
 <body>
% $m->comp("/mc/debug/cookies.mc", cookies => $cookies) if $debug;
  <div id="prologue">
   <h1><a href="./">Keystone Resolver</a>: <% $title %></h1>
  </div>
   <div id="usermenu">
% if ($user) {
    <div id="umleft">
     <a href="./user.html"><% encode_entities($user->name()) %></a>
     |
     <a href="./details.html">Details</a>
     |	
     <a href="./password.html">Password</a>
    </div>
    <div id="umright">
     <a href="./logout.html">Logout</a>
    </div>
% } else {
    <div id="umright">
     <a href="./login.html">Login</a>
     or
     <a href="./register.html">Register</a>
    </div>
% }
   </div>
  <div id="menu">
   <a href="./"><b>Home</b></a>
   <p>
    Search:
   </p>
   <ul class="tight">
    <li><a href="./search.html?_class=MetadataFormat">Metadata&nbsp;Format</a></li>
    <li><a href="./search.html?_class=Genre">Genre</a></li>
    <li><a href="./search.html?_class=ServiceType">Service Type</a></li>
    <li><a href="./search.html?_class=Service">Service</a></li>
    <li><a href="./search.html?_class=Serial">Serial</a></li>
    <li><a href="./search.html?_class=SerialAlias">Serial&nbsp;Alias</a></li>
    <li><a href="./search.html?_class=Domain">Domain</a></li>
    <li><a href="./search.html?_class=Provider">Provider</a></li>
    <li><a href="./search.html?_class=ServiceTypeRule">Service Type Rule</a></li>
    <li><a href="./search.html?_class=ServiceRule">Service Rule</a></li>
% if ($user && $user->admin() > 1) {
    <li><a href="./search.html?_class=User"><b>User</b></a></li>
% }
   </ul>
   <p>
    Browse:
   </p>
   <ul class="tight">
    <li><a href="./search.html?_class=MetadataFormat&amp;_submit=Search">Metadata&nbsp;Format</a></li>
    <li><a href="./search.html?_class=Genre&amp;_submit=Search">Genre</a></li>
    <li><a href="./search.html?_class=ServiceType&amp;_submit=Search">Service Type</a></li>
    <li><a href="./search.html?_class=Service&amp;_submit=Search">Service</a></li>
    <li><a href="./search.html?_class=Serial&amp;_submit=Search">Serial</a></li>
    <li><a href="./search.html?_class=SerialAlias&amp;_submit=Search">Serial&nbsp;Alias</a></li>
    <li><a href="./search.html?_class=Domain&amp;_submit=Search">Domain</a></li>
    <li><a href="./search.html?_class=Provider&amp;_submit=Search">Provider</a></li>
    <li><a href="./search.html?_class=ServiceTypeRule&amp;_submit=Search">Service Type Rule</a></li>
    <li><a href="./search.html?_class=ServiceRule&amp;_submit=Search">Service Rule</a></li>
% if ($user && $user->admin() > 1) {
    <li><a href="./search.html?_class=User&amp;_submit=Search"><b>User</b></a></li>
% }
   </ul>
   <br/>
   <p>
    <a href="http://validator.w3.org/check?uri=referer"><img
	src="./valid-xhtml10.png"
	alt="Valid XHTML 1.0 Strict" height="31" width="88" /></a>
    <br/>
    <a href="http://jigsaw.w3.org/css-validator/"><img
	src="./vcss.png"
	alt="Valid CSS!" height="31" width="88" /></a>
   </p>
  </div>
  <div id="main">
<% $text %>
  </div>
  <div id="epilogue">
   <a href="http://indexdata.com/">Index Data</a>
  </div>
 </body>
</html>
