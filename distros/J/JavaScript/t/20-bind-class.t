#!perl

package Foo;

use Test::More tests => 25;

use Test::Exception;

use strict;
use warnings;

use JavaScript;

sub new {
    my $pkg = shift;
    $pkg = ref $pkg || $pkg;
    return bless {}, $pkg;
}

my $rt1 = JavaScript::Runtime->new();

# Check constructor and package stuff
{
    # If we don't define package assume same as name
    my $cx1 = $rt1->create_context();
    $cx1->bind_class(name => "Foo",
                     constructor => sub {
                         my $pkg = shift;
                         is($pkg, "Foo", "package is Foo in Foo constructor");
                         return Foo->new();
                     }
                 );
    my $o = $cx1->eval("new Foo();");
    isa_ok($o, "Foo", "new Foo(); returns instanceof Foo");

    $cx1->bind_class(name => "Bar",
                     constructor => sub {
                         my $pkg = shift;
                         is($pkg, "Foo", "package is Foo in Bar constructor");
                         return $pkg->new();
                     },
                     package => "Foo",
                 );
    my $p = $cx1->eval("new Bar()");
    isa_ok($o, "Foo", "new Bar() returns instanceof Foo");    
}

{
    # Default constructor
    # If we don't define package assume same as name
    my $cx1 = $rt1->create_context();
    $cx1->bind_class(name => "Foo");
    $cx1->bind_class(name => "Baz", package => "Foo");

    my $o = $cx1->eval("new Foo();");
    isa_ok($o, "Foo", "new Foo() returns instanceof Foo");
    $o = $cx1->eval("new Baz();");
    isa_ok($o, "Foo", "new Baz() returns instanceof Foo");

}

# Check fs and static_fs
{
    my $Foo_object_method = 0;
    sub object_method {
        my $self = shift;
        isa_ok($self, "Foo", "self is Foo in object_method");
        is($_[0], scalar @_, "1 arg in object_method");
        $Foo_object_method++;
    }
    
    my $Foo_class_method = 0;
    sub class_method {
        my $self = shift;
        is($self, "Foo", "self is Foo in class_method");
        is($_[0], scalar @_, "1 arg in class_method");
        $Foo_class_method++;
    }

    my $cx1 = $rt1->create_context();
    $cx1->bind_class(name => "Foo",
                     constructor => \&Foo::new,
                     fs => { object_method => \&Foo::object_method  },
                     static_fs => { class_method => \&Foo::class_method, },
                     package => "Foo",
                 );
    $cx1->eval("o = new Foo(); o.object_method(1)");

    if ($@ || $Foo_object_method == 0) {
        ok(0, "self is Foo in object_method");
        ok(0, "1 arg in object_method");
    }

    $cx1->eval("Foo.class_method(1);");

    if ($@ || $Foo_class_method == 0) {
        ok(0, "self is Foo in class_method");
        ok(0, "1 arg in class_method");
    }
}

# Check multiple instance methods
{
    sub fone {
        is($_[1], 1, "called fone");
    }

    sub ftwo {
        is($_[1], 2, "called ftwo");
    }
    
    my $cx1 = $rt1->create_context();
    $cx1->bind_class(name => "Foo",
                     constructor => "new",
                     fs => [qw(fone ftwo)],
                 );
    $cx1->eval("o = new Foo(); o.fone(1); o.ftwo(2)");
    if ($@) {
	ok(0, "called fone");
	ok(0, "called ftwo");
    }
}

# Check ps
{
    my $x = 5;
    sub get_x {
        my $self = shift;
        isa_ok($self, "Foo", "self is Foo in get_x");
        return $x;
    }

    sub set_x {
        my $self = shift;
        isa_ok($self, "Foo", "self is Foo in set_x");
        $x = shift;
    }

    sub get_y {
        my $self = shift;
        isa_ok($self, "Foo", "self is Foo in get_y");
        return 10;
    }

    my $cx1 = $rt1->create_context();
    $cx1->bind_class(name => "Foo",
                     constructor => \&Foo::new,
                     ps => { x => { getter => 'get_x',
                                    setter => \&Foo::set_x,
                               },
                             y => [qw(get_y)],
                        },
                 );

    my $r = $cx1->eval("a = new Foo(); f = a.x;");
    is($r, 5);
    $r = $cx1->eval("a = new Foo(); f = a.x; f++; a.x = f; f = a.x; a.x;");
    is($r, 6);
}

# Check static_ps
{
    my $z = 10;
    sub get_z {
        my $self = shift;
        is($self, "Foo", "self is Foo in get_z");
        return $z;
    }

    sub set_z {
        my $self = shift;
        is($self, "Foo", "self is Foo in set_z");
        $z = shift;
    }

    my $cx1 = $rt1->create_context();
    $cx1->bind_class(name => "Foo",
                     constructor => \&Foo::new,
                     static_ps => { z => [qw(get_z set_z)],
                               },
                 );
    my $r = $cx1->eval("Foo.z;");
    diag($@) if $@;
    is($r, 10, "Foo.z is 10");
    $cx1->eval("Foo.z = 11;");
    diag($@) if $@;
    is($z, 11, "Foo.z is 11 after assignment");
}

{
    # Check that static_ps and ps can coexist
    my $cx1 = $rt1->create_context();
    $cx1->bind_class(name => "Foo",
                     constructor => "new",
                     ps => { x => { getter => sub { return "x"; } } },
                     static_ps => { y => { getter => sub { return "y"; } } }
                     );
    is($cx1->eval("(new Foo()).x"), "x", "(new Foo()).x return x");
    diag($@) if $@;
    is($cx1->eval("Foo.y"), "y", "Foo.y returns y");
    diag($@) if $@;
}

#  LocalWords:  STDERR
