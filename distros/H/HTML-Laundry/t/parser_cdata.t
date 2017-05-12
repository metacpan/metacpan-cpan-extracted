use strict;
use warnings;

use Test::More tests => 19;

require_ok('HTML::Laundry');

my $l1 = HTML::Laundry->new({ notidy => 1 });

is( $l1->clean('<script src="http://example.com/foo.js" />'), '', "Empty script tag produces no results");
is( $l1->clean('<script src="http://example.com/foo.js"></script>'), '', "Non-empty script tag produces no results");
is( $l1->clean('</script></script><script src="http://example.com/foo.js" />'), '', "Spurious </script>s don't confuse the situation");
is( $l1->clean('inter<script src="http://example.com/foo.js" />rupt'), 'interrupt', "Text on either side of script is parsed");
is( $l1->clean('<br /><script src="http://example.com/foo.js" /><br />'), '<br /><br />', "Tags on either side of script are parsed");
is( $l1->clean('<script>alert(\'x\');'), '', "Unclosed <script> is eaten");


is( $l1->clean('<![CDATA[Hello]]>'), 'Hello', "Text within CDATA is parsed");
ok( $l1->clean('<![CDATA[Hello]]') eq 'Hello]]' && $l1->clean('<br></br>') eq '<br />' && $l1->clean('<![CDATA[Hello]]>') eq 'Hello', 'Malformed CDATA doesn\'t carry between parsings');
is( $l1->clean('<![CDATA[<p id="xyzzy"><br></br></p>]]>'), '<p id="xyzzy"><br /></p>', "Tags within CDATA are parsed");
is( $l1->clean('inter<![CDATA[Hello]]>rupt'), 'interHellorupt', "Text on either side of CDATA is parsed");
is( $l1->clean('<p><![CDATA[Hello]]></p>'), '<p>Hello</p>', "Tags on either side of CDATA are parsed");
is( $l1->clean('<p><![CDATA[Hel<script>alert(\'ha ha ha\')</script>lo]]></p>'), '<p>Hello</p>', "Script within CDATA is discarded");
is( $l1->clean('<p><![CDATA[Hel<script>alert(\'ha ha ha\')]]>lo</p>'), '<p>Hello</p>', "Unclosed script within CDATA does not affect parsing of remainder");
is( $l1->clean('<script><![CDATA[alert(\'ha ha ha\')</script>]]>'), ']]&gt;', "Splitting script with CDATA doesn't allow script injection (1/2)");
is( $l1->clean('<![CDATA[<script>alert(\'ha ha ha\')]]></script>'), '', "Splitting script with CDATA doesn't allow script injection (2/2)");
is( $l1->clean(q{<![CDATA[<scr]]>ipt>alert('Ha ha ha')</script>}), qq{ipt&gt;alert('Ha ha ha')}, 'Splitting script tag tag with CDATA doesn\'t allow script inection (1/3)');
is( $l1->clean(q{<scr<![CDATA[ipt>alert('Ha ha ha')</script>]]>}), qq{alert('Ha ha ha')]]&gt;}, 'Splitting script tag tag with CDATA doesn\'t allow script inection (2/3)');
is( $l1->clean(q{<scr<![CDATA[ipt>i]>pit>alert('Ha ha ha')</script>')]}), qq{i]&gt;pit&gt;alert('Ha ha ha')')]}, 'Splitting script tag tag with CDATA doesn\'t allow script inection (2/3)');
