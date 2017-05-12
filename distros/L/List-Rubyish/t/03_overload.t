package List::Rubyish::Test;
use strict;
use warnings;
use base qw/Test::Class/;

use Test::More;
use List::Rubyish;

__PACKAGE__->runtests;

sub test_add : Tests(9) {
    my $obj    = List::Rubyish->new([qw/ 1 2 3 /]);
    my $obj2   = List::Rubyish->new(['4']);
    my $lopnor = List::Rubyish->new(['lopnor']);

    $obj += $obj2;
    is_deeply $obj->to_a, [qw/ 1 2 3 4 /];

    $obj += $lopnor;
    is_deeply $obj->to_a, [qw/ 1 2 3 4 lopnor /];

    $obj += 'foo';
    is_deeply $obj->to_a, [qw/ 1 2 3 4 lopnor foo /];

    $obj += ['bar'];
    is_deeply $obj->to_a, [qw/ 1 2 3 4 lopnor foo bar /];

    $obj += 99;
    is_deeply $obj->to_a, [qw/ 1 2 3 4 lopnor foo bar 99 /];

    $obj = 99 + $obj;
    is_deeply $obj->to_a, [qw/ 99 1 2 3 4 lopnor foo bar 99 /];

    $obj = 'foo' + $obj;
    is_deeply $obj->to_a, [qw/ foo 99 1 2 3 4 lopnor foo bar 99 /];

    $obj = $lopnor + $obj;
    is_deeply $obj->to_a, [qw/ lopnor foo 99 1 2 3 4 lopnor foo bar 99 /];

    is_deeply $lopnor->to_a, [qw/ lopnor /];
}

sub test_push : Tests(5) {
    my $obj    = List::Rubyish->new([qw/ 1 2 3 /]);
    my $obj2   = List::Rubyish->new(['4']);
    my $lopnor = List::Rubyish->new(['lopnor']);

    no warnings 'void'; ## wtf?

    $obj << $obj2;
    is_deeply $obj->to_a, [qw/ 1 2 3 4 /];

    $obj << $lopnor;
    is_deeply $obj->to_a, [qw/ 1 2 3 4 lopnor /];

    $obj << 'foo';
    is_deeply $obj->to_a, [qw/ 1 2 3 4 lopnor foo /];

    $obj << ['bar'];
    is_deeply $obj->to_a, [qw/ 1 2 3 4 lopnor foo bar /];

    $obj << 99;
    is_deeply $obj->to_a, [qw/ 1 2 3 4 lopnor foo bar 99 /];
}

sub test_unshift : Tests(5) {
    my $obj    = List::Rubyish->new([qw/ 1 2 3 /]);
    my $obj2   = List::Rubyish->new(['4', '5']);
    my $lopnor = List::Rubyish->new(['lopnor']);

    no warnings 'void'; ## wtf?

    $obj2 >> $obj;
    is_deeply $obj->to_a, [qw/ 4 5 1 2 3 /];

    $lopnor >> $obj;
    is_deeply $obj->to_a, [qw/ lopnor 4 5 1 2 3 /];

    'foo' >> $obj;
    is_deeply $obj->to_a, [qw/ foo lopnor 4 5 1 2 3 /];

    ['bar'] >> $obj;
    is_deeply $obj->to_a, [qw/ bar foo lopnor 4 5 1 2 3 /];

    99 >> $obj;
    is_deeply $obj->to_a, [qw/ 99 bar foo lopnor 4 5 1 2 3 /];
}
