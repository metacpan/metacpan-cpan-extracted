use strict;
use Test::More tests => 252;
use HTML::Entities::Numbered;

open(ENT, 't/entities.txt') || die $!;
while (<ENT>) {
    chomp;
    my @entity = split /\t+/, $_;
    ok(hex2name($entity[2]) eq $entity[0]);
}
close ENT;
