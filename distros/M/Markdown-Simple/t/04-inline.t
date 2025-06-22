use Test::More;

use Markdown::Simple;

my $markdown = q|
**bold** *italic* ~~strike~~

* one **bold**
* two *italic*
* three ~~strike~~
|;

my $html = markdown_to_html($markdown);
is($html, '<div><strong>bold</strong> <em>italic</em> <del>strike</del></div><div><ul><li>one <strong>bold</strong></li><li>two <em>italic</em></li><li>three <del>strike</del></li></ul></div>');

$markdown = q|
**bold** *italic* ~~strike~~

1. one **bold**
2. two *italic*
3. three ~~strike~~
|;

$html = markdown_to_html($markdown);
use Data::Dumper;
is($html, '<div><strong>bold</strong> <em>italic</em> <del>strike</del></div><div><ol><li>one <strong>bold</strong></li><li>two <em>italic</em></li><li>three <del>strike</del></li></ol></div>');


$markdown = q{
**bold** *italic* ~~strike~~

|table|one|two|
|-----|---|---|
|one **bold**|two *italic*|three ~~strike~~|
};

$html = markdown_to_html($markdown);

is($html, '<div><strong>bold</strong> <em>italic</em> <del>strike</del></div><div><table><tr><th>table</th><th>one</th><th>two</th></tr><tr><td>one <strong>bold</strong></td><td>two <em>italic</em></td><td>three <del>strike</del></td></tr></table></div>');


done_testing();
