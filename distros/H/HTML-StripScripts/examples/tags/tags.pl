#!/usr/bin/perl
use strict;
use warnings;

use blib;
use HTML::StripScripts::Parser();
use MyStripScripts();

my $html = <<HTML;
<html>
  <head>
    <title>Test</title>
    <meta http-equiv="content-type" content="text/html" />
    <link type="text/css" rel="stylesheet" href="/styles.css" />
  </head>
  <body>
    Some text
  </body>
</html>
HTML


my $original = HTML::StripScripts::Parser->new({ 
    Context     => 'Document', 
    AllowHref   => 1,
});
print "\nDocument filtered via HTML::StripScripts::Parser:\n";
print   "-------------------------------------------------\n\n";
print $original->filter_html($html);

my $new      = MyStripScripts->new({
    Context     => 'Document', 
    AllowHref   => 1, 
});
print "\n\nDocument filtered via MyStripScripts:\n";
print     "-------------------------------------\n\n";
print $new->filter_html($html);

print "\n\n";



