use strict;
use warnings;

use Test::More tests => 4;
use HTML::Video::Embed;

my $embeder = new HTML::Video::Embed({
    "class" => "test-video",
});

is( $embeder->url_to_embed('http://www.funnyordie.com/videos/1ab8850305/spook-hunters'),
    '<iframe class="test-video" src="http://www.funnyordie.com/embed/1ab8850305" frameborder="0" allowfullscreen="1"></iframe>',
    'funnyordie embed works'
);

is( $embeder->url_to_embed('http://www.funnyordie.com/video/1ab8850305/spook-hunters'), undef, 'invalid url');
is( $embeder->url_to_embed('http://www.funnyordie.com/videos//spook-hunters'), undef, 'no video id');
is( $embeder->url_to_embed('http://www.funny0rdie.com/videos/1ab8850305/spook-hunters'), undef, 'domain check');
