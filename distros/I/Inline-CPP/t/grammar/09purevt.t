use strict;
use warnings;
use Test::More;

# Test pure virtual functions (abstract classes).
use Inline CPP => <<'END';

class Abstract {
  public:
        virtual char *text() = 0;
        virtual int greet(char *name) {
        printf("# Hello, %s.\n", name);
        return 17;
    }
};

class Impl : public Abstract {
  public:
    Impl() {}
    ~Impl() {}
    virtual char *text() { return "Hello from Impl!"; }
};


END

my $o = new_ok( 'Impl' );
is(
    $o->text, 'Hello from Impl!',
    "Resolved virtual member function from self."
);

is(
    $o->greet('Neil'), 17,
    "Inherited member function from parent."
);

my $p;
eval{ $p = Abstract->new(); };
if( $@ ) {
    like(
        $@,
        qr/^Can't locate object method "new" via package "([^:]+::)*Abstract"/,
        "Classes with pure virtual functions cannot be instantiated."
    );
} else {
    not_ok(
        "Abstract class with pure virtual function should not instantiate."
    );
}


done_testing();
