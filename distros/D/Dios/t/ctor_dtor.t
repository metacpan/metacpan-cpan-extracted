use Dios;
use Test::More;

plan tests => 10;

my $NAME = 'Damian';

class Base1 {
    shared $.name;

    method basic { return $name }

    submethod BUILD (:$call_me) {
        $name = $call_me;
    }

    submethod DESTROY {
        ::pass 'Base1 destroy';
    }
}

class Base2 {
    shared $.name;

    method more_basic { return $name }

    submethod BUILD (:$or_call_me) {
        $name = $or_call_me;
    }

    submethod DESTROY (  ) {
        ::pass 'Base2 destroy';
    }
}

class Demo is Base1 is Base2 {
    has Str $.name is required;

    method foo ($this: Str $newname, Int|Undef :$other) {
        ::is $name, $NAME => 'Name correct';

        $name = 'Other';
        ::is $this->get_name, 'Other' => 'Assignment to name correct';

        return 1;
    }

    submethod DESTROY () {
        ::pass 'Demo destroy';
    }
}

my $obj = Demo->new({ name => $NAME, call_me=>'basic', or_call_me => 'more basic' });

::is $obj->basic, 'basic' => 'Inherited Base1 correctly';
::is $obj->more_basic, 'more basic' => 'Inherited Base2 correctly';

::is $obj->foo('me'), 1      => 'Called foo() correctly';
::is $obj->get_name, 'Other' => 'Retained updated name correctly';

::ok !defined eval{ $obj->set_name('etc'); 1 }, => 'Setter failed, as expected';

END { ::done_testing() }
