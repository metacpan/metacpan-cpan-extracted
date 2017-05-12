
use strict;

# exposes bug in HTML::Template 2.3 and below, 
# Thanks to Matt Churchyard for bug report

$^W = 1;

print "1..1\n";

use HTML::Template::XPath;

my $xpt = new HTML::Template::XPath(default_lang => 'en',
				root_dir => './t');

my $output_ref = $xpt->process(xpt_filename => '5_simple.xpt',
			xml_filename => '5_simple.xml',
			lang => 'en');

my $expected_output = `cat t/5_simple.out`;

print "not " if $$output_ref ne $expected_output;
print "ok 1\n";
