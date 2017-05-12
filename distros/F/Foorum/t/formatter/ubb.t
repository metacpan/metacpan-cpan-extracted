#!/usr/bin/perl

use strict;
use warnings;
use Test::More 'no_plan';    # tests => 6;

use Foorum::Formatter qw/filter_format/;

my $text = <<TEXT;
 :inlove: [b]Test[/b] [url=http://fayland.org/]Personal Homepage[/url] [size=14]size[/size]
[font=Arial]Arial Text[/font] [align=center]Text[/align]
TEXT

my $html = filter_format( $text, { format => 'ubb' } );

like( $html, qr/inlove.gif/,               'emot convert OK' );
like( $html, qr/\<a href/,                 '[url] convert OK' );
like( $html, qr/font-weight\:bold/,        '[b] convert OK' );
like( $html, qr/font-size\:14pt/,          '[size] OK' );
like( $html, qr/font-family\s*\:\s*Arial/, '[font] OK' );
like( $html, qr/text-align:\s*center/,     '[align] OK' );

#diag($html);

# check http://code.google.com/p/foorum/issues/detail?id=36
$text = <<TEXT;
[url=http://search.cpan.org/perldoc?CatalystX::Foorum]CatalystX::Foorum[/url]
TEXT
$html = filter_format( $text, { format => 'ubb' } );
is( $html,
    qq~<a href="http://search.cpan.org/perldoc?CatalystX::Foorum">CatalystX::Foorum</a><br />\n~,
    'CPAN URL OK'
);

# test breakline
$html = filter_format( "a\nb\n", { format => 'ubb' } );
is( $html, "a<br />\nb<br />\n", 'breakline OK' );

# test video|flash
$text = <<TEXT;
[video]http://www.youtube.com/v/vCErwxUYEbY&rel=1[/video]
[flash]http://fayland.org/king.swf[/flash]
[music]http://fayland.org/love.mp3[/music]
TEXT
$html = filter_format( $text, { format => 'ubb' } );
is( $html,
    qq~<div><embed src="http://www.youtube.com/v/vCErwxUYEbY&rel=1" type="application/x-shockwave-flash" allowfullscreen="true" width="425" height="344"></embed></div><br />
<div class='bbcode_flash'><embed src="http://fayland.org/king.swf" type="application/x-shockwave-flash"  width="425" height="344"></embed></div><br />
<div><embed name="rplayer" type="audio/x-pn-realaudio-plugin" src="http://fayland.org/love.mp3" 
controls="StatusBar,ControlPanel" width='320' height='70' border='0' autostart='flase'></embed></div><br />
~,
    '[video] [flash] [music] OK'
);

is( filter_format(
        '[color=blue" onmouseover="alert:XSS"]test[/color]',
        { format => 'ubb' }
    ),
    '<span style="color:blue">test</span>',
    'stripscripts enabled'
);

1;
