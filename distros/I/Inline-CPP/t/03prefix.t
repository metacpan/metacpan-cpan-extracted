use strict;
use warnings;
use Test::More tests => 4;

# Originally one of these tests was passing char* strings, there's no need
# to test strings, and doing so adds unnecessary complexity to the test.

ok(1);

# this is needed to avoid false passes if was done first without 'info'
use Inline CPP => config => force_build => 1, clean_after_build => 0;
use Inline CPP => DATA => prefix => 'Foo_';

is(identity( 100 ), 100, "prefix resolved." );
is(identity(identity( 200 )), 200, "prefix resolved in nested calls." );

is(Foo->new->dummy, "10", "prefixed object resolves." );

done_testing();

__END__
__CPP__

struct Foo {
  int dummy() { return 10; }
};

int Foo_identity( int in ) { return in; }

