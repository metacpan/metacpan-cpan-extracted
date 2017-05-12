#!perl
use strict;
use Test::More tests => 20;
use_ok('HTML::TagCloud');

my $cloud = HTML::TagCloud->new;
isa_ok($cloud, 'HTML::TagCloud');

my $tags = tags();
foreach my $tag (keys %$tags) {
  my $count = $tags->{$tag};
  my $url   = "/show/$tag";
  $cloud->add($tag, $url, $count);
}

my $css = $cloud->css;
is(lines($css), 55);

my $html = $cloud->html(0);
is($html, "");

$html = $cloud->html(1);
is($html, q{<div id="htmltagcloud"><span class="tagcloud1"><a href="/show/florida">florida</a></span></div>
});

$html = $cloud->html(2);
is($html, q{<div id="htmltagcloud">
<span class="tagcloud2"><a href="/show/florida">florida</a></span>
<span class="tagcloud0"><a href="/show/tanja">tanja</a></span>
</div>});

$html = $cloud->html(5);
is(lines($html), 7);
is($html, q{<div id="htmltagcloud">
<span class="tagcloud5"><a href="/show/florida">florida</a></span>
<span class="tagcloud0"><a href="/show/fort">fort</a></span>
<span class="tagcloud1"><a href="/show/london">london</a></span>
<span class="tagcloud2"><a href="/show/madagascar">madagascar</a></span>
<span class="tagcloud3"><a href="/show/tanja">tanja</a></span>
</div>});

$html = $cloud->html_and_css(5);
is(lines($html), 63);

$html = $cloud->html(20);
is(lines($html), 22);

$html = $cloud->html;
is(lines($html), 351);

$cloud = HTML::TagCloud->new;
$cloud->add("a", "a.html", 10);
$cloud->add("b", "b.html", 10);
$cloud->add("c", "c.html", 10);

$html = $cloud->html();
is($html, q{<div id="htmltagcloud">
<span class="tagcloud3"><a href="a.html">a</a></span>
<span class="tagcloud3"><a href="b.html">b</a></span>
<span class="tagcloud3"><a href="c.html">c</a></span>
</div>});

$cloud = HTML::TagCloud->new( distinguish_adjacent_tags => 1 );
$cloud->add("a", "a.html", 10);
$cloud->add("b", "b.html", 10);
$cloud->add("c", "c.html", 10);

$css = $cloud->css;
is(lines($css), 105);

$html = $cloud->html();
is($html, q{<div id="htmltagcloud">
<span class="tagcloud3even"><a href="a.html">a</a></span>
<span class="tagcloud3odd"><a href="b.html">b</a></span>
<span class="tagcloud3even"><a href="c.html">c</a></span>
</div>});

$cloud = HTML::TagCloud->new;
$cloud->add_static("a", 10);

$html = $cloud->html();
is ($html, q{<div id="htmltagcloud"><span class="tagcloud1">a</span></div>
});

$cloud = HTML::TagCloud->new( distinguish_adjacent_tags => 1 );
$cloud->add_static("a", 10);

$html = $cloud->html();
is ($html, q{<div id="htmltagcloud"><span class="tagcloud1even">a</span></div>
});

$cloud = HTML::TagCloud->new;
$cloud->add_static("a", 10);
$cloud->add_static("b", 10);
$cloud->add_static("c", 10);

$html = $cloud->html();
is($html, q{<div id="htmltagcloud">
<span class="tagcloud3">a</span>
<span class="tagcloud3">b</span>
<span class="tagcloud3">c</span>
</div>});

$cloud = HTML::TagCloud->new( distinguish_adjacent_tags => 1 );
$cloud->add_static("a", 10);
$cloud->add_static("b", 10);
$cloud->add_static("c", 10);

$html = $cloud->html();
is($html, q{<div id="htmltagcloud">
<span class="tagcloud3even">a</span>
<span class="tagcloud3odd">b</span>
<span class="tagcloud3even">c</span>
</div>});

$cloud = HTML::TagCloud->new;
$cloud->add("a", "a.html", 10);
$cloud->add_static("b", 10);
$cloud->add("c", "c.html", 10);

$html = $cloud->html();
is($html, q{<div id="htmltagcloud">
<span class="tagcloud3"><a href="a.html">a</a></span>
<span class="tagcloud3">b</span>
<span class="tagcloud3"><a href="c.html">c</a></span>
</div>});

$cloud = HTML::TagCloud->new( distinguish_adjacent_tags => 1 );
$cloud->add("a", "a.html", 10);
$cloud->add_static("b", 10);
$cloud->add("c", "c.html", 10);

$html = $cloud->html();
is($html, q{<div id="htmltagcloud">
<span class="tagcloud3even"><a href="a.html">a</a></span>
<span class="tagcloud3odd">b</span>
<span class="tagcloud3even"><a href="c.html">c</a></span>
</div>});

sub tags {
  return {
    'laptop'                 => 11,
    'diane'                  => 10,
    'grand central station'  => 2,
    'fog'                    => 4,
    'amsterdam'              => 10,
    'floor'                  => 1,
    'mai kai'                => 3,
    'glow stick'             => 2,
    'london'                 => 197,
    'albert hall'            => 4,
    'night'                  => 17,
    'victoria peak tram'     => 3,
    'squirrel'               => 6,
    'teddy bear'             => 3,
    'orange'                 => 30,
    'hyde park'              => 4,
    'fort'                   => 165,
    'ray'                    => 8,
    'light'                  => 23,
    'disney world'           => 10,
    'tanja orme'             => 51,
    'pool table'             => 4,
    'wedding dress'          => 7,
    'frasier'                => 2,
    'village'                => 6,
    'alex'                   => 11,
    'soup'                   => 1,
    'tom insam'              => 2,
    'dock'                   => 2,
    'church'                 => 4,
    'natural history museum' => 4,
    'lucy'                   => 1,
    'dimsum'                 => 2,
    'sea horse'              => 2,
    'ice skating'            => 1,
    'lauderdale'             => 165,
    'andrews'                => 53,
    'tate'                   => 13,
    'lan tau'                => 16,
    'dummy'                  => 3,
    'clotilde lafont'        => 2,
    'waffle'                 => 1,
    'harbour'                => 23,
    'micra'                  => 2,
    'fondue'                 => 1,
    'cecile lafont'          => 1,
    'kitten'                 => 4,
    'na'                     => 34,
    'river thames'           => 15,
    'rain'                   => 2,
    'mustang'                => 2,
    'chair'                  => 1,
    'verbier'                => 139,
    'nick'                   => 5,
    'plate'                  => 1,
    'tank'                   => 5,
    'cable car'              => 4,
    'chinese'                => 1,
    'red rose'               => 2,
    'red'                    => 18,
    'kathy'                  => 1,
    'hualien'                => 9,
    'salt'                   => 1,
    'elephant'               => 1,
    'jessica sergeant'       => 2,
    'swimming pool'          => 20,
    'pond'                   => 1,
    'malin bergman'          => 2,
    'palm tree'              => 9,
    'moon'                   => 8,
    'agathe lafont'          => 3,
    'chelsea'                => 21,
    'fotango'                => 31,
    'escalator'              => 3,
    'ron'                    => 1,
    'tea cup'                => 1,
    'james duncan'           => 6,
    'pyramid'                => 5,
    'whiteg'                 => 3,
    'sky'                    => 51,
    'goose'                  => 7,
    'louvre'                 => 6,
    'car'                    => 5,
    'candle'                 => 3,
    'water'                  => 4,
    'bridge'                 => 11,
    'goddaughter'            => 11,
    'fisherman'              => 3,
    'clock'                  => 1,
    'eye'                    => 48,
    'bamboo'                 => 4,
    'moorhen'                => 2,
    'stairs'                 => 3,
    'wedding cake'           => 5,
    'swan'                   => 21,
    'melissa'                => 4,
    'mitre'                  => 1,
    'tree'                   => 89,
    'miyagawa'               => 2,
    'zendo'                  => 2,
    'erena'                  => 35,
    'polo'                   => 29,
    'poker'                  => 1,
    'piano sheet'            => 2,
    'waterloo'               => 4,
    'sign'                   => 25,
    'eggs'                   => 3,
    'arm'                    => 1,
    'stars'                  => 10,
    'corridor'               => 1,
    'jesse'                  => 3,
    'donnie'                 => 7,
    'shrimp'                 => 4,
    'terry'                  => 2,
    'kennedy space center'   => 7,
    'black'                  => 1,
    'crow'                   => 2,
    'eurostar'               => 4,
    'anton'                  => 1,
    'bottle'                 => 3,
    'wood'                   => 1,
    'autrijus'               => 4,
    'sleeping bag'           => 6,
    'jenny mather'           => 2,
    'cheese'                 => 2,
    'blurry'                 => 11,
    'sunset'                 => 46,
    'lobster'                => 1,
    'birthday'               => 4,
    'smoke'                  => 1,
    'wedding'                => 35,
    'jamie freeman'          => 2,
    'limousine'              => 2,
    'pottery'                => 3,
    'fish'                   => 21,
    'red carpet'             => 2,
    'arthur bergman'         => 7,
    'bubbles'                => 1,
    'eiffel tower'           => 10,
    'kerry lapworth'         => 2,
    'mud'                    => 2,
    'pete berlin'            => 3,
    'penguin'                => 5,
    'simon wistow'           => 2,
    'new'                    => 23,
    'flower'                 => 58,
    'balloon'                => 1,
    'drink'                  => 21,
    'sand'                   => 6,
    'centre pompidou'        => 2,
    'john'                   => 2,
    'jane'                   => 9,
    'show'                   => 21,
    'helmet'                 => 1,
    'restaurant'             => 2,
    'ring'                   => 1,
    'stag'                   => 32,
    'greg'                   => 3,
    'york'                   => 23,
    'thorpe park'            => 15,
    'bike'                   => 1,
    'pauline brocard'        => 106,
    'shoes'                  => 3,
    'cute'                   => 1,
    'canal'                  => 1,
    'wheel'                  => 1,
    'modern'                 => 13,
    'hot spring'             => 2,
    'band'                   => 1,
    'ingy'                   => 7,
    'bungalow'               => 14,
    'gun'                    => 1,
    'oxygen'                 => 1,
    'gold'                   => 1,
    'rollercoaster'          => 13,
    'maude lafont'           => 1,
    'gary'                   => 5,
    'charlie'                => 2,
    'portuguese man of war'  => 1,
    'mountain'               => 33,
    'elf'                    => 1,
    'mark fowler'            => 11,
    'tram'                   => 1,
    'skiing'                 => 31,
    'plane'                  => 4,
    'menu'                   => 3,
    'scuba'                  => 18,
    'albert memorial'        => 11,
    'big buddha'             => 16,
    'van'                    => 1,
    'george'                 => 1,
    'ripples'                => 4,
    'spider'                 => 1,
    'rose'                   => 4,
    'river'                  => 11,
    'rocking chair'          => 1,
    'mtr'                    => 3,
    'lighthouse'             => 6,
    'foot'                   => 1,
    'chris robertson'        => 2,
    'round pond'             => 21,
    'queen'                  => 9,
    'hot pot'                => 1,
    'pen'                    => 1,
    'chick'                  => 5,
    'garlic'                 => 4,
    'greg jameson'           => 18,
    'sun'                    => 20,
    'door'                   => 1,
    'james lewis'            => 4,
    'portugal'               => 9,
    'crab'                   => 5,
    'box'                    => 1,
    'helicopter'             => 2,
    'parliament'             => 8,
    'purple'                 => 11,
    'bath'                   => 35,
    'scott'                  => 2,
    'pub'                    => 8,
    'yapc'                   => 57,
    'pole'                   => 1,
    'painter'                => 2,
    'perl'                   => 1,
    'food'                   => 13,
    'dog'                    => 4,
    'carp'                   => 3,
    'splash'                 => 2,
    'hcchien'                => 2,
    'taiwan'                 => 92,
    'flag'                   => 1,
    'horse'                  => 2,
    'fowler'                 => 35,
    'manatee'                => 1,
    'weir'                   => 2,
    'firework'               => 8,
    'alligator'              => 10,
    'st john'                => 13,
    'sunrise'                => 1,
    'clkao'                  => 3,
    'chicken'                => 6,
    'head'                   => 1,
    'hilary'                 => 2,
    'trampoline'             => 8,
    'shane'                  => 7,
    'picnic'                 => 3,
    'aquarium'               => 28,
    'sushi'                  => 20,
    'pam'                    => 7,
    'building'               => 14,
    'clouds'                 => 6,
    'pink'                   => 18,
    'bus'                    => 4,
    'oliver'                 => 2,
    'tom'                    => 1,
    'fire'                   => 15,
    'boat'                   => 41,
    'clown fish'             => 4,
    'killer whale'           => 8,
    'danielle'               => 4,
    'paul mison'             => 1,
    'bbq'                    => 3,
    'cash'                   => 1,
    'bluebells'              => 5,
    'richard clamp'          => 1,
    'turtle'                 => 7,
    'paul'                   => 4,
    'chips'                  => 1,
    'lizard'                 => 8,
    'leon brocard'           => 70,
    'table'                  => 4,
    'victoria peak'          => 10,
    'bird'                   => 6,
    'green'                  => 5,
    'mark'                   => 36,
    'baobab tree'            => 12,
    'ball'                   => 3,
    'statue'                 => 11,
    'yellow'                 => 13,
    'francois brocard'       => 32,
    'grass'                  => 19,
    'leo lapworth'           => 2,
    'farm'                   => 53,
    'madagascar'             => 224,
    'lake'                   => 14,
    'hot chocolate'          => 2,
    'wine'                   => 6,
    'train'                  => 7,
    'andrea hummer'          => 8,
    'catherine'              => 2,
    'tanja'                  => 248,
    'star ferry'             => 5,
    'hong'                   => 79,
    'beach'                  => 88,
    'notre dame'             => 3,
    'books'                  => 1,
    'underground'            => 1,
    'reflection'             => 36,
    'pony'                   => 5,
    'steve'                  => 6,
    'pool'                   => 1,
    'jason'                  => 4,
    'hair'                   => 1,
    'house'                  => 7,
    'karen'                  => 2,
    'sea'                    => 123,
    'noodles'                => 1,
    'rainbow'                => 4,
    'florida'                => 282,
    'fountain'               => 4,
    'croissant'              => 1,
    'fresnel lens'           => 3,
    'glass'                  => 2,
    'bahamas'                => 55,
    'bed'                    => 3,
    'post box'               => 3,
    'island'                 => 13,
    'agi'                    => 1,
    'roast suckling pig'     => 7,
    'windsor'                => 10,
    'kiss'                   => 1,
    'rock'                   => 8,
    'paris'                  => 70,
    'erena fowler'           => 8,
    'shadow'                 => 13,
    'ceiling'                => 1,
    'kong'                   => 79,
    'duck'                   => 10,
    'sam'                    => 11,
    'port'                   => 1,
    'river seine'            => 12,
    'class'                  => 1,
    'croquet'                => 3,
    'katrien janin'          => 6,
    'roof'                   => 1,
    'billingsgate'           => 6,
    'blue'                   => 29,
    'cake'                   => 4,
    'psp'                    => 2,
    'grandmother'            => 2,
    'alex monney'            => 4,
    'kensington gardens'     => 85,
    'hammock'                => 14,
    'snow'                   => 84,
    'taipei'                 => 36,
    'mike robertson'         => 1,
    'book'                   => 1,
    'martine brocard'        => 38,
    'road'                   => 3,
    'ribbon'                 => 1
  };
}

sub lines {
  my $text = shift;
  my @lines = split "\n", $text;
  return scalar(@lines);
}
