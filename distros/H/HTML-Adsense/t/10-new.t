#!perl

use strict;
use warnings;

use Test::More tests => 24;

use_ok( 'HTML::Adsense' );

my ($ad);

{
	$ad = HTML::Adsense->new();
	ok($ad, 'HTML::Adsense object created');
	isa_ok($ad, 'HTML::Adsense', 'HTML::Adsense object created');
}

{
	ok(my $block = $ad->render, 'ad block rendered OK');
    like($block, qr/google_ad_client = "pub-4763368282156432"/, 'block looks good');
    like($block, qr/google_ad_width = "468"/, 'block looks good');
    like($block, qr/google_ad_height = "60"/, 'block looks good');
    like($block, qr/google_ad_format = "468x60_as"/, 'block looks good');
    like($block, qr/google_ad_type = "text"/, 'block looks good');
}

{ ## Change the format
	$ad->set_format('text 728x90');
	ok(my $block = $ad->render, 'ad block rendered OK');
    like($block, qr/google_ad_client = "pub-4763368282156432"/, 'block looks good');
    like($block, qr/google_ad_width = "728"/, 'block looks good');
    like($block, qr/google_ad_height = "90"/, 'block looks good');
    like($block, qr/google_ad_format = "728x90_as"/, 'block looks good');
    like($block, qr/google_ad_type = "text"/, 'block looks good');
}

{ ## Change the format - invalid
	$ad->set_format('perl');
	ok(my $block = $ad->render, 'ad block rendered OK');
    like($block, qr/google_ad_client = "pub-4763368282156432"/, 'block looks good');
    like($block, qr/google_ad_width = "468"/, 'block looks good');
    like($block, qr/google_ad_height = "60"/, 'block looks good');
    like($block, qr/google_ad_format = "468x60_as"/, 'block looks good');
    like($block, qr/google_ad_type = "text"/, 'block looks good');
}

{ ## Change some values
	$ad->channel(undef);
	$ad->client('pub-asdasdasdasd');
	ok(my $block = $ad->render, 'ad block rendered OK');
    like($block, qr/google_ad_client = "pub-asdasdasdasd"/, 'block looks good');
    unlike($block, qr/google_ad_channel = "1486395465"/, 'block looks good');
}
