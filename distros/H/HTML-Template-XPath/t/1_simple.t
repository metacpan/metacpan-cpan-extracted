
use strict;

$^W = 1;

print "1..2\n";

use HTML::Template::XPath;

my $xpt = new HTML::Template::XPath(default_lang => 'en',
				root_dir => './t');

my $output_ref = $xpt->process(xpt_filename => '1_simple.xpt',
			xml_filename => '1_simple.xml',
			lang => 'en');

my $expected_output = `cat t/1_simple.out`;

print "not " if $$output_ref ne $expected_output;
print "ok 1\n";

my $file_mtimes = $xpt->file_mtimes;

print "not " unless exists $file_mtimes->{'./t/1_simple.xml'};
print "ok 2\n";
