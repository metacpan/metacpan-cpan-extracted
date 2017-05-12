#!/usr/bin/perl
use strict;
use warnings;
use Test::Simple tests => 10;
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
$writer->write_graph($gsm->type3,'t/graphtest2.dot');
ok(-f 't/graphtest2.dot');
unlink('t/graphtest2.dot');

my $adjm = $gsm->type3_adj_matrix;
ok($adjm->{Rose}->{Marry} == 1);

ok(cmp_hashes($adjm->{Angie},{Tifa=>1,Dora=>1,Charlee=>1}));
ok(cmp_hashes($adjm->{Charlee},{Tifa=>1,Dora=>1}));
ok(cmp_hashes($adjm->{Dora},{Tifa=>1}));
ok(cmp_hashes($adjm->{Marry},{}));
ok(cmp_hashes($adjm->{Gugod},{}));
ok(cmp_hashes($adjm->{Joan},{Rose => 1, Gugod => 1, Autrijus => 1}));
ok(cmp_hashes($adjm->{Autrijus},{Marry=>1,Rose=>1,Gugod=>1}));
ok(cmp_hashes($adjm->{Peacock} ,{Marry=>1,Gugod=>1,Autrijus=>1,Joan=>1}));

sub cmp_hashes {
    my ($h1,$h2) = @_;
    return 0 unless (keys %$h1 == keys %$h2);
    for (keys %$h1) {
	return 0 if($h1->{$_} ne $h2->{$_});
    }
    return 1;
}
