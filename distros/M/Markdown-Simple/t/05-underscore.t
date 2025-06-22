use Test::More;

use Markdown::Simple;

my $markdown = q{
__bold__ _italic_

- __bold__
- _italic_
};

my $html = markdown_to_html($markdown);

is($html, '<div><strong>bold</strong> <em>italic</em></div><div><ul><li><strong>bold</strong></li><li><em>italic</em></li></ul></div>');

done_testing();
