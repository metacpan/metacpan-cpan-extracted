use Test::More;

use Markdown::Simple;

my $markdown = q{
__bold__ _italic_

* __bold__
* _italic_
**no**
};

my $html = strip_markdown($markdown);

is($html, "\nbold italic\n\n* bold\n* italic\nno\n");

my $markdown = q{
# head
# head2
# head3

|one|**two**|three|
|---|-------|-----|
|one|two|__three__|

∂ƒøøø
};

$html = strip_markdown($markdown);

is($html, "\nhead\nhead2\nhead3\n\n|one|two|three|\n|---|-------|-----|\n|one|two|three|\n\n∂ƒøøø\n");




done_testing();
