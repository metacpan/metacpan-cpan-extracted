#!/usr/bin/perl

use HTML::FormatText::WithLinks::AndTables;
use Test::More tests => 1;
my $html = '
<a href="http://example.com">Link</a>
<table><tr><td><a href="http://example.com/foo">Cell link</a></td></tr></table>';

my $text = HTML::FormatText::WithLinks::AndTables->convert($html, 
{
            footnote        => '',
            after_link      => ' (%l)',
            before_link     => '',
            leftmargin      => 0,
});
print "got: '$text'\n";
my $expected = ' Link (http://example.com)

 Cell link (http://example.com/foo) 

';
#print "expected: '$expected'\n";
ok($text eq $expected,"links inside tables have after_link applied properly");


