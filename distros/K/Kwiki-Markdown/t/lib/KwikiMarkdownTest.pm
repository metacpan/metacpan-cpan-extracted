package KwikiMarkdownTest;
use Test::Base -Base;

use Kwiki::Markdown;

package KwikiMarkdownTest::Filter;
use Test::Base::Filter -base;

sub markdown_filter {
    return Kwiki::Markdown->text_to_html(shift);
}
