use Test::More;
use HTML::LinkFilter;

my @cases = (
    [ <<'WISH', <<'HTML' ],
<a href="/foo/bar">
WISH
<a href="/foo/bar">
HTML
    [ <<'WISH', <<'HTML' ],
<a href="/foo/bar">foo</a>
WISH
<a href="/foo/bar">foo</a>
HTML
);

plan tests => scalar @cases;

my $callback_sub = sub { };

my $filter = HTML::LinkFilter->new;

foreach my $case_ref ( @cases ) {
    my( $wish, $html ) = @{ $case_ref };

    $filter->change( $html, $callback_sub );
    is( $filter->html, $wish );
}


