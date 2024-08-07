use Test::More qw(no_plan);

use Math::Transform::List;


# 3

 {my $a = '';

  ok 6 == transform {$a .= "@_\n"} [1..3], [1,2], [1..3];

  ok $a eq << 'end';
2 1 3
2 3 1
1 3 2
3 1 2
3 2 1
1 2 3
end
 }


# 4

 {my $a = '';

  ok 24 == transform {$a .= "@_\n"} [1..4], [1,2], [1..4];

  ok $a eq << 'end';
2 1 3 4
2 3 4 1
1 3 4 2
3 4 1 2
3 4 2 1
4 1 2 3
4 2 1 3
1 2 3 4
1 3 2 4
2 3 1 4
2 4 3 1
1 4 3 2
3 1 4 2
3 2 4 1
4 3 1 2
4 3 2 1
1 4 2 3
2 4 1 3
3 1 2 4
3 2 1 4
4 2 3 1
4 1 3 2
1 2 4 3
2 1 4 3
end
 }



# 5

 {my $a = '';

  ok 120 == transform {$a .= "@_\n"} [1..5], [1,2], [1..5];

  ok $a eq << 'end';
2 1 3 4 5
2 3 4 5 1
1 3 4 5 2
3 4 5 1 2
3 4 5 2 1
4 5 1 2 3
4 5 2 1 3
5 1 2 3 4
5 2 1 3 4
1 2 3 4 5
1 3 2 4 5
2 3 1 4 5
2 4 3 5 1
1 4 3 5 2
3 5 4 1 2
3 5 4 2 1
4 1 5 2 3
4 2 5 1 3
5 3 1 2 4
5 3 2 1 4
1 4 2 3 5
2 4 1 3 5
2 5 3 4 1
1 5 3 4 2
3 1 4 5 2
3 2 4 5 1
4 3 5 1 2
4 3 5 2 1
5 4 1 2 3
5 4 2 1 3
1 5 2 3 4
2 5 1 3 4
3 1 2 4 5
3 2 1 4 5
4 2 3 5 1
4 1 3 5 2
5 3 4 1 2
5 3 4 2 1
1 4 5 2 3
2 4 5 1 3
3 5 1 2 4
3 5 2 1 4
4 1 2 3 5
4 2 1 3 5
5 2 3 4 1
5 1 3 4 2
1 2 4 5 3
2 1 4 5 3
2 3 5 1 4
1 3 5 2 4
3 4 1 2 5
3 4 2 1 5
4 5 2 3 1
4 5 1 3 2
5 1 2 4 3
5 2 1 4 3
1 2 3 5 4
2 1 3 5 4
2 3 4 1 5
1 3 4 2 5
2 4 5 3 1
1 4 5 3 2
3 5 1 4 2
3 5 2 4 1
4 1 2 5 3
4 2 1 5 3
5 2 3 1 4
5 1 3 2 4
1 2 4 3 5
2 1 4 3 5
2 3 5 4 1
1 3 5 4 2
3 4 1 5 2
3 4 2 5 1
4 5 3 1 2
4 5 3 2 1
5 1 4 2 3
5 2 4 1 3
1 2 5 3 4
2 1 5 3 4
5 1 4 3 2
5 2 4 3 1
1 2 5 4 3
2 1 5 4 3
2 3 1 5 4
1 3 2 5 4
2 4 3 1 5
1 4 3 2 5
2 5 4 3 1
1 5 4 3 2
3 1 5 4 2
3 2 5 4 1
4 3 1 5 2
4 3 2 5 1
5 4 3 1 2
5 4 3 2 1
1 5 4 2 3
2 5 4 1 3
3 1 5 2 4
3 2 5 1 4
4 3 1 2 5
4 3 2 1 5
5 4 2 3 1
5 4 1 3 2
1 5 2 4 3
2 5 1 4 3
3 1 2 5 4
3 2 1 5 4
4 2 3 1 5
4 1 3 2 5
2 4 1 5 3
1 4 2 5 3
2 5 3 1 4
1 5 3 2 4
3 1 4 2 5
3 2 4 1 5
4 2 5 3 1
4 1 5 3 2
5 3 1 4 2
5 3 2 4 1
end
 }

