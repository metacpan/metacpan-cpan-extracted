use strict;
use warnings;

use Test::More tests => 7;
use HTML::Video::Embed;

my $embeder = new HTML::Video::Embed({
    'class' => "test-video",
});

is( 
    $embeder->url_to_embed('http://www.collegehumor.com/video:1930495'),
    '<iframe class="test-video" src="http://www.collegehumor.com/e/1930495" frameborder="0" allowfullscreen="1"></iframe>',
    'collegehumor old url embed works'
);

is( 
    $embeder->url_to_embed('http://www.collegehumor.com/video/1930495/disney-princess-spring-breakers-trailer'),
    '<iframe class="test-video" src="http://www.collegehumor.com/e/1930495" frameborder="0" allowfullscreen="1"></iframe>',
    'collegehumor new url embed works'
);

is( 
    $embeder->url_to_embed('http://www.collegehumor.com/video/0/some-random-video'),
    '<iframe class="test-video" src="http://www.collegehumor.com/e/0" frameborder="0" allowfullscreen="1"></iframe>',
    'collegehumor video id 0 works'
);

is( $embeder->url_to_embed('http://www.collegehumor.com/vdeo:1930495'), undef, 'invalid misspelled url');
is( $embeder->url_to_embed('http://www.collegehumor.com/vdeo:sdfsdfsdf'), undef, 'invalid video id');
is( $embeder->url_to_embed('http://www.collegehumor.com/video;1930495'), undef, 'invalid video seperator');
is( $embeder->url_to_embed('http://www.c0llegehumor.com/video/1930495'), undef, 'domain check');
