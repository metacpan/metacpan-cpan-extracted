#!/usr/bin/env perl
#
use 5.006;
use strict;
use warnings FATAL => 'all';

use Test::More;
use DateTime;
use Mojo::DOM;

use Facebook::InstantArticle;
use Facebook::InstantArticle::Slideshow;

my $now = DateTime->now;

my $ia = Facebook::InstantArticle->new(
    language  => 'en',
    url       => 'http://www.example.com/2016/08/17/some-article',
    title     => 'Some title',
    subtitle  => 'Usually the description/ingress of the article.',
    kicker    => 'Nobody needs a kicker, but...',
    published => "$now",
    modified  => "$now",
);

$ia->add_lead_asset_image(
    source  => 'http://www.example.com/lead_image.png',
    caption => 'Lead asset!',
);

$ia->add_author(
    name => 'Tore Aursand',
);

my $slideshow = Facebook::InstantArticle::Slideshow->new;

$slideshow->add_image(
    source  => 'http://www.example.com/image01.png',
    caption => 'Image #1',
);

$ia->add_slideshow( $slideshow );

$ia->add_paragraph( 'This is a paragraph...' );
$ia->add_paragraph( '...and another paragraph!' );
$ia->add_paragraph( '' );

$ia->add_video(
    source          => 'http://www.example.com/video.mpg',
    enable_comments => 1,
    enable_likes    => 1,
    presentation    => 'aspect-fit',
);

$ia->add_list(
    elements => [ 'Item 1', 'Item 2', 'Item 3' ],
);

$ia->add_blockquote( 'Blocked out!' );

$ia->add_embed(
    source => 'http://www.example.com/embed.js',
);

$ia->add_map(
    latitude  => 56.1341342,
    longitude => 23.253474,
);

$ia->add_credit( 'Tore Aursand' );
$ia->add_copyright( 'Tore Aursand' );

my $dom = Mojo::DOM->new( $ia->to_string );

is( $dom->at('html')->attr('lang'), 'en', 'HTML language is OK' );
is( $dom->at('html')->attr('prefix'), 'op:http://media.facebook.com/op#', 'HTML prefix is OK' );
is( $dom->find('html > head > meta')->[0]->attr('charset'), 'utf-8', 'Meta charset is OK' );
is( $dom->find('html > head > meta')->[1]->attr('property'), 'op:markup_version', 'Meta markup version property is OK' );
is( $dom->find('html > head > meta')->[1]->attr('version'), 'v1.0', 'Meta markup version value is OK' );
is( $dom->at('html > head > link')->attr('href'), 'http://www.example.com/2016/08/17/some-article', 'Canonical URL is OK' );
is( $dom->find( 'article > p' )->size, 2, 'Number of paragraphs is OK' );

$dom = $dom->at( 'html > body > article' );

is( $dom->at('header > h1')->text, 'Some title', 'Title is OK' );
is( $dom->at('header > h2')->text, 'Usually the description/ingress of the article.', 'Subtitle (ingress) is OK' );
is( $dom->at('header > h3')->text, 'Nobody needs a kicker, but...', 'Kicker is OK' );
is( $dom->find('header > time')->[0]->attr('datetime'), "$now", 'Published timestamp is OK' );
is( $dom->find('header > time')->[1]->attr('datetime'), "$now", 'Modified timestamp is OK' );
is( $dom->at('header > figure > img')->attr('src'), 'http://www.example.com/lead_image.png', 'Lead asset source is OK' );
is( $dom->at('header > figure > figcaption')->text, 'Lead asset!', 'Lead asset caption is OK' );
is( $dom->at('header > address > a')->text, 'Tore Aursand', 'Address is OK' );

done_testing;
