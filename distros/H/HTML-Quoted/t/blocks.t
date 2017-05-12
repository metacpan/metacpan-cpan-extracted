use strict;
use warnings;

use Test::More tests => 7;
BEGIN { use_ok('HTML::Quoted') };

sub rt_ok { # C&P also in t/lines.t
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
    my $a = "<div>line1</div>";
    is_deeply(HTML::Quoted->extract($a),[{raw => '<div>line1</div>', block => 1 }])
        or diag Dumper(HTML::Quoted->extract($a));
    rt_ok($a);
}
{
    my $a = "<div />";
    is_deeply(HTML::Quoted->extract($a),[{raw => '<div />', block => 1 }])
        or diag Dumper(HTML::Quoted->extract($a));
    rt_ok($a);
}
{
    my $a = "<div></div><br />";
    is_deeply(HTML::Quoted->extract($a),[{raw => '<div></div>', block => 1 },{raw => '<br />'}])
        or diag Dumper(HTML::Quoted->extract($a));
    rt_ok($a);
}
