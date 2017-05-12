use strict;
use Test::More tests => 252;
use HTML::Entities::Numbered;

open(ENT, 't/entities.txt') || die $!;
while (<ENT>) {
    chomp;
    my @entity = split /\t+/, $_;
    unless ($entity[0] =~ /^&(?:lt|gt|amp|quot|apos);/) {
	ok(name2decimal_xml($entity[0]) eq $entity[1]);
    }
    else {
	ok(name2decimal_xml($entity[0]) eq $entity[0]);
    }
}
close ENT;
