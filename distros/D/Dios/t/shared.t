use Dios;
use Test::More;

plan tests => 20;

my $NAME = 'Damian';

class Base1 {
    shared $.name where { length > 0 } = 'Base1';

    method basic { return $name }
}

class Base2 {
    shared $.name is rw //= 'Base2';

    method more_basic { return $name }
}

class Demo is Base1 is Base2 {
    shared Str $.name = 'Demo';
}

my $obj = Demo->new;

::is $obj->basic, 'Base1' => 'Inherited Base1 correctly';
::is $obj->more_basic, 'Base2' => 'Inherited Base2 correctly';

::is $obj->get_name,        'Demo'  => "Accessed object's name correctly";
::is $obj->Base2::get_name, 'Base2' => "Accessed object's base 2 name correctly";
::is $obj->Base1::get_name, 'Base1' => "Accessed object's base 1 name correctly";

::is 'Demo'->get_name,  'Demo'  => "Accessed class's name correctly";
::is 'Base2'->get_name, 'Base2' => "Accessed class's base 2 name correctly";
::is 'Base1'->get_name, 'Base1' => "Accessed class's base 1 name correctly";

::ok !defined eval{ 'Base1'->set_name('etc'); 1 }, => 'Class setter failed, as expected';
::is 'Base1'->get_name,     'Base1' => "Accessed class's base 2 name correctly";
::is $obj->Base1::get_name, 'Base1' => "Object's base 2 name correctly";
::is 'Base2'->get_name,     'Base2' => "Accessed class's base 2 name correctly";
::is $obj->Base2::get_name, 'Base2' => "Object's base 2 name correctly";

::ok do{ $obj->set_name('ad hoc'); 1 } => 'Object setter succeeded, as expected';
::is 'Base1'->get_name,     'Base1' => "Accessed class's base 2 name correctly";
::is $obj->Base1::get_name, 'Base1' => "Object's base 2 name correctly";
::is 'Base2'->get_name,     'ad hoc' => "Accessed class's base 2 name correctly";
::is $obj->Base2::get_name, 'ad hoc' => "Object's base 2 name correctly";

::ok  eval { $obj->set_name('a'); }, "Constraint passed";
::ok !eval { $obj->set_name('');  }, "Constraint failed";

END { ::done_testing() }

