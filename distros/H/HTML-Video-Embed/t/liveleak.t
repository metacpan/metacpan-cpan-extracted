use strict;
use warnings;

use Test::More tests => 6;
use HTML::Video::Embed;

my $embeder = new HTML::Video::Embed({
    class => "test-video",
});

is( $embeder->url_to_embed('http://www.liveleak.com/view?i=ffc_1272800490'),
    '<iframe class="test-video" src="http://www.liveleak.com/ll_embed?i=ffc_1272800490" frameborder="0" allowfullscreen="1"></iframe>',
    'liveleak embed works'
);

is( $embeder->url_to_embed('http://www.liveleak.com/ll_embed?f=52ae730e7226'),
    '<iframe class="test-video" src="http://www.liveleak.com/ll_embed?f=52ae730e7226" frameborder="0" allowfullscreen="1"></iframe>',
    'liveleak embed works, embed url (f instead of i)'
);

is( $embeder->url_to_embed('http://www.liveleak.com/view?i=ffc_12728770049090'), undef, 'invalid i=');
is( $embeder->url_to_embed('http://www.liveleak.com/view?v=ffc_12728004900'), undef, 'no i=');
is( $embeder->url_to_embed('http://www.l1veleak.com/view?i=ffc_12728004900'), undef, 'domain check');

{
    my $embeder = new HTML::Video::Embed({
        class => "test-video",
        secure  => 1,
    });

    is $embeder->url_to_embed('http://www.liveleak.com/view?i=ffc_1272800490'), undef, 'secure mode returns undef';
}
