use Test::More;
use strict; use warnings FATAL => 'all';

{ package My::Defaults;
  use strict; use warnings FATAL => 'all';
  use parent 'List::Objects::WithUtils';
  sub import {
    my ($class) = @_;
    $class->SUPER::import(
      +{
        import => [ 'autobox', 'immarray' ],
        to     => 'My::Target',
      }
    )
  }
}
{ package My::Target;
  use strict; use warnings FATAL => 'all';
  use Test::More;

  BEGIN { My::Defaults->import }
  ok __PACKAGE__->can('immarray'), 'immarray ok';
  ok not( __PACKAGE__->can('array') ), 'omitted array ok';
  cmp_ok []->count, '==', 0, 'autobox ok';
}

done_testing;
