#!/usr/bin/perl

use Test::Simple tests => 3;
use Graph::SocialMap;
use YAML;

my $relation = {
    1357 => [qw/Marry Rose/],
    3579 => [qw/Marry Peacock/],
    2468 => [qw/Joan/],
    4680 => [qw/Rose Joan/],
    OSSF => [qw/Gugod Autrijus/],
};

my $gsm = Graph::SocialMap->new(relation => $relation);

my (@p,$a,$b);

@p = $gsm->pairs(1,2);
$a = YAML::Dump(@p);
$b = YAML::Dump(([1,2]));
ok($a eq $b);

@p = $gsm->pairs(1,2,3);
$a = YAML::Dump(@p);
$b = YAML::Dump(([1,2],[1,3],[2,3]));
ok($a eq $b);

@p = $gsm->pairs(3,5,6,7);
$a = YAML::Dump(@p);
$b = YAML::Dump(([3,5],[3,6],[3,7],[5,6],[5,7],[6,7]));
ok($a eq $b);
