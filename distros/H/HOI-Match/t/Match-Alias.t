# Before 'make install' is performed this script should be runnable with
# 'make test'. After 'make install' it should work as 'perl HOI-Match.t'

#########################

use Test::More tests => 10;
BEGIN { use_ok('HOI::Match') };

#########################

sub sum {
    HOI::Match::pmatch(
        "h :: r" => sub { $h + sum($r) },
        "nil" => sub { 0 }
    )->(@_)
}
ok(sum([1, 2, 3, 4]) == 10);

sub head {
    HOI::Match::pmatch(
        "h :: _" => sub { $h }
    )->(@_)
}
my $res_head = head([1, 2, 3]);
ok(head([1, 2, 3]) == 1);

sub tail {
    HOI::Match::pmatch(
        "_ :: r" => sub { $r }
    )->(@_)
}
my $res_tail = tail([1, 2, 3]);
is_deeply($res_tail, [2, 3]);

sub point_extract {
    HOI::Match::pmatch(
        "point (x _) :: r" => sub { $x + point_extract($r) },
        "nil" => sub { 0 }
    )->(@_)
}
ok(
    point_extract(
        [ 
            {"type" => "point", "val" => [ 1, 2 ]},
            {"type" => "point", "val" => [ 2, 4 ]},
            {"type" => "point", "val" => [ 3, 6 ]},
        ]
    ) == 6
);

sub fact {
    HOI::Match::pmatch(
        "0" => sub { 1 },
        "x" => sub { $x * fact($x - 1) }
    )->(@_)
}
ok(fact(5) == 120);

sub alphabet {
    HOI::Match::pmatch(
        '"a"' => sub { 'a' },
        'x' => sub { alphabet(chr(ord($x)-1)).$x }
    )->(@_)
}
ok(alphabet('z') eq 'abcdefghijklmnopqrstuvwxyz');

sub ovld {
    HOI::Match::pmatch(
        'point (x y)' => sub { $x + $y },
        'point (x y z)' => sub { $x + $y + $z }
    )->(@_)
}
ok(ovld( { 'type' => 'point', 'val' => [ 1, 2 ] } ) == 3);
ok(ovld( { 'type' => 'point', 'val' => [ 1, 2, 3 ] } ) == 6);

sub strrev {
    HOI::Match::pmatch(
        '""' => sub { "" },
        'x:xs' => sub { strrev($xs).$x }
    )->(@_)
}

ok(strrev('abcde') eq 'edcba');
