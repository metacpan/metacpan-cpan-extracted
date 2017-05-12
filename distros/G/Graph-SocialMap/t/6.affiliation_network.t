#!/usr/bin/perl
#!/usr/bin/perl
use Graph::SocialMap;
use Test::More 'no_plan';

my $relation = {
    1357 => [qw/Marry Rose/],
    3579 => [qw/Marry Peacock/],
    2468 => [qw/Joan/],
    4680 => [qw/Rose Joan/],
    CLOCK => [qw/12 1 2 3 4 5 6 7 8 9 10 11/],
    1234 => [qw/Tifa Dora Charlee Angie/],
    5555 => [qw/A B C D E F G H I J K/],
    RAND => [qw/A Tifa Peacock Joan Peacock/]
};

my $gsm = Graph::SocialMap->new(relation => $relation);
my $n = $gsm->affiliation_network;
ok( $n->has_edge('Issue/1357','People/Marry'));
ok( $n->has_edge('People/Marry','Issue/1357'));
ok( ! $n->has_edge('People/Rose','People/Marry') );
