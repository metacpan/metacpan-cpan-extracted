#!/usr/bin/perl
#
# fixed for security vulnerability.
# This script is not secure - and when not in a development environment
# better be not allowed to run from public directories
#
use HTML::Merge::Development;
use HTML::Merge::Error;
use HTML::Merge::Compile;
use CGI qw/:standard :netscape/;
use strict;

print "Content-type: text/html\n\n";
my $template = param('template');
die "This LOOK like a security problem !" if  $template =~ /[|\\\/]/;
my $open = $HTML::Merge::Compile::open;
my @allways_show = ("loops.html","cookie.html","autoform.html","dates.html"," showdb.html");

my $template = param('template');
my $fn;
if  (!(join(' ',@allways_show) =~ /$template/))
	{
	ReadConfig();
        $fn = "$HTML::Merge::Ini::TEMPLATE_PATH/$template";
	}
	else
	{
	$fn = "/home/httpd/template/app/razinf/$template";
	};
print start_html({-bgcolor => 'Silver'}, "Source for $template");

unless ($template) {
	&HTML::Merge::Error::ForceError("No template specified");
	exit;
}
print h2("Source for $template");

open(I, $fn) if -r $fn;
my $text = join("", <I>);
close(I);

$text =~ s/&/&amp;/g;
$text =~ s/"/&quot;/g;
$text =~ s/</&lt;/g;
$text =~ s/>/&gt;/g;

print pre($text);
print end_html;
