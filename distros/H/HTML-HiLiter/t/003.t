use strict;
use Test::More tests => 3;
use HTML::HiLiter;
use Data::Dump qw( dump );

my $file = 't/docs/test.html';

my @q = (
    'foo = "quick brown" and bar=(fox* or run)',
    'runner',
    '"Over the Too Lazy dog"',
    '"c++ filter"',
    '"-h option"',
    'laz',
    'fakefox',
    '"jumped over"',
);

ok( my $hiliter = HTML::HiLiter->new(
        query             => join( ' ', @q ),
        word_characters   => '\w\-\.\+',
        ignore_first_char => '\.',
        class             => 'hilite',

        #debug        => 1,
        #tty          => 1,
        print_stream => 0,
    ),
    "new HiLiter"
);

ok( my $hilited = $hiliter->run($file) );

#dump $hiliter;

my $expected_hilited = <<EOF;
<html>
<head>
<meta name="somemeta" content="somemeta description of the quick fox">
<title>quick fox</title>
</head>

<body>
<h1>THIS IS THE TITLE</h1>
<div>
<p
>The <b><i><span class='hilite'>q</span></i></b><span class='hilite'>uick brown</span> ( really!@#\$ ) <span class='hilite'>fox</span> [<span class='hilite'>foxy</span>, no doubt...]
</p>
<p>
<span class='hilite'>jum</span><em><span class='hilite'>p</span></em><span class='hilite'>ed over</span>&nbsp;the to<strong>o</strong> lazy<br />
 dog. hey, running, <span class='hilite'>runner</span>, ran
</p>
</div>
<div>
<p>
a second div with a fake entity called &fakefoxent;
<a href="http://fox.com/quick.html">a link here</a>
</p>
</div>
<div>
<p>
a third div with a technical piece: <span class='hilite'>C++&nbsp;filter</span> takes the &#8211;h&nbsp;option
or the &#8212; long-dash option
</p>
</div>
</body>
</html>
EOF

is( $hilited, $expected_hilited, "hiliter matches" );
