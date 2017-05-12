use strict;
use warnings;

use Test::More tests => 15;
BEGIN { use_ok('HTML::Quoted') };

sub rt_ok { # C&P also in t/blocks.t
    my $text = shift;
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    is(
        HTML::Quoted->combine_hunks( HTML::Quoted->extract( $text ) ),
        $text,
        "round trips okay",
    );
}

use Data::Dumper;
{
    my $a = "line1";
    is_deeply(HTML::Quoted->extract($a),[{raw => 'line1'}]);
    rt_ok($a);
}

{
    my $a = "line1<br>";
    is_deeply(HTML::Quoted->extract($a),[{raw => 'line1<br>'}])
        or diag Dumper(HTML::Quoted->extract($a));
    rt_ok($a);
}
{
    my $a = "line1<br />";
    is_deeply(HTML::Quoted->extract($a),[{raw => 'line1<br />'}])
        or diag Dumper(HTML::Quoted->extract($a));
    rt_ok($a);
}
{
    my $a = "line1<br></br>";
    is_deeply(HTML::Quoted->extract($a),[{raw => 'line1<br></br>'}])
        or diag Dumper(HTML::Quoted->extract($a));
    rt_ok($a);
}

{
    my $a = "line1<br>line2";
    is_deeply(HTML::Quoted->extract($a),[{raw => 'line1<br>'}, {raw => 'line2'}])
        or diag Dumper(HTML::Quoted->extract($a));
    rt_ok($a);
}
{
    my $a = "line1<br />line2";
    is_deeply(HTML::Quoted->extract($a),[{raw => 'line1<br />'}, {raw => 'line2'}]);
    rt_ok($a);
}
{
    my $a = "line1<br></br>line2";
    is_deeply(HTML::Quoted->extract($a),[{raw => 'line1<br></br>'}, {raw => 'line2'}]);
    rt_ok($a);
}

