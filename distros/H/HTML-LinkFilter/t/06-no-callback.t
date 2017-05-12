use Test::More;
use HTML::LinkFilter;

my @cases = (
    [ <<'WISH', <<'HTML' ],
<a href="foo/bar">
WISH
<a href="foo/bar">
HTML
    [ <<'WISH', <<'HTML' ],
<a href="foo/bar"></a>
WISH
<a href="foo/bar"></a>
HTML
    [ <<'WISH', <<'HTML' ],
<p>foo</p>
WISH
<p>foo</p>
HTML
    [ <<'WISH', <<'HTML' ],
<link href="http://foo.forkn.jp/css/member.css" rel="stylesheet" type="text/css" media="screen" />
WISH
<link href="http://foo.forkn.jp/css/member.css" rel="stylesheet" type="text/css" media="screen" />
HTML
    [ <<'WISH', <<'HTML' ],
<p>
    <a href="/foo">bar</a>
</p>
WISH
<p>
    <a href="/foo">bar</a>
</p>
HTML
);

plan tests => scalar @cases;

my $filter = HTML::LinkFilter->new;

foreach my $case_ref ( @cases ) {
    my( $wish, $html ) = @{ $case_ref };

    $filter->change( $html );
    is( $filter->html, $wish );
}


