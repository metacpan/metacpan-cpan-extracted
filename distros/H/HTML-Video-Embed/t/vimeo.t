use strict;
use warnings;

use Test::More tests => 5;
use HTML::Video::Embed;

my $embeder = new HTML::Video::Embed({
    class=> "test-video",
});

is( 
    $embeder->url_to_embed('http://vimeo.com/12279924'),
    '<iframe class="test-video" src="http://player.vimeo.com/video/12279924" frameborder="0" allowfullscreen="1"></iframe>',
    'vimeo embed works (normal url)'
);

is( 
    $embeder->url_to_embed('http://vimeo.com/m/12279924'),
    '<iframe class="test-video" src="http://player.vimeo.com/video/12279924" frameborder="0" allowfullscreen="1"></iframe>',
    'vimeo embed works (mobile url)'
);

is( $embeder->url_to_embed('http://vimeo.com/fhfhgfhgfh'), undef, 'invalid url');
is( $embeder->url_to_embed('http://vimeo.com/'), undef, 'no video id');
is( $embeder->url_to_embed('http://v1meo.com/12279924'), undef, 'domain check');
