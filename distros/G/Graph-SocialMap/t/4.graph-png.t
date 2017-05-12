#!/usr/bin/perl
use strict;
use Test::Simple tests => 1;
use Graph::SocialMap;
use Graph::Writer::GraphViz;
use IO::All;
use YAML;

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
my $writer = Graph::Writer::GraphViz->new(-format=>'png');
$writer->write_graph($gsm->type2,'/tmp/graph.png');
ok( -f '/tmp/graph.png');
unlink('/tmp/graph.png');
