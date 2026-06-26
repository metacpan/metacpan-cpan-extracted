use strict;
use warnings;

use lib '../lib';

use HTML::Composer;
use HTML::Composer::Unsafe;
use Test::More;

my $unsafe = HTML::Composer::Unsafe->new('<b>raw</b>');
ok $unsafe, 'Unsafe object is truthy';
isa_ok $unsafe, 'HTML::Composer::Unsafe';
is "$unsafe", '<b>raw</b>', 'Stringification returns original string';

my $h       = HTML::Composer->new;
my $unsafe2 = $h->unsafe('<script>alert(1)</script>');
isa_ok $unsafe2, 'HTML::Composer::Unsafe';
is "$unsafe2", '<script>alert(1)</script>',
  'Unsafe via $h->unsafe stringifies correctly';

my $html = $h->html(
    [
        head => [
            title  => ['Test'],
            script => [ $h->unsafe('var x = 1 < 2 && 3 > 0;') ],
        ],
        body => [
            div => ['content'],
        ]
    ]
);

like $html, qr/var x = 1 < 2 && 3 > 0;/,
  'Unsafe content is not HTML-escaped in rendered output';

my $escaped_html = $h->html(
    [
        head => [ title => ['Test'] ],
        body => [ div   => ['<b>raw text</b>'] ],
    ]
);
like $escaped_html, qr/&lt;b&gt;raw text&lt;\/b&gt;/,
  'Regular text IS HTML-escaped';

done_testing;
