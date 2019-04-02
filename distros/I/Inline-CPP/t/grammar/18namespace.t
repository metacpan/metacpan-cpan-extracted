use strict;
use warnings;
use Test::More;

# this is needed to avoid false passes if was done first without 'info'
use Inline CPP => config => force_build => 1, clean_after_build => 0;

## no critic (eval)

# Test implementation of C++ namespaces.

my $rv = eval <<'EOILCPP';
  use Inline CPP => q[
    namespace Bar {
      class Foo {
        public:
          Foo() : a(10) { }
          int fetch() { return a; }
        private:
          int a;
      };
    }
  ];
  1;
EOILCPP


TODO: {
  local $TODO = 'C++ namespace feature not yet implemented.';

  is( $rv, 1, 'Compilation succeeded.' );
  can_ok( 'Bar::Foo', qw( new fetch ) );

  my $bf = new_ok( 'Bar::Foo' );
  my $val = eval { $bf->fetch };
  ok( defined($val) && $val == 10, 'Bar::Foo->fetch obtained correct value.' );

};

done_testing();
