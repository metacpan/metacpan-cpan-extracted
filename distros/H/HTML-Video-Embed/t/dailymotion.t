use strict;
use warnings;

use Test::More tests => 4;
use HTML::Video::Embed;

my $embeder = new HTML::Video::Embed({
    'class' => 'test-video',
});

is( 
    $embeder->url_to_embed('http://www.dailymotion.com/video/xbrozz_the-worst-5-things-to-say-policemen_fun'),
    '<iframe class="test-video" src="http://www.dailymotion.com/embed/video/xbrozz" frameborder="0" allowfullscreen="1"></iframe>',
    'dailymotion embed works'
);

is( $embeder->url_to_embed('http://www.dailymotion.com/videoxbrozz_the-worst-5-things-to-say-policemen_fun'), undef, 'invalid url');
is( $embeder->url_to_embed('http://www.dailymotion.com/video/_the-worst-5-things-to-say-policemen_fun'), undef, 'no video id');
is( $embeder->url_to_embed('http://www.da1lymotion.com/video/xbrozz_the-worst-5-things-to-say-policemen_fun'), undef, 'domain check');
