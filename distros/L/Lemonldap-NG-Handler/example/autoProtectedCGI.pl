#!/usr/bin/perl

my $cgi = new Lemonldap::NG::Handler::CGI( { https => 0, } );

$cgi->authenticate();

print $cgi->header;

unless ( $cgi->authorize ) {
    print $cgi->start_html('Forbidden');
    print "You're not authorized to see this page";
    print $cgi->end_html;
}
else {
    print $cgi->start_html('Authorized');
    print "<h1>Welcome</h1>You're authorized to see this page";
    print $cgi->end_html;
}
