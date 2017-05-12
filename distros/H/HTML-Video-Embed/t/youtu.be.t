use strict;
use warnings;

use Test::More tests => 7;
use HTML::Video::Embed;

my $embeder = new HTML::Video::Embed({
    class => "video",
    secure  => 1,
});

is( 
    $embeder->url_to_embed('http://www.youtu.be/xExSdzkZZB0'),  
    '<iframe class="video" src="https://www.youtube-nocookie.com/embed/xExSdzkZZB0?rel=0&html5=1" frameborder="0" allowfullscreen="1"></iframe>',
    'youtube embed works'
);

is( 
    $embeder->url_to_embed('http://www.youtu.be/xExSdzkZZB0#t=01h53m22s&g=sdfsdf'),  
    '<iframe class="video" src="https://www.youtube-nocookie.com/embed/xExSdzkZZB0?rel=0&html5=1&start=6802" frameborder="0" allowfullscreen="1"></iframe>',
    'youtube embed works (with timecode fragment)'
);

is( 
    $embeder->url_to_embed('https://www.youtu.be/xExSdzkZZB0?t=3h7m2s&g=sdfsdf'),
    '<iframe class="video" src="https://www.youtube-nocookie.com/embed/xExSdzkZZB0?rel=0&html5=1&start=11222" frameborder="0" allowfullscreen="1"></iframe>',
    'youtube embed works (with timecode query)'
);

is( 
    $embeder->url_to_embed('http://www.youtu.be/xExSdzkZZB0#t=sdfdsf'),
    '<iframe class="video" src="https://www.youtube-nocookie.com/embed/xExSdzkZZB0?rel=0&html5=1" frameborder="0" allowfullscreen="1"></iframe>',
    'youtube embed works (no invalid timecode)'
);

is( $embeder->url_to_embed('http://www.youtu.be/xZB0'), undef, 'invalid id');
is( $embeder->url_to_embed('http://www.youtu.be/'), undef, 'no v=');
is( $embeder->url_to_embed('http://www.y0utu.be/xExxSdzkZZB0'), undef, 'domain check');
