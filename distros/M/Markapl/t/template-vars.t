use lib 't/lib';
use strict;
use warnings;
use Test::More tests => 1;
use MyTestView3;

my $out = MyTestView3->render(
    "/var1.html",
    title => "Greeting"
);

diag $out;
like($out, qr/Greeting/);
