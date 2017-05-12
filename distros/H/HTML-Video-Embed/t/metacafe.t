use strict;
use warnings;

use Test::More tests => 4;
use HTML::Video::Embed;

my $embeder = new HTML::Video::Embed({
    class => "test-video",
});

is( 
    $embeder->url_to_embed('http://www.metacafe.com/watch/10099000/clumsy_penguins/'),
    '<iframe src="http://www.metacafe.com/embed/10099000/" class="test-video" frameborder="0" allowfullscreen="1"></iframe>',
    'metacafe embed works'
);

is( $embeder->url_to_embed('http://www.metacafe.com/watch/"£$sdf/nuts_celebrity_mistaken_identity_craig_t_squirrel_cart/'), undef, 'invalid url');
is( $embeder->url_to_embed('http://www.metacafe.com/watch//nuts_celebrity_mistaken_identity_craig_t_squirrel_cart/'), undef, 'no video id');
is( $embeder->url_to_embed('http://www.m3tacafe.com/watch/4515418/nuts_celebrity_mistaken_identity_craig_t_squirrel_cart/'), undef, 'domain check');
