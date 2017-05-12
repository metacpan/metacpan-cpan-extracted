use Test::More;
use HTML::LinkFilter;

my @cases = (
    [ <<'WISH', <<'HTML' ],
<!doctype html>
<html>
WISH
<!doctype html>
<html>
HTML
);

plan tests => scalar @cases;

sub callback { }

my $filter = HTML::LinkFilter->new;

foreach my $case_ref ( @cases ) {
    my( $wish, $html ) = @{ $case_ref };

    $filter->change( $html, \&callback_sub );
    is( $filter->html, $wish );
}


