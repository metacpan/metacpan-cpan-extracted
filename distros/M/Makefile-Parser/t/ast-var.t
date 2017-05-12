use strict;
use warnings;
use Test::More tests => 6;
use Makefile::AST::Variable;

my $var = Makefile::AST::Variable->new(
    { name => 'foo',
      value => 'hello',
      flavor => 'simple',
      origin => 'makefile',
    }
);
ok $var, 'var obj ok';
isa_ok $var, 'Makefile::AST::Variable', 'var class ok';
is $var->name, 'foo';
is $var->value, 'hello';
is $var->flavor, 'simple';
is $var->origin, 'makefile';



