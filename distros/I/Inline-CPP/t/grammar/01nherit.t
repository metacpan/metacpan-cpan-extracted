use strict;
use warnings;
use Test::More;

# this is needed to avoid false passes if was done first without 'info'
use Inline CPP => config => force_build => 1, clean_after_build => 0;

# Testing proper handling of inherited object methods.

use Inline CPP => <<'END';

class Foo {
 public:
   Foo() {
    secret=0;
   }

   ~Foo() { }

   int get_secret() { return secret; }
   void set_secret(int s) { secret = s; }

 protected:
   int secret;
};

class Bar : public Foo {
 public:
   Bar(int s) { secret = s; }
   ~Bar() {  }

   void set_secret(int s) { secret = s * 2; }
};

END

# If it works, it will print this. Otherwise it won't.
ok(1);

# Test Foo.
my $o = new_ok( 'Foo' );
is( $o->get_secret(), 0, "Foo: Object getter." );
$o->set_secret(539);
is( $o->get_secret(), 539, "Foo: Object setter." );


# Test Bar.


my $p = new_ok( 'Bar', [ 11 ] );
is(
    $p->get_secret(), 11,
    "Bar: Overrides constructor, inherits accessor from Foo."
);

$p->set_secret( 21 );
is( $p->get_secret(), 42, "Bar: Overrides setter." );

done_testing();
