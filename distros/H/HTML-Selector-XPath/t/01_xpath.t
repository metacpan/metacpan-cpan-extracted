use strict;
use Test::Base;
use HTML::Selector::XPath;

my @should_die = split /\n+/, <<'EOF';
[1a]
[-1a]
[--a]
[!a]
[ab!c]
[]
[x=1a]
[x=-1a]
[x=--a]
[x=!a]
[x=ab!c]
[x="]
[x="abc" "]
[x=abc z]
EOF

plan tests => 1 * blocks() + @should_die;
filters { selector => 'chomp', xpath => 'chomp' };

run {
    my $block = shift;
    my $selector = HTML::Selector::XPath->new($block->selector);
    is $selector->to_xpath, $block->xpath, $block->selector;
};

for my $selector (@should_die) {
    my $to_xpath = eval { HTML::Selector::XPath->new($selector)->to_xpath };
    is($to_xpath, undef, "invalid selector should die: $selector");
}

__END__
===
--- selector
*
--- xpath
//*

===
--- selector
E
--- xpath
//E

===
--- selector
E F
--- xpath
//E//F

===
--- selector
E > F
--- xpath
//E/F

===
--- selector
p.pastoral.marine
--- xpath
//p[contains(concat(' ', normalize-space(@class), ' '), ' pastoral ')][contains(concat(' ', normalize-space(@class), ' '), ' marine ')]

===
--- selector
E:first-child
--- xpath
//E[count(preceding-sibling::*) = 0 and parent::*]

===
--- selector
F E:first-child
--- xpath
//F//E[count(preceding-sibling::*) = 0 and parent::*]

===
--- selector
F > E:first-child
--- xpath
//F/E[count(preceding-sibling::*) = 0 and parent::*]

===
--- selector
E:lang(c)
--- xpath
//E[@xml:lang='c' or starts-with(@xml:lang, 'c-')]

===
--- selector
E + F
--- xpath
//E/following-sibling::*[1]/self::F

===
--- selector
E + #bar
--- xpath
//E/following-sibling::*[1]/self::*[@id='bar']

===
--- selector
E + .bar
--- xpath
//E/following-sibling::*[1]/self::*[contains(concat(' ', normalize-space(@class), ' '), ' bar ')]

===
--- selector
E[foo]
--- xpath
//E[@foo]

===
--- selector
E[foo=warning]
--- xpath
//E[@foo='warning']

===
--- selector
E[foo="warning"]
--- xpath
//E[@foo='warning']

===
--- selector
E[foo~="warning"]
--- xpath
//E[contains(concat(' ', @foo, ' '), ' warning ')]

===
--- selector
E[foo~=warning]
--- xpath
//E[contains(concat(' ', @foo, ' '), ' warning ')]

===
--- selector
E[foo^="warning"]
--- xpath
//E[starts-with(@foo,'warning')]

===
--- selector
E[foo^=warning]
--- xpath
//E[starts-with(@foo,'warning')]

===
--- selector
E:not([foo^="warning"])
--- xpath
//E[not(starts-with(@foo,'warning'))]

===
--- selector
E:not([foo^=warning])
--- xpath
//E[not(starts-with(@foo,'warning'))]

===
--- selector
E[foo$="warning"]
--- xpath
//E[substring(@foo,string-length(@foo)-6)='warning']

===
--- selector
E[foo$=warning]
--- xpath
//E[substring(@foo,string-length(@foo)-6)='warning']

===
--- selector
E[lang|="en"]
--- xpath
//E[@lang='en' or starts-with(@lang, 'en-')]

===
--- selector
E[lang|=en]
--- xpath
//E[@lang='en' or starts-with(@lang, 'en-')]

===
--- selector
DIV.warning
--- xpath
//DIV[contains(concat(' ', normalize-space(@class), ' '), ' warning ')]

===
--- selector
E#myid
--- xpath
//E[@id='myid']

===
--- selector
foo.bar, bar
--- xpath
//foo[contains(concat(' ', normalize-space(@class), ' '), ' bar ')] | //bar

===
--- selector
E:nth-child(1)
--- xpath
//E[count(preceding-sibling::*) = 0 and parent::*]

===
--- selector
E:last-child
--- xpath
//E[count(following-sibling::*) = 0 and parent::*]


===
--- selector
F E:last-child
--- xpath
//F//E[count(following-sibling::*) = 0 and parent::*]

===
--- selector
F > E:last-child
--- xpath
//F/E[count(following-sibling::*) = 0 and parent::*]

===
--- selector
E[href*="bar"]
--- xpath
//E[contains(@href, 'bar')]

===
--- selector
E[href*=bar]
--- xpath
//E[contains(@href, 'bar')]

===
--- selector
E:not([href*="bar"])
--- xpath
//E[not(contains(@href, 'bar'))]

===
--- selector
E:not([href*=bar])
--- xpath
//E[not(contains(@href, 'bar'))]

===
--- selector
F > E:nth-of-type(3)
--- xpath
//F/E[3]

===
--- selector
E ~ F
--- xpath
//E/following-sibling::F

===
--- selector
E ~ F.foo
--- xpath
//E/following-sibling::F[contains(concat(' ', normalize-space(@class), ' '), ' foo ')]

===
--- selector
E:contains("Hello")
--- xpath
//E[text()[contains(string(.),"Hello")]]

===
--- selector
E:contains( "Hello" )
--- xpath
//E[text()[contains(string(.),"Hello")]]
===
--- selector
E:contains( "Hello" ).C

--- xpath
//E[text()[contains(string(.),"Hello")]][contains(concat(' ', normalize-space(@class), ' '), ' C ')]
===
--- selector
E:contains( "Hello" ) .C

--- xpath
//E[text()[contains(string(.),"Hello")]]//*[contains(concat(' ', normalize-space(@class), ' '), ' C ')]
===
--- selector
F, E:contains( "Hello" )

--- xpath
//F | //E[text()[contains(string(.),"Hello")]]
===
--- selector
E:contains( "Hello" ), F

--- xpath
//E[text()[contains(string(.),"Hello")]] | //F
===
--- selector
E ~ F
--- xpath
//E/following-sibling::F

===
--- selector
E ~ #bar
--- xpath
//E/following-sibling::*[@id='bar']

===
--- selector
E ~ .bar
--- xpath
//E/following-sibling::*[contains(concat(' ', normalize-space(@class), ' '), ' bar ')]

===
--- selector
E ~ *
--- xpath
//E/following-sibling::*

===
--- selector
.foo ~ E
--- xpath
//*[contains(concat(' ', normalize-space(@class), ' '), ' foo ')]/following-sibling::E

===
--- selector
.foo ~ *
--- xpath
//*[contains(concat(' ', normalize-space(@class), ' '), ' foo ')]/following-sibling::*

===
--- selector
.foo ~ .bar
--- xpath
//*[contains(concat(' ', normalize-space(@class), ' '), ' foo ')]/following-sibling::*[contains(concat(' ', normalize-space(@class), ' '), ' bar ')]

===
--- selector
> em
--- xpath
//*/em

===
--- selector
:first-child
--- xpath
//*[count(preceding-sibling::*) = 0 and parent::*]
===
--- selector
:last-child
--- xpath
//*[count(following-sibling::*) = 0 and parent::*]

===
--- selector
E.c:first-child
--- xpath
//E[contains(concat(' ', normalize-space(@class), ' '), ' c ')][count(preceding-sibling::*) = 0 and parent::*]

===
--- selector
E:first-child.c
--- xpath
//E[count(preceding-sibling::*) = 0 and parent::*][contains(concat(' ', normalize-space(@class), ' '), ' c ')]

===
--- selector
E#i:first-child
--- xpath
//E[@id='i'][count(preceding-sibling::*) = 0 and parent::*]

===
--- selector
E:first-child#i
--- xpath
//E[count(preceding-sibling::*) = 0 and parent::*][@id='i']

===
--- selector
:lang(c)
--- xpath
//*[@xml:lang='c' or starts-with(@xml:lang, 'c-')]

===
--- selector
:lang(c)#i
--- xpath
//*[@xml:lang='c' or starts-with(@xml:lang, 'c-')][@id='i']

===
--- selector
#i:lang(c)
--- xpath
//*[@id='i'][@xml:lang='c' or starts-with(@xml:lang, 'c-')]

===
--- selector
*:lang(c)#i
--- xpath
//*[@xml:lang='c' or starts-with(@xml:lang, 'c-')][@id='i']

===
--- selector
E:lang(c)#i
--- xpath
//E[@xml:lang='c' or starts-with(@xml:lang, 'c-')][@id='i']

===
--- selector
E#i:lang(c)
--- xpath
//E[@id='i'][@xml:lang='c' or starts-with(@xml:lang, 'c-')]

===
--- selector
*:lang(c)#i:first-child
--- xpath
//*[@xml:lang='c' or starts-with(@xml:lang, 'c-')][@id='i'][count(preceding-sibling::*) = 0 and parent::*]

===
--- selector
E:lang(c)#i:first-child
--- xpath
//E[@xml:lang='c' or starts-with(@xml:lang, 'c-')][@id='i'][count(preceding-sibling::*) = 0 and parent::*]

===
--- selector
E:lang(c):first-child#i
--- xpath
//E[@xml:lang='c' or starts-with(@xml:lang, 'c-')][count(preceding-sibling::*) = 0 and parent::*][@id='i']

===
--- selector
E#i:lang(c):first-child
--- xpath
//E[@id='i'][@xml:lang='c' or starts-with(@xml:lang, 'c-')][count(preceding-sibling::*) = 0 and parent::*]

===
--- selector
#bar
--- xpath
//*[@id='bar']

===
--- selector
*#bar
--- xpath
//*[@id='bar']

===
--- selector
*[foo]
--- xpath
//*[@foo]

===
--- selector
[foo]
--- xpath
//*[@foo]


===
--- selector
.warning
--- xpath
//*[contains(concat(' ', normalize-space(@class), ' '), ' warning ')]

===
--- selector
*.warning
--- xpath
//*[contains(concat(' ', normalize-space(@class), ' '), ' warning ')]

 
===
--- selector
:nth-child(1)
--- xpath
//*[count(preceding-sibling::*) = 0 and parent::*]

===
--- selector
*:nth-child(1)
--- xpath
//*[count(preceding-sibling::*) = 0 and parent::*]

===
--- selector
E:nth-child(1)
--- xpath
//E[count(preceding-sibling::*) = 0 and parent::*]

===
--- selector
E:nth-child(2)
--- xpath
//E[count(preceding-sibling::*) = 1 and parent::*]

===
--- selector
E:nth-child(even)
--- xpath
//E[not((count(preceding-sibling::*)+1)<0) and ((count(preceding-sibling::*) + 1) - 0) mod 2 = 0 and parent::*]
===
--- selector
E:nth-child(odd)
--- xpath
//E[not((count(preceding-sibling::*)+1)<1) and ((count(preceding-sibling::*) + 1) - 1) mod 2 = 0 and parent::*]

===
--- selector
E:nth-child(2n)
--- xpath
//E[not((count(preceding-sibling::*)+1)<0) and ((count(preceding-sibling::*) + 1) - 0) mod 2 = 0 and parent::*]
===
--- selector
E:nth-child(2n+1)
--- xpath
//E[not((count(preceding-sibling::*)+1)<1) and ((count(preceding-sibling::*) + 1) - 1) mod 2 = 0 and parent::*]

===
--- selector
:root
--- xpath
/*

===
--- selector
E:root
--- xpath
/E

===
--- selector
E:empty
--- xpath
//E[not(* or text())]
===
--- selector
:empty
--- xpath
//*[not(* or text())]

===
--- selector
p , :root
--- xpath
//p | /*

===
--- selector
p , q
--- xpath
//p | //q
===
--- selector
div *:not(p) em
--- xpath
//div//*[not(self::p)]//em
===
--- selector
a:not(.external)[href]
--- xpath
//a[not(self::*[contains(concat(' ', normalize-space(@class), ' '), ' external ')])][@href]
===
--- selector
div em:only-child
--- xpath
//div//em[count(preceding-sibling::*) = 0 and parent::*][count(following-sibling::*) = 0 and parent::*]

===
--- selector
[x=abc]
--- xpath
//*[@x='abc']

===
--- selector
[x=a-bc]
--- xpath
//*[@x='a-bc']

===
--- selector
[x=abc-]
--- xpath
//*[@x='abc-']

===
--- selector
[x=ab--c]
--- xpath
//*[@x='ab--c']

===
--- selector
option[value!=""]
--- xpath
//option[@value!='']

===
--- selector
option[ value="" ]
--- xpath
//option[@value='']

===
--- selector
tr[class!="wantedClass"]
  
--- xpath
//tr[@class!='wantedClass']
===
--- selector
form[name='foo']

--- xpath
//form[@name='foo']
