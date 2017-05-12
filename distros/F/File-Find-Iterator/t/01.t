# -*- perl -*-

use Test::More;
BEGIN { plan tests => 7 };
use File::Find::Iterator qw(imap igrep);

my $find = File::Find::Iterator->create(dir => ["."]);
# test creation
ok $find;

# test next method
my @res = ();
while (my $f =  $find->next) {
    push @res, $f;
}
ok @res;

# test first method
$find->first;
my @res2 = ();
while (my $f = $find->next) {
    push @res2, $f;
}
ok @res == @res2;

# test the filter feature
$find->filter(sub { -d });
$find->first;
my $res3 = 1;
while (my $f =  $find->next) {
    $res3 &&= -d $f;
}
ok $res3;

# test the map feature
$find->map(sub { -M });
$find->first;
my $res4 = 1;
while (my $f =  $find->next) {
    $res4 &&= $f > 0;
}
ok $res4;



{

    my $find = File::Find::Iterator->create(dir => ["."]);
    ok $find;
    $find = imap { "$_$_" } igrep { -d } $find;
    my @res = ();
    while (my $f =  $find->next) {
	push @res, $f;
    }
    ok @res;

}
