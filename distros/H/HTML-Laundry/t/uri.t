use strict;
use warnings;
binmode Test::More->builder->output, ":utf8"; 
binmode Test::More->builder->failure_output, ":utf8"; 

use Test::More tests => 36;

require_ok('HTML::Laundry');

my $l = HTML::Laundry->new({ notidy => 1 });

note 'Clean URLs';

is( $l->clean(q{<IMG SRC="http://example.com/otter.png">}), q{<img src="http://example.com/otter.png" />}, 'Legit <img> not affected');
is( $l->clean(q{<IMG SRC="mypath/otter.png">}), q{<img src="mypath/otter.png" />}, 'Legit <img> with relative URL not affected');
is( $l->clean(q{<IMG SRC=file:///home/smoot/of_ute.jpg>}), q{<img />}, 'Legitimate URL with unsupported scheme is cleaned away');
is( $l->clean(q{<IMG SRC=ftp://example.com/otter.png>}), q{<img src="ftp://example.com/otter.png" />}, 'Legitimate URL with non-http but supported scheme is passed through under default rules');
is( $l->clean(q{<IMG SRC="http://example.com:80/otter.png">}), q{<img src="http://example.com/otter.png" />}, 'Canonical scheme port number is stripped');
is( $l->clean(q{<IMG SRC="HTTP://EXAMPLE.COM/FOO/OTTER.pNg">}), q{<img src="http://example.com/FOO/OTTER.pNg" />}, 'Scheme and domain name lowercased; file path is not');
is( $l->clean(q{<IMG SRC="http://example.com:8080/otter.png">}), q{<img src="http://example.com:8080/otter.png" />}, 'Non-canonical scheme port number is preserved');
is( $l->clean(q{<IMG SRC="http://xyzzy/otter.png">}), q{<img src="http://xyzzy/otter.png" />}, 'Bad domain name is preserved');
is( $l->clean(q{<IMG SRC="http://ex ample.com/otter.png">}), q{<img src="http://ex%20ample.com/otter.png" />}, 'Spaces are URI encoded in hostname');
is( $l->clean(q{<IMG SRC="http://example.com/otter baby.png">}), q{<img src="http://example.com/otter%20baby.png" />}, 'Spaces are URI encoded in path');
is( $l->clean(q{<IMG SRC="http://example.com/otter;/?:@&=+$,[],.png">}), q{<img src="http://example.com/otter;/?:@&=+$,[],.png" />}, 'Restricted characters left untouched in path');
is( $l->clean(q{<A HREF="http://www.google.com/search?hl=en&source=hp&q=japh&aq=f&oq=&aqi=">}), q{<a href="http://www.google.com/search?hl=en&source=hp&q=japh&aq=f&oq=&aqi=">}, 'Query string left untouched');
is( $l->clean(q{<A HREF="http://foo&bar?@example.com/">user</a>}), q{<a href="http://foo&bar?@example.com/">user</a>}, 'User-info left untouched');
is( $l->clean(q{<A HREF="http://www.google.com/search?hl=en&source=hp&q=japh&aq=f&oq=&aqi=">}), q{<a href="http://www.google.com/search?hl=en&source=hp&q=japh&aq=f&oq=&aqi=">}, 'Query string left untouched');
is( $l->clean(q{<A HREF="http://example.com/index/#javascript:foo?bar&">info</a>}), q{<a href="http://example.com/index/#javascript:foo?bar&">info</a>}, 'Fragment left untouched');

note 'UTF-8 handling in URLs';

# Arrow used in tinyarro.ws is %E2%9E%A1 / \x{27a1}
is( $l->clean(q{<A  HREF="http://ja.wikipedia.org/wiki/黒澤明"></a>}), q{<a href="http://ja.wikipedia.org/wiki/%E9%BB%92%E6%BE%A4%E6%98%8E"></a>}, 'UTF-8 path is escaped');
my $heavy = $l->clean(q{<a href="http://➡.ws/Լ䘅">JAPH</a>});
ok( ( $heavy eq qq{<a href="http://\x{27a1}.ws/%D4%BC%E4%98%85">JAPH</a>} or $heavy eq q{<a href="http://xn--4ag7q.ws/%D4%BC%E4%98%85">JAPH</a>}), 'UTF-8-heavy URL is passed through, returned with UTF-8 domain and escaped path');
$heavy = $l->clean(q{<a href="http://➡.ws:80/Լ䘅">JAPH</a>});
ok( ( $heavy eq qq{<a href="http://\x{27a1}.ws/%D4%BC%E4%98%85">JAPH</a>} or $heavy eq q{<a href="http://xn--4ag7q.ws/%D4%BC%E4%98%85">JAPH</a>}), 'UTF-8-heavy URL is canonical-ized');
TODO: {
    local $TODO = q{Haven't added in use of Net::LibIDN or Net::DNS::IDNA yet};
    is( $l->clean(q{<A  HREF="http://π.cr.yp.to/" />}), q{<a href="http://xn--1xa.cr.yp.to/"></a>}, '<a href> with UTF-8 domain name is Punycode escaped');
}

note 'Begin nastiness';
# based on http://ha.ckers.org/xss.html#XSScalc
is( $l->clean(q{<IMG SRC="javascript:alert('XSS');">}), q{<img />}, 'Unobfuscated <img> is neutralized');
is( $l->clean(q{<IMG SRC=javascript:alert('XSS')>}), q{<img />}, '<img> with no quotes or semicolon is neutralized');
is( $l->clean(q{<IMG SRC=JaVaScRiPt:alert('XSS')>}), q{<img />}, '<img> with case-varying is neutralized');
is( $l->clean(q{<IMG SRC=javascript:alert(&quot;XSS&quot;)>}), q{<img />}, '<img> with HTML entities is neutralized');
is( $l->clean(q{<IMG SRC=`javascript:alert("RSnake says, 'XSS'")`>}), q{<img />}, '<img> with grave accents is neutralized');
is( $l->clean(q{<IMG """><SCRIPT>alert("XSS")</SCRIPT>">}), q{<img />&quot;&gt;}, 'malformed <img> with scripts is neutralized');
is( $l->clean(q{<IMG SRC=javascript:alert(String.fromCharCode(88,83,83))>}), q{<img />}, '<img> with fromCharCode is neutralized');
is( $l->clean(q{<IMG SRC=&#106;&#97;&#118;&#97;&#115;&#99;&#114;&#105;&#112;&#116;&#58;&#97;&#108;&#101;&#114;&#116;&#40;&#39;&#88;&#83;&#83;&#39;&#41;>}), q{<img />}, '<img> UTF-8 encoding is neutralized');
is( $l->clean(q{<IMG SRC=&#0000106&#0000097&#0000118&#0000097&#0000115&#0000099&#0000114&#0000105&#0000112&#0000116&#0000058&#0000097&#0000108&#0000101&#0000114&#0000116&#0000040&#0000039&#0000088&#0000083&#0000083&#0000039&#0000041>}),
    '<img />', '<img> with long-style UTF-8 encoding is neutralized');
is( $l->clean(q{<IMG SRC=&#x6A&#x61&#x76&#x61&#x73&#x63&#x72&#x69&#x70&#x74&#x3A&#x61&#x6C&#x65&#x72&#x74&#x28&#x27&#x58&#x53&#x53&#x27&#x29>}),
    q{<img />}, '<img> with no-colon hex encoding is neutralized');
is( $l->clean(q{<IMG SRC="jav	ascript:alert('XSS');">}), q{<img />}, '<img> with embedded tab is neutralized');
is( $l->clean(q{<IMG SRC="jav&#x09;ascript:alert('XSS');">}), q{<img />}, '<img> with encoded embedded tab is neutralized');
is( $l->clean(q{<IMG SRC="jav&#x0A;ascript:alert('XSS');">}), q{<img />}, '<img> with encoded embedded newline is neutralized');
is( $l->clean(q{<IMG SRC="jav&#x0D;ascript:alert('XSS');">}), q{<img />}, '<img> with encoded embedded CR is neutralized');
is( $l->clean(q{<IMG
SRC
=
"
j
a
v
a
s
c
r
i
p
t
:
a
l
e
r
t
(
'
X
S
S
'
)
"
>
}), q{<img />}, '<img> with multiline JS is neutralized');
is( $l->clean(q{<IMG SRC="javascript:alert('黒澤明');">}), q{<img />}, 'UTF-8 URL does not prevent sanitization');

# http://imfo.ru/csstest/css_hacks/import.php
