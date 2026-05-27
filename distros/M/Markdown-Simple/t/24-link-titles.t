use strict;
use warnings;
use Test::More;
use Markdown::Simple;

like markdown_to_html(qq|[t](http://x "the title")\n|),
    qr|<a href="http://x" title="the title">t</a>|,
    'double-quoted link title';
like markdown_to_html(qq|[t](http://x 'sq title')\n|),
    qr|<a href="http://x" title="sq title">t</a>|,
    'single-quoted link title';
like markdown_to_html(qq|![a](x.png "img title")\n|),
    qr|<img src="x\.png" alt="a" title="img title"\s*/?>|,
    'image title';

done_testing;
