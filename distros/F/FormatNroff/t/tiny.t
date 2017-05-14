print "1..1\n";

require HTML::FormatNroff;
use HTML::Parse;
require HTML::Testing;

my $man_date = '20 Dec 97';
my $name = "tiny";

my $html_source =<<END_HERE ;
This is some text.
This is some more text.
END_HERE

my $expected = ".TH \"$name\" \"1\" \"$man_date\" \"HTML\"\n";

$expected .=<<'END_EXPECTED' ;
.PP
This is some text. This is some more text.
END_EXPECTED

my $tester = new HTML::Testing(name => $name,
			       man_date => $man_date,
			       project => 'HTML',
			       man_header => 1,
			       expected => $expected,
			       html_source => $html_source
			       );
$tester->run_test();

1;









