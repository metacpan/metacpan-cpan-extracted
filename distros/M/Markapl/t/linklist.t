
use lib 't/lib';
use Test::More tests => 1;
use MyTestView;

my $out = MyTestView->render("/linklist.html");
like(
    $out,
    qr/<li><a href=".+">.+<\/a><\/li>/,
    "<a> renders correctly"
);
