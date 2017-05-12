use strict;
use Test::More qw(no_plan);
use Math::Permute::Partitions;

if (1)
 {my $a = '';
  ok 4 == permutePartitions {$a .= "@_\n"} [1,2], [3,4];
  ok $a eq <<END;
1 2 3 4
1 2 4 3
2 1 3 4
2 1 4 3
END
 }  

if (1)
 {my $a = '';
  ok 24 == permutePartitions {$a .= "@_\n"} [1,2], [3,4], [5, 6, 7];
  ok $a eq <<END;
1 2 3 4 5 6 7
1 2 3 4 5 7 6
1 2 3 4 6 5 7
1 2 3 4 7 5 6
1 2 3 4 6 7 5
1 2 3 4 7 6 5
1 2 4 3 5 6 7
1 2 4 3 5 7 6
1 2 4 3 6 5 7
1 2 4 3 7 5 6
1 2 4 3 6 7 5
1 2 4 3 7 6 5
2 1 3 4 5 6 7
2 1 3 4 5 7 6
2 1 3 4 6 5 7
2 1 3 4 7 5 6
2 1 3 4 6 7 5
2 1 3 4 7 6 5
2 1 4 3 5 6 7
2 1 4 3 5 7 6
2 1 4 3 6 5 7
2 1 4 3 7 5 6
2 1 4 3 6 7 5
2 1 4 3 7 6 5
END
 }  
