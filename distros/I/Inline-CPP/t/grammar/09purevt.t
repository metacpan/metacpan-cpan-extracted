use strict;
use warnings;
use Test::More;
use FindBin;

# this is needed to avoid false passes if was done first without 'info'
use Inline CPP => config => force_build => 1, clean_after_build => 0,
  typemaps => "$FindBin::Bin/typemap.09purevt",
  ;

# Test pure virtual functions (abstract classes).
use Inline CPP => <<'END';

#ifdef __INLINE_CPP_STANDARD_HEADERS
#include <string>
#else
#include <string.h>
#endif

#ifdef __INLINE_CPP_NAMESPACE_STD
using namespace std;
#endif

class Abstract {
  public:
        Abstract() {}
        virtual char *text() = 0;
        virtual int greet(char *name) {
            printf("# Hello, %s.\n", name);
            return 17;
        }
        virtual string greet2() {
            string retval = "yo";
            return retval;
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

is(
    $o->greet2, "yo",
    "Inherited string member function from parent."
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
