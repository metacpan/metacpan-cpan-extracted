#!/usr/bin/perl -w

# Example of menu
# This program is an auto-protected CGI that reads a HTML file and replace
# tagged links :
#  * by links if the connected user is authorized to access to this site
#  * by italic text else
#
# The tagged links have to be written so :
#    [[http://my-protected-site/welcome Comment to display in the link]]

# Set here the path to the HTML file to read
my $html_file = '/path/to/html/template';

# DEBIAN Users : uncomment this
# require "/usr/share/lemonldap-ng/configStorage.pm";

use Lemonldap::NG::Handler::CGI;
use strict;

# Initialization
our $cgi;
$cgi = Lemonldap::NG::Handler::CGI->new( { https => 0, } ) or die;

# Authentication
$cgi->authenticate();

open F, $html_file or die "Template \"$html_file\" not found !";

# HTTP Headers
print $cgi->header(
    -type    => 'text/html',
    -charset => 'UTF-8',
);

while (<F>) {

    #print "TOTO" if(m#[[(https?://\S+)\s+(.*?)]]#);
    s#\[\[(https?://\S+)\s+(.*?)\]\]#&link($1,$2)#eg;
    print;
}
close F;

sub link {
    my ( $l, $t ) = @_;
    return ( $cgi->testUri($l) ? "<a href=\"$l\">$t</a>" : "<i>$t</i>" );
}

