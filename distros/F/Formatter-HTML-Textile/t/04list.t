use Test::More tests=>2;
use Formatter::HTML::Textile;

my $source = "* list1\n* list2\n* list3\n";
my $dest = Formatter::HTML::Textile->format($source)->fragment;
my $expected = "<ul>\n<li>list1</li>\n<li>list2</li>\n<li>list3</li>\n</ul>";

is($dest, $expected);

$source = "# list1\n# list2\n# list3\n";
$dest = Formatter::HTML::Textile->format($source)->fragment;
$expected = "<ol>\n<li>list1</li>\n<li>list2</li>\n<li>list3</li>\n</ol>";

is($dest, $expected);
