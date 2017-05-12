use strict;
use warnings;
use Test::More tests => 28;

use Inline (CPP => 'DATA', classes => sub { join('::', split('__', shift)); } );

can_ok 'Inline::Test::Parent', 'new';
my $parent_object = new_ok 'Inline::Test::Parent';
is ref($parent_object), 'Inline::Test::Parent', 'Our "Inline__Test__Parent" is a "Inline::Test::Parent"';
can_ok 'Inline::Test::Parent', 'parent_method';
is $parent_object->parent_method(), 'RETVAL FROM parent_method()', 'Proper object method association from Inline::Test::Parent.';

can_ok 'Inline::Test::Child1', 'new';
my $child1_object = new_ok 'Inline::Test::Child1';
is ref($child1_object), 'Inline::Test::Child1', 'Our "Inline__Test__Child1" is a "Inline::Test::Child1"';
can_ok 'Inline::Test::Child1', 'child1_method';
is $child1_object->child1_method(), 'RETVAL FROM child1_method()', 'Proper object method association from Inline::Test::Child1.';
can_ok 'Inline::Test::Child1', 'parent_method';
is $child1_object->parent_method(), 'RETVAL FROM parent_method()', 'Proper Inline::Test::Child1 object method inheritance from Inline::Test::Parent.';

can_ok 'Inline::Test::Child2', 'new';
my $child2_object = new_ok 'Inline::Test::Child2';
is ref($child2_object), 'Inline::Test::Child2', 'Our "Inline__Test__Child2" is a "Inline::Test::Child2"';
can_ok 'Inline::Test::Child2', 'child2_method';
is $child2_object->child2_method(), 'RETVAL FROM child2_method()', 'Proper object method association from Inline::Test::Child2.';
can_ok 'Inline::Test::Child2', 'parent_method';
is $child2_object->parent_method(), 'RETVAL FROM parent_method()', 'Proper Inline::Test::Child2 object method inheritance from Inline::Test::Parent.';

can_ok 'Inline::Test::Grandchild', 'new';
my $grandchild_object = new_ok 'Inline::Test::Grandchild';
is ref($grandchild_object), 'Inline::Test::Grandchild', 'Our "Inline__Test__Grandchild" is a "Inline::Test::Grandchild"';
can_ok 'Inline::Test::Grandchild', 'grandchild_method';
is $grandchild_object->grandchild_method(), 'RETVAL FROM grandchild_method()', 'Proper object method association from Inline::Test::Grandchild.';
can_ok 'Inline::Test::Grandchild', 'child1_method';
is $grandchild_object->child1_method(), 'RETVAL FROM child1_method()', 'Proper Inline::Test::Grandchild object method inheritance from Inline::Test::Child1.';
can_ok 'Inline::Test::Grandchild', 'parent_method';
is $grandchild_object->parent_method(), 'RETVAL FROM parent_method()', 'Proper Inline::Test::Grandchild object method inheritance from Inline::Test::Parent.';

done_testing();

__DATA__
__CPP__

class Inline__Test__Parent
{
public:
    SV* parent_method() { return(newSVpv("RETVAL FROM parent_method()", 27)); }
    Inline__Test__Parent() {}
    ~Inline__Test__Parent() {}
};

class Inline__Test__Child1: public Inline__Test__Parent
{
public:
    SV* child1_method() { return(newSVpv("RETVAL FROM child1_method()", 27)); }
    Inline__Test__Child1() {}
    ~Inline__Test__Child1() {}
};

class Inline__Test__Child2: public Inline__Test__Parent
{
public:
    SV* child2_method() { return(newSVpv("RETVAL FROM child2_method()", 27)); }
    Inline__Test__Child2() {}
    ~Inline__Test__Child2() {}
};

class Inline__Test__Grandchild: public Inline__Test__Child1
{
public:
    SV* grandchild_method() { return(newSVpv("RETVAL FROM grandchild_method()", 31)); }
    Inline__Test__Grandchild() {}
    ~Inline__Test__Grandchild() {}
};
