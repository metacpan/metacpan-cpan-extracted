use Test::More;
use Markdown::Simple;

my $markdown = q{
# header 1
## header 2
### header 3

|table|heading|
|one|two|
|three|four|

};

my $html = markdown_to_html($markdown);
is($html, q|<div><h1>header 1</h1><h2>header 2</h2><h3>header 3</h3></div><div><table><tr><th>table</th><th>heading</th></tr><tr><td>three</td><td>four</td></tr></table></div>|);

my $markdown = q|
1. one
2. two
3. three
|;

is(markdown_to_html($markdown), q|<div><ol><li>one</li><li>two</li><li>three</li></ol></div>|);

my $markdown = q|
- one
- two
- three
|;
is(markdown_to_html($markdown), q|<div><ul><li>one</li><li>two</li><li>three</li></ul></div>|);

done_testing();

