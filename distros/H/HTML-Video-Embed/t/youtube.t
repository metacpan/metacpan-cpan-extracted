use strict;
use warnings;

use Test::More tests => 9;
use HTML::Video::Embed;

my $embeder = new HTML::Video::Embed({
    class => "test-video",
});

is( 
    $embeder->url_to_embed('http://www.youtube.com/watch?v=xExSdzkZZB0'),  
    '<iframe class="test-video" src="http://www.youtube-nocookie.com/embed/xExSdzkZZB0?rel=0&html5=1" frameborder="0" allowfullscreen="1"></iframe>',
    'youtube embed works'
);

is( 
    $embeder->url_to_embed('http://www.youtube.com/watch?v=xExSdzkZZB0#t=01h53m22s'),  
    '<iframe class="test-video" src="http://www.youtube-nocookie.com/embed/xExSdzkZZB0?rel=0&html5=1&start=6802" frameborder="0" allowfullscreen="1"></iframe>',
    'youtube embed works (with timecode fragment)'
);

is( 
    $embeder->url_to_embed('http://www.youtube.com/watch?v=xExSdzkZZB0&t=02h26m31s'),  
    '<iframe class="test-video" src="http://www.youtube-nocookie.com/embed/xExSdzkZZB0?rel=0&html5=1&start=8791" frameborder="0" allowfullscreen="1"></iframe>',
    'youtube embed works (with timecode query)'
);

is( 
    $embeder->url_to_embed('http://www.youtube.com/watch?v=xExSdzkZZB0#t=22s'),  
    '<iframe class="test-video" src="http://www.youtube-nocookie.com/embed/xExSdzkZZB0?rel=0&html5=1&start=22" frameborder="0" allowfullscreen="1"></iframe>',
    'youtube embed works (with timecode), just seconds'
);

is( 
    $embeder->url_to_embed('http://www.youtube.com/watch?v=xExSdzkZZB0#t=2m3s'),  
    '<iframe class="test-video" src="http://www.youtube-nocookie.com/embed/xExSdzkZZB0?rel=0&html5=1&start=123" frameborder="0" allowfullscreen="1"></iframe>',
    'youtube embed works (with timecode), single digits'
);

is( 
    $embeder->url_to_embed('http://www.youtube.com/watch?v=xExSdzkZZB0#t=sdfdsf'),  
    '<iframe class="test-video" src="http://www.youtube-nocookie.com/embed/xExSdzkZZB0?rel=0&html5=1" frameborder="0" allowfullscreen="1"></iframe>',
    'youtube embed works (invalid timecode removed)'
);

is( $embeder->url_to_embed('http://www.youtube.com/watch?v=xExkZZB0'), undef, 'invalid v=');
is( $embeder->url_to_embed('http://www.youtube.com/watch?h=xExxSdzkZZB0'), undef, 'no v=');
is( $embeder->url_to_embed('http://www.y0utube.com/watch?h=xExxSdzkZZB0'), undef, 'domain check');
