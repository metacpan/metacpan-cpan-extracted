use strict;
use warnings;

use Test::More tests => 4;
use HTML::Video::Embed;

my $embeder = new HTML::Video::Embed({
    "class" => "test-video",
});

is( $embeder->url_to_embed('http://www.ebaumsworld.com/video/watch/81510426/'),
    '<iframe class="test-video" src="http://www.ebaumsworld.com/media/embed/81510426" frameborder="0" allowfullscreen="1"></iframe>',
    'ebaumsworld embed works'
);

is( $embeder->url_to_embed('http://www.ebaumsworld.com/video/watch/wibble/'), undef, 'invalid video');
is( $embeder->url_to_embed('http://www.ebaumsworld.com/video/watch/'), undef, 'no video');
is( $embeder->url_to_embed('http://www.eboumsworld.com/video/watch/81510426/'), undef, 'domain check');
