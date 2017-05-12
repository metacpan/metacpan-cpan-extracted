use strict;
use Test::More tests => 504;
use HTML::Entities::Numbered;

open(ENT, 't/entities.txt') || die $!;
while (<ENT>) {
    chomp;
    my @entity = split /\t+/, $_;
    my $changed = $entity[0];
    $changed =~ tr/A-Za-z/a-zA-Z/;
    ok(name2decimal($changed) ne $entity[1]);
    unless ($changed =~ /^&(?:thorn|eth);$/i) {
	ok(name2decimal($changed) eq $changed);
    }
    else {
	ok(name2decimal($changed) ne $changed);
    }
}
close ENT;
