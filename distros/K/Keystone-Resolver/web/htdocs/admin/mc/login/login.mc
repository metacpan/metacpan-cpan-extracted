%# $Id: login.mc,v 1.3 2007-06-21 14:19:09 mike Exp $
<%args>
$dest => undef
</%args>
<%perl>
if (defined $dest) {
    my $session = $m->notes("session");
    $session->update(dest => $dest);
}

my $email_address = utf8param($r, "email_address");
my $password = utf8param($r, "password");
my $login = utf8param($r, "login");
my $remind = utf8param($r, "remind");
my $register = utf8param($r, "register");

my @params = (email_address => $email_address);
if ($email_address && $password && defined $login) {
    $m->comp("submitted.mc", @params, password => $password);
} elsif ($email_address && defined $remind) {
    $m->comp("remind.mc", @params);
} elsif ($email_address && defined $register) {
    $m->comp("/mc/register/register.mc", @params);
} else {
    $m->comp("form.mc", submitted => (defined $login || defined $remind ||
				      defined $register));
}
</%perl>
