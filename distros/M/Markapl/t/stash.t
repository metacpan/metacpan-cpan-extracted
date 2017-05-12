
use lib 't/lib';
use strict;
use warnings;
use Test::More tests => 3;
use MyTestView;
use MyTestView3;

my $title = "Greeting, " . time;
MyTestView3->set(title => $title);

is(MyTestView3->get("title"), $title);

my $out = MyTestView3->render("/stash1.html");
like($out, qr/$title/);

$out = MyTestView->render("/stash1.html");
like($out, qr/<h1><\/h1>/);


