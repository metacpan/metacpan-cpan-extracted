#!/usr/bin/perl
use strict;
use warnings;

use HTML::StripScripts::Parser();
use MyStripScripts();

my $html = <<HTML;
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN" "http://www.w3.org/TR/html4/strict.dtd">
<html>
  <head>
    <title>Test</title>
  </head>
  <body>
    Some text
  </body>
</html>
HTML


my $original = HTML::StripScripts::Parser->new({ Context => 'Document' });
print "\nDocument filtered via HTML::StripScripts::Parser:\n";
print   "-------------------------------------------------\n\n";
print $original->filter_html($html);

my $new      = MyStripScripts->new({ Context => 'Document' });
print "\n\nDocument filtered via MyStripScripts:\n";
print     "-------------------------------------\n\n";
print $new->filter_html($html);

print "\n\n";



