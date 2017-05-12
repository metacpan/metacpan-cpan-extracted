use Test::More 'no_plan';

use List::Maker;

my $count = 1;

List::Maker::add_handler(
    qr/^ \s* (\d+) \s* d \s* (\d+) \s* $/xms => sub {
        ok $count==1 || $count==2  => "$1 d $2";
        $count++;
    }
);

List::Maker::add_handler(
    qr/^ \s* ' ( [^\\']*(?:\\.[^\\']*)* ) ' \s* x \s* (\d+) \s* $/xms => sub {
        is 3, $count  => "xx";
    }
);

< 2d6 >;
< 3 d 10 >;
< 'cat' x 3 >;
