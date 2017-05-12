use Test::More tests => 38;

use strict;
use warnings;

use Inline CPP => 'DATA';

note( 'Instantiating objects.' );
my @object_descriptions = (
    [
        my $parent1_obj = new_ok( 'Parent1', [], 'Parent1 object born:' ),
        [ qw/ Parent1      / ],
        [ qw/ do_something / ]
    ],
    [
        my $parent2_obj = new_ok( 'Parent2', [], 'Parent2 object born:' ),
        [ qw/ Parent2    /   ],
        [ qw/ do_another /   ]
    ],
    [
        my $child_obj = new_ok( 'Child',     [], 'Child object born:'   ),
        [ qw/ Child          Parent1         Parent2    / ],
        [ qw/ yet_another    do_something    do_another / ]
    ],
    [
        my $child2_obj = new_ok( 'Child2',   [], 'Child2 object born:'  ),
        [ qw/ Child2        Parent1          Parent2    / ],
        [ qw/ some_other    do_something     do_another / ]
    ],
);

note( 'Testing object lineage.' );
foreach my $obj_desc ( @object_descriptions ) {
    foreach my $class ( @{ $obj_desc->[1] } ) {
        ok(
            $obj_desc->[0]->isa( $class ),
            "UNIVERSAL::isa confirms $obj_desc->[1][0] object is a $class."
        );
    }
}

note( 'Testing object method capabilities (inheritance).' );
foreach my $obj_desc ( @object_descriptions ) {
    foreach my $func_name ( @{ $obj_desc->[2] } ) {
        can_ok( $obj_desc->[0], $func_name );
    }
}


note( 'Testing \@Class::ISA arrays.' );
is_deeply( \@Parent1::ISA, [ ], "\@Parent1::ISA: No inheritance." );
is_deeply( \@Parent2::ISA, [ ], "\@Parent2::ISA: No inheritance." );
TODO: {
    local $TODO = "Still researching why Child and Child2 inherit via main::";
    is_deeply(
        \@Child::ISA,   [ qw/ Parent1   Parent2 / ],
        "\@Child::ISA: Parent1, Parent2."
    );
    is_deeply(
        \@Child2::ISA,  [ qw/ Parent2   Parent1 / ],
        "\@Child2::ISA: Parent2, Parent1."
    );
}

my @method_tests = (
    [
        $parent1_obj,           # Object ref.
        'Parent1',              # Class name.
        {
            do_something => 51  # Method call and expected result.
        }
    ],
    [
        $parent2_obj,           # Object ref.
        'Parent2',              # Class name.
        {
            do_another   => 17  # Method call and expected result.
        }
    ],
    [
        $child_obj,             # Object ref.
        'Child',                # Class name.
        {
            yet_another  => 3,  # Method call and expected result.
            do_something => 51, # Inherited from Parent1: Call and expected.
            do_another   => 17, # Inherited from Parent2: Call and expected.
        },
    ],
    [
        $child2_obj,            # Object ref.
        'Child2',               # Class name.
        {
            some_other   => 4,  # Method call and expected result.
            do_something => 51, # Inherited from Parent1: Call and expected.
            do_another   => 17  # Inherited from Parent2: Call and expected.
        }
    ],
);

note( 'Testing that object methods return correct values' );
TODO: {
    foreach my $obj_task ( @method_tests ) {
        while( my( $method, $expect ) = each %{ $obj_task->[2] } ) {
            local $TODO =
                'Still working on why multiple inheritance is messed up.'
                if( $obj_task->[1] =~ /Child\d?/ );
            is(
                $obj_task->[0]->$method, $expect,
                "$obj_task->[1] object method $method " .
                "correctly returns $expect."
            );
        }
    }
}


# These tests are essentially repeats from code above, but with code that is
# more transparent to illustrate the issue as clearly as possible.

note( "\n\nPainfully simple so we don\'t miss it this time.\n\n" );
TODO: {
    is(
        $child_obj->yet_another, 3,
        'Child $obj->yet_another() should return 3.'
    );
    is(
        $child_obj->do_something, 51,
        'Child $obj->do_something() ' .
        'inherits from Parent1 and should return 51.'
    );
    {
        local $TODO = 'Inheritance foulup: Calling do_another() but getting' .
                      ' return value from do_something().';
        is(
            $child_obj->do_another, 17,
            'Child $obj->do_another() ' .
            'inherits from Parent2, and should return 17.'
        );
    }
    is(
        $child2_obj->some_other, 4,
        'Child2 $obj->some_other() should return 4.'
    );
    {
        local $TODO = 'Inheritance foulup: Calling do_something but getting' .
                      ' return value from do_another().';
        is(
            $child2_obj->do_something, 51,
            'Child2 $obj->do_something() ' .
            'inherited from Parent1 and should return 51.'
        );
    }
    is(
        $child2_obj->do_another, 17,
        'Child2 $obj->do_another() ' .
        'inherited from Parent2 and should return 17.'
    );
}
done_testing();

=cut

-------------------- email from Patrick ---------------
David,

I'm really no C++ expert, but I think the implementation is not viable
the way it is. If you create a
small C++ program that simulates Inline::CPP like this:

#include <stdio.h>

/* Your Child/Parent classes here "as is" */

int main(int argv, char **argc){
       Child *c = new Child() ;
       printf("%d\n", c->do_something()) ;
       printf("%d\n", c->do_another()) ;

       void *x = c ;
       printf("%d\n", ((Parent1 *)x)->do_something()) ;
       printf("%d\n", ((Parent2 *)x)->do_another()) ;
}

I gives the same error:
51
17
51
51

I think the problem is that you can't cast your pointer to either
Parent1 or Parent2 depending on
your needs because the bytes are not overlapped in memory. In the
definition of the Child object,
the Parent1 stuff is before the Parent2 stuff. To access the Parent2
stuff you probably need to
use an offset on the Child Pointer.

What's happening (I think) is that your are calling do_something()
both times because both methods
are at the same byte offset in there respective parent object. If you
add some member variables in
one of the Parent object before the method definitions you will
probably get crashes because the method
offset will no longer line up. I'm not sure if any of this is clear....

I think the correct way to do this is something like:

       printf("%d\n", ((Child *)x)->Parent1::do_something()) ;
       printf("%d\n", ((Child *)x)->Parent2::do_another()) ;

but that implies that your Parent functions know about Child, which is
not good...

Anyways, just some stuff to think about, unfortunately I don't have
any suggestions for you...


Patrick

--------------------------------

Email response from davido/daoswald:

Your explanation was excellent.

What needs to be happening is that, as Child inherits from Parent1 and
Parent2, the pointer should be cast as a Child type, like in this
modification of your test:

int main(int argv, char **argc){
      Child *c = new Child() ;
      printf("%d\n", c->do_something()) ;
      printf("%d\n", c->do_another()) ;

      void *x = c ;
      printf("%d\n", ((Child *)x)->do_something()) ;
      printf("%d\n", ((Child *)x)->do_another()) ;
}

...or in more idiomatic C++:

int main() {
   using std::cout;
   using std::endl;

   Child *c = new Child() ;
   cout << c->do_something() << endl;
   cout << c->do_another()   << endl;

   void *x = c ;
   cout <<  static_cast< Child* >(x)->do_something() << endl;
   cout <<  static_cast< Child* >(x)->do_another()   << endl;

   return 0;
}

Though I'm not much closer to a solution, at least your message
reminded me that we're dealing with void pointers to objects.  Maybe I
need to start looking at how and where the casting is being
accomplished.

------------------------------------

=cut

__END__
__CPP__

class Parent1 {
  public:
    Parent1() { }
    ~Parent1() { }

    virtual int do_something() { return 51; }
};

class Parent2 {
  public:
    Parent2();
    ~Parent2();

    virtual int do_another();
};

Parent2::Parent2() { }
Parent2::~Parent2() { }
int Parent2::do_another() { return 17; }

class Child : public Parent1, public Parent2 {
  public:
    Child() { }
    ~Child() { }

    int yet_another() { return 3; }
};

class Child2 : public Parent2, public Parent1 {
  public:
    Child2() { }
    ~Child2() { }

    int some_other() { return 4; }
};
