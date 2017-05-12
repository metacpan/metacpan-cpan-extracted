use strict;
use Test::More tests => 1008;
use HTML::Entities::Numbered;

open(ENT, 't/entities.txt') || die $!;
while (<ENT>) {
    chomp;
    my @entity = split /\t+/, $_;
    ok(decimal2name(name2decimal($entity[0])) eq $entity[0]);
    ok(name2decimal(decimal2name($entity[1])) eq $entity[1]);
    ok(name2hex(hex2name($entity[2])) eq $entity[2]);
    ok(hex2name(name2hex(decimal2name(name2decimal($entity[0])))) eq $entity[0]);
}
close ENT;
