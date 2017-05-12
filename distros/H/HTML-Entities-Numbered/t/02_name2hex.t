use strict;
use Test::More tests => 252;
use HTML::Entities::Numbered;

open(ENT, 't/entities.txt') || die $!;
while (<ENT>) {
    chomp;
    my @entity = split /\t+/, $_;
    ok(name2hex($entity[0]) eq $entity[2]);
}
close ENT;
