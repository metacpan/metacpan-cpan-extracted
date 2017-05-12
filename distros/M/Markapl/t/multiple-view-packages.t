use lib 't/lib';

use strict;
use warnings;
use Test::More tests => 2;

use MyTestView2;
use MyTestView;

my $out1 = MyTestView2->render("/helper-heads-cells");
my $out2 = MyTestView->render("/foo.html");

is $out2, "foo.html output";
like $out1, qr/^<table>.+<\/table>/;
