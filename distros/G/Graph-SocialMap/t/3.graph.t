#!/usr/bin/perl

use Test::More qw(no_plan);
use Graph::SocialMap;
use Graph::Writer::GraphViz;
use IO::All;

my $relation = {
    1357 => [qw/Marry Rose Autrijus/],
    3579 => [qw/Marry Peacock/],
    2468 => [qw/Joan/],
    4680 => [qw/Rose Joan/],
    OSSF => [qw/Gugod Autrijus/],
    GGYY => [qw/Gugod Autrijus Joan Peacock/],
    1234 => [qw/Tifa Dora Charlee Angie/],
    5555 => [qw/A B C D E F G H I J K/],
};

my $gsm = Graph::SocialMap->new(relation => $relation);
my $writer = Graph::Writer::GraphViz->new(-format=>'dot');
$writer->write_graph($gsm->type2,'t/graphtest1.dot');
ok(-f 't/graphtest1.dot');
unlink 't/graphtest1.dot';

ok($gsm->dos('Marry','Autrijus') == 1);

my $alldos = $gsm->all_dos;
ok($alldos->{Marry}->{Autrijus} == 1);
ok($alldos->{Marry}->{Joan} == 2);
