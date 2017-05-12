
use strict;

$^W = 1;

print "1..5\n";

use HTML::Template::XPath;

my $generate;
# should be used by TJ only
#$generate = 1;

my $xpt = new HTML::Template::XPath(default_lang => 'en',
				root_dir => './t');

my $output_ref = $xpt->process(xpt_filename => '3_lang.xpt',
			xml_filename => 'dir/3_lang.xml',
			lang => 'de');
if($generate){
  open OUT, ">t/3_lang.de.out";
  print OUT $$output_ref;
  close OUT;
}
my $expected_output = `cat t/3_lang.de.out`;
print "not " if $$output_ref ne $expected_output;
print "ok 1\n";
$output_ref = $xpt->process(xpt_filename => '3_lang.xpt',
			xml_filename => 'dir/3_lang.xml',
			lang => 'en');
if($generate){
  open OUT, ">t/3_lang.en.out";
  print OUT $$output_ref;
  close OUT;
}
$expected_output = `cat t/3_lang.en.out`;
print "not " if $$output_ref ne $expected_output;
print "ok 2\n";
$output_ref = $xpt->process(xpt_filename => '3_lang.xpt',
			xml_filename => 'dir/3_lang.xml',
			lang => 'es');
if($generate){
  open OUT, ">t/3_lang.es.out";
  print OUT $$output_ref;
  close OUT;
}
$expected_output = `cat t/3_lang.es.out`;
print "not " if $$output_ref ne $expected_output;
print "ok 3\n";

my $file_mtimes = $xpt->file_mtimes;

print "not " unless exists $file_mtimes->{'./t/dir/3_lang.xml'};
print "ok 4\n";
print "not " unless exists $file_mtimes->{'./t/dir/dir/3_lang_a.xml'};
print "ok 5\n";
