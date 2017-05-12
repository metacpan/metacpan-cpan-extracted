
use lib 't/lib';
use Test::More tests => 1;
use MyTestView;

my $out = MyTestView->render("/rowcell.html");
is(
    $out,
    "<table><tr><td>HI</td></tr></table>",
    "row and cell output tr and td tags correctly"
);

