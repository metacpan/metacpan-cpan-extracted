
use lib 't/lib';
use Test::More;

plan tests => 3;

use MyTestView;

my $output = MyTestView->render("/foo.html");

is($output, "foo.html output", "foo.html rendered ok");

$output = MyTestView->render("/foo/bar.html");
is($output, "bar.html output", "bar.html rendered ok");

eval { Markapl->render("/not/there") };
ok( $@ =~ /no such template/, "render() on non-existant template dies" );
