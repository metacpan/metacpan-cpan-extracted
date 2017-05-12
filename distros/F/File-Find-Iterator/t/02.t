# -*- perl -*-

use Test::More;
BEGIN { plan tests => 2 };
use File::Find::Iterator;

my $find = File::Find::Iterator->create(dir => ["."]);

my @res = ();
while (my $f =  $find->next) {
    push @res, $f;
}
ok @res;

# test the statefile option
$find->statefile('statefile');
$find->first;
my @res2 = ();
push @res2, $find->next, $find->next;

while (my $f =  $find->next) {
    push @res2, $f;
}
ok @res2 == @res;


unlink $find->statefile;
