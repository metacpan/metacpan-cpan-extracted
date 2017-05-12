use Test::More;
use strict; use warnings FATAL => 'all';

{ package
  testing::Role::CaseMap;
 use Moo;

 has casemap => (
   is => 'ro',
   default => sub { 'ascii' },
 );

 with 'IRC::Toolkit::Role::CaseMap';

}


my $o = testing::Role::CaseMap->new;
can_ok( $o, $_ ) for qw/ lower upper equal /;


cmp_ok( $o->lower('ABCdef{}'), 'eq', 'abcdef{}',
  'lower() ok'
);

cmp_ok( $o->upper('abc[]DEF'), 'eq', 'ABC[]DEF',
  'upper() ok'
);

ok( $o->equal('abc[]DEF', 'ABC[]def'), 
  'equal() ok'
);

ok( !$o->equal('abcdef[]', 'abc[]def'),
  '!equal() ok'
);

done_testing;
