use warnings;
use strict;

use utf8;
use Test::More;
use Test::Differences;

use HTML::Scrubber;
use HTML::Parser;

my $scrub = HTML::Scrubber->new(
    allow => [
        qw{ p b i area br base col colgroup embed hr img input
            link map meta object param table track source video wbr }
    ]
);
$scrub->default( undef, { '*' => 1 } );    # allow all attributes
$scrub->comment(1);

# html snippets adapted from https://developer.mozilla.org/en/docs/
# except for the <br> snippet, which is taken from the example in the
# original ticket
my %snippets = (
    "area" => '<map name="primary">
      <area shape="circle" coords="75,75,75" href="left.html" alt="Click to go Left"></area>
    </map>',
    "base" => '<base target="_blank" href="http://www.example.com/page.html"></base>',
    "br"   => '<P STYLE="font-size: 300%">
    <BLINK>"You may get to touch her<BR>
    If your gloves are sterilized<BR></BR>
    Rinse your mouth with Listerine</BR>
    Blow disinfectant in her eyes"</BLINK><BR>
    -- X-Ray Spex, <I>Germ-Free Adolescents<I>',
    "col" => '<table>
      <colgroup>
        <col span="2"></col>
      </colgroup>
    </table>',
    "embed" => '<embed type="video/quicktime" src="movie.mov" width="640" height="480"></embed>',
    "hr"    => '<p>This is the first paragraph of text.</p>
    <hr></hr>
    <p>This is the second paragraph of text.</p>',
    "img"   => '<img src="image.png" alt="alt text"></img>',
    "input" => '<input id="input1" type="text"></input>',
    "link"  => '<link href="style.css" rel="stylesheet"></link>',
    "meta"  => '<meta charset="utf-8"></meta>',
    "param" => '<object data="movie.swf" type="application/x-shockwave-flash">
      <param name="foo" value="bar"></param>
    </object>',
    "source" => '<video controls>
      <source src="foo.ogg" type="video/ogg"></source>
    </video>',
    "track" => '<video controls>
      <source src="sample.mp4" type="video/mp4">
      <track kind="captions" src="sampleCaptions.vtt" srclang="en"></track>
    </video>',
    "wbr" => '<p>word<wbr>.break<wbr>.opportunity<wbr></wbr>.</p>',
);

plan tests => scalar keys %snippets;

my %expected = (
    "area" => '<map name="primary">
      <area shape="circle" coords="75,75,75" href="left.html" alt="Click to go Left">
    </map>',
    "base" => '<base target="_blank" href="http://www.example.com/page.html">',
    "br"   => '<p style="font-size: 300%">
    "You may get to touch her<br>
    If your gloves are sterilized<br>
    Rinse your mouth with Listerine
    Blow disinfectant in her eyes"<br>
    -- X-Ray Spex, <i>Germ-Free Adolescents<i>',
    "col" => '<table>
      <colgroup>
        <col span="2">
      </colgroup>
    </table>',
    "embed" => '<embed type="video/quicktime" src="movie.mov" width="640" height="480">',
    "hr"    => '<p>This is the first paragraph of text.</p>
    <hr>
    <p>This is the second paragraph of text.</p>',
    "img"   => '<img src="image.png" alt="alt text">',
    "input" => '<input id="input1" type="text">',
    "link"  => '<link href="style.css" rel="stylesheet">',
    "meta"  => '<meta charset="utf-8">',
    "param" => '<object data="movie.swf" type="application/x-shockwave-flash">
      <param name="foo" value="bar">
    </object>',
    "source" => '<video controls>
      <source src="foo.ogg" type="video/ogg">
    </video>',
    "track" => '<video controls>
      <source src="sample.mp4" type="video/mp4">
      <track kind="captions" src="sampleCaptions.vtt" srclang="en">
    </video>',
    "wbr" => "<p>word<wbr>.break<wbr>.opportunity<wbr>.</p>",
);

for my $tag_name ( sort keys %snippets ) {
    eq_or_diff $scrub->scrub( $snippets{$tag_name} ), $expected{$tag_name}, "False ending <$tag_name> tags are removed";
}

# vim: expandtab shiftwidth=4
