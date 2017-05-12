use strict;
use warnings;
use Math::Decimal128 qw(:all);

print "1..1\n";

my @me = (['inf', undef], ['+inf', 0], ['1234', -12], ['0', 123], ['1', 6200],
          ['inf', 17], ['-inf', ''], ['-1234', -12], ['-0', 123], ['-1', 6200],
          ['nan', -3], ['+nan', 0], ['-nan', ''], ['nan', 0], ['+0', 2], ['+123', 7000]);

my @pv = ('inf', 'inf', '1234e-12', '0e123', '1e6200', 'inf', '-inf', '-1234e-12', '-0e123',
       '-1e6200', 'nan', 'nan', '-nan', 'nan', '+0e2', '+123e7000');

my $ok = 1;

for(my $i = 0; $i < @me; $i++) {
  if(MEtoPVl(@{$me[$i]}) ne $pv[$i]) {
    $ok = 0;
    warn "\n [ @{$me[$i]} ] does not translate to $pv[$i]\n";
  }
}

if($ok) {print "ok 1\n"}
else    {print "not ok 1\n"}

