use lib qw(./blib/lib ../blib/lib);
use strict;
BEGIN { $| = 1; print "1..9\n"; }
use Inline::Files;
my $loaded = 1;
END {print "not ok 1\n" unless $loaded;}
print "ok 1\n";

print while <VIRTUAL>;

open SECOND_VIRTUAL
  and do { print for <SECOND_VIRTUAL>; 1 }
or print "not ok 8\n";


__VIRTUAL__
ok 2
ok 3
ok 4
__SECOND_VIRTUAL__
ok 8
ok 9
__VIRTUAL__
ok 5
ok 6
__OTHER__
not ok 666
__VIRTUAL__
__VIRTUAL__
ok 7
__SECOND_VIRTUAL__
not ok 10
not ok 11
