
use strict;

# Tests 'text'-style XML parsing (i.e. XML is in a scalar, not a file)

$^W = 1;

print "1..1\n";

use HTML::Template::XPath;

my $xpt = new HTML::Template::XPath(default_lang => 'en',
				root_dir => './t');

my $xml = <<"EOF";
<?xml version="1.0"?>
<Page NAME="Home">
   <Title>XML Page!</Title>
   <DATA>
      <users ID="0">
            <ROW ID="0">
                  <User>root</User>
                  <Password>aaaaaa</Password>
            </ROW>
            <ROW ID="1">
                  <User>simon</User>
                  <Password>bbbbbb</Password>
            </ROW>
            <ROWCOUNT>2</ROWCOUNT>
      </users>
   </DATA>
</Page>
EOF

my $output_ref = $xpt->process(xpt_filename => '6_text.xpt',
			xml_text => $xml,
			lang => 'en');

my $expected_output = `cat t/6_text.out`;

print "not " if $$output_ref ne $expected_output;
print "ok 1\n";
