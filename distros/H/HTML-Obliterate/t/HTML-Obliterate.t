use Test::More tests => 41;
BEGIN { use_ok('HTML::Obliterate') };

my $str = q{<p>hello world</p>};
my $arr = [$str, "howdy", q{<br /><img src="" />}];

ok(HTML::Obliterate::remove_html($str) eq 'hello world', 'remove_html str');

my $new = HTML::Obliterate::remove_html($arr);

ok($new->[0] eq 'hello world', 'remove_html arr chg 1');
ok($new->[1] eq 'howdy', 'remove_html arr chg 2');
ok($new->[2] eq '', 'remove_html str arr chg 3');
ok($arr->[0] ne 'hello world', 'remove_html arr no chg 1');
ok($arr->[1] eq 'howdy', 'remove_html arr no chg 2');
ok($arr->[2] ne '', 'remove_html str arr no chg 3');

HTML::Obliterate::remove_html($arr);
ok($arr->[0] eq 'hello world', 'remove_html arr void chg');
ok($arr->[1] eq 'howdy', 'remove_html arr void chg 2');
ok($arr->[2] eq '', 'remove_html str arr void chg 3');

ok(HTML::Obliterate::extirpate_html($str) eq 'hello world', 'alias test');

ok(HTML::Obliterate::remove_html_from_string(qq{<p>hello\nworld</p><img class="css" src="bowza">}) eq "hello\nworld", 'multi line string');
ok(HTML::Obliterate::remove_html_from_string(qq{<p\nclass="foo">hello\nworld</p><img \nclass="css" src="bowza">}) eq "hello\nworld", 'multi line tag');

my %ent = (
    'Hello' => '&lt;Hello&gt;',
    "\nHello\n\n" => "&lt;\nHello\n&gt;\n",
    'Hello ' => '&lt;Hello&gt &n;',
    '&;' => '&;',
    'hi' => '&#142;hi&there;',
    '& quot ;' => '& quot ;',
    '& l t' => '& l t',
    '& gt' => '& gt', 
    "\n;" => "&lt\n;",
    ''  => '<>',
    'ab'  => 'a<>>b',
    'lajde' => 'l<q>>>d>a<b>jde',
    'xy'  => 'x<!--  _  -->y',
    'comment w/ HTML' => 'com<!-- <a href=\"old.htm\">old page</a> -->ment w/ HTML',
    'comment x comment' => 'comment <!--z-->x<!--y--> comment', 
    'test' => '<em>test</em>',
    'foobar' => 'foo<br>bar',
    
    'test 1' => '<p align="center">test 1</p>', # w/ attribute
    'test 2' => '<p align="center>test 2</p>', # mis quoted attribute
    'test 3' => '<p title="<b>">test 3</p>', # attribute w/ unescaped html
    'bar' => '<foo>bar',
    'baz' =>  '</foo>baz',
    'baz 2' => '<!-- <p>foo</p> bar -->baz 2',
    'bar 2' => '<img src="foo.gif" alt="a > b">bar 2', # attribute w/ '>'
    'zib' => '<# just data #>zib',
    
    # doesn't take out tag contents since it doesn't parse the HTML into a struvture
    'if (ac)tag section' => '<script>if (a<b && a>c)</script>tag section',

    'jaz' => '<![INCLUDE CDATA [ >>>>>>>>>>>> ]]>jaz',
);

my $cnt = 0;
for my $key (sort keys %ent) {
    $cnt++;
    my $res = HTML::Obliterate::remove_html_from_string($ent{$key});
    diag "'$res' should be $key" if $res ne $key;
    ok($res eq $key, "HTML entity $cnt");
}