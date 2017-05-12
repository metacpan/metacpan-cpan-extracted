
use strict;

$^W = 1;

print "1..5\n";

use HTML::Template::XPath;

my $xpt = new HTML::Template::XPath(default_lang => 'en',
				root_dir => './t');

my $output_ref = $xpt->process(xpt_filename => '2_document.xpt',
			xml_filename => 'dir/2_document_a.xml',
			lang => 'en');

my $expected_output = `cat t/2_document.out`;

print "not " if $$output_ref ne $expected_output;
print "ok 1\n";

my $file_mtimes = $xpt->file_mtimes;

print "not " unless exists $file_mtimes->{'./t/dir/2_document_a.xml'};
print "ok 2\n";
print "not " unless exists $file_mtimes->{'./t/dir/2_document_b.xml'};
print "ok 3\n";
print "not " unless exists $file_mtimes->{'./t/2_document_c.xml'};
print "ok 4\n";
print "not " unless exists $file_mtimes->{'./t/dir/dir/2_document_d.xml'};
print "ok 5\n";

