use Test::More;

use Markdown::Simple;

my $markdown = q{
__bold__ _italic_

* __bold__
* _italic_
**no**
};

my $html = markdown_to_html($markdown);

is($html, '<div><strong>bold</strong> <em>italic</em></div><div><ul><li><strong>bold</strong></li><li><em>italic</em></li></ul><strong>no</strong></div>');

my $markdown = q{
__bold__ _italic_

* __bold__
* _italic_
*no*
};

my $html = markdown_to_html($markdown);

is($html, '<div><strong>bold</strong> <em>italic</em></div><div><ul><li><strong>bold</strong></li><li><em>italic</em></li></ul><em>no</em></div>');


done_testing();
