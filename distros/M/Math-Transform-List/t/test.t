use Test::More qw(no_plan);

use Math::Transform::List;


# 0

ok 0 == transform {} [];


# 1

 {my $a = '';

  ok 1 == transform {$a .= "@_\n"} [qw(a)];

  ok $a eq << 'end';
a
end
 }


# 2

 {my $a = '';

  ok 2 == transform {$a .= "@_\n"} [qw(a b)], [1..2];

  ok $a eq << 'end';
b a
a b
end
 }


# 3

 {my $a = '';

  ok 3 == transform {$a .= "@_\n"} [qw(a b c)], [1..3];

  ok $a eq << 'end';
b c a
c a b
a b c
end
 }


# 4

 {my $a = '';

  ok 4 == transform {$a .= "@_\n"} [qw(a b c d)], [1..4];

  ok $a eq << 'end';
b c d a
c d a b
d a b c
a b c d
end
 }

# 4a

 {my $a = '';

  ok 4 == transform {$a .= "@_\n"} [qw(a b c d)], [[1..4]];

  ok $a eq << 'end';
b c d a
c d a b
d a b c
a b c d
end
 }


# 4b

 {my $a = '';

  ok 2 == transform {$a .= "@_\n"} ['a'..'d'], [[1,3], [2,4]];

  ok $a eq << 'end';
c d a b
a b c d
end
 }


# 4c

 {my $a = '';

  ok 4 == transform {$a .= "@_\n"} [qw(a b c d)], [1..2], [3..4];

  ok $a eq << 'end';
b a c d
a b d c
b a d c
a b c d
end
 }


# 26

 {my $a = '';

  ok 26 == transform {$a .= "@_\n"} ['a'..'z'], [1..26];

  ok $a eq << 'end';
b c d e f g h i j k l m n o p q r s t u v w x y z a
c d e f g h i j k l m n o p q r s t u v w x y z a b
d e f g h i j k l m n o p q r s t u v w x y z a b c
e f g h i j k l m n o p q r s t u v w x y z a b c d
f g h i j k l m n o p q r s t u v w x y z a b c d e
g h i j k l m n o p q r s t u v w x y z a b c d e f
h i j k l m n o p q r s t u v w x y z a b c d e f g
i j k l m n o p q r s t u v w x y z a b c d e f g h
j k l m n o p q r s t u v w x y z a b c d e f g h i
k l m n o p q r s t u v w x y z a b c d e f g h i j
l m n o p q r s t u v w x y z a b c d e f g h i j k
m n o p q r s t u v w x y z a b c d e f g h i j k l
n o p q r s t u v w x y z a b c d e f g h i j k l m
o p q r s t u v w x y z a b c d e f g h i j k l m n
p q r s t u v w x y z a b c d e f g h i j k l m n o
q r s t u v w x y z a b c d e f g h i j k l m n o p
r s t u v w x y z a b c d e f g h i j k l m n o p q
s t u v w x y z a b c d e f g h i j k l m n o p q r
t u v w x y z a b c d e f g h i j k l m n o p q r s
u v w x y z a b c d e f g h i j k l m n o p q r s t
v w x y z a b c d e f g h i j k l m n o p q r s t u
w x y z a b c d e f g h i j k l m n o p q r s t u v
x y z a b c d e f g h i j k l m n o p q r s t u v w
y z a b c d e f g h i j k l m n o p q r s t u v w x
z a b c d e f g h i j k l m n o p q r s t u v w x y
a b c d e f g h i j k l m n o p q r s t u v w x y z
end
 }

