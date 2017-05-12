
use strict;
use warnings;
use constant EPSILON => 1e-5;
#########################

use Test::More tests => 18;
use_ok('Math::SymbolicX::Inline');

#use lib 'lib';
#use Math::SymbolicX::Inline;
#our $Count = 0;
#sub ok {print ++$Count . ($_[0]?" okay":"  bad"); print " => $_[1]\n";}

eval {
    Math::SymbolicX::Inline->import(<<'HERE');
foo = x * bar
bar = partial_derivative(x^2, x)
x (:=) arg0 + 1
HERE
};
ok( !$@,          'synopsis' );
ok( bar(3) == 8,  'synopsis prints correct results (1)' );
ok( foo(3) == 32, 'synopsis prints correct results (2)' );
eval { x(3) };
ok( defined $@, 'synopsis throws correct errors' );

eval {
    Math::SymbolicX::Inline->import(<<'HERE');
myfunction = partial_derivative( sin(arg0) * sin(arg0), arg0 )
HERE
};
warn $@ if $@;
ok( !$@, 'example 1' );
ok(
    (
              myfunction(2) - EPSILON < -0.756802495307928
          and myfunction(2) + EPSILON > -0.756802495307928
    ),
    'example 1 prints correct results'
);

my $function = 'sin';
eval {
    Math::SymbolicX::Inline->import(<<HERE);
# Our function:
myfunction2 = partial_derivative(inner, x)
# Supportive declarations:
inner (=) $function(x*y)^2
x (:=) arg0
y (:=) arg1
HERE
};
ok( !$@, 'example 2' );
ok(
    (
              myfunction2( 2, 5 ) - EPSILON < 4.56472625363814
          and myfunction2( 2, 5 ) + EPSILON > 4.56472625363814
    ),
    'example 2 prints correct results'
);

$function = 'tan';
eval {
    Math::SymbolicX::Inline->import(<<HERE);
# Our function:
myfunction3 = partial_derivative(inner, x)
# Supportive declarations:
inner (=) $function(x*y)^2
x (:=) arg0
y (:=) arg1
HERE
};
ok( !$@, 'example 3' );
ok(
    (
              myfunction3( 2, 7 ) - EPSILON < 5424.62052876086
          and myfunction3( 2, 7 ) + EPSILON > 5424.62052876086
    ),
    'example 3 prints correct results'
);
eval { inner( 2, 7 ) };
ok( $@, 'example 3 does not define private functions' );

eval {
    Math::SymbolicX::Inline->import(<<HERE);
# Our function:
myfunction4 =
		partial_derivative(inner, x)
# Supportive declarations:
inner(=)$function(x*y)^2
x (:=)


arg0
y             (:=) arg1
HERE
};
ok( !$@, 'example 3 is whitespace insensitive' );

eval {
    Math::SymbolicX::Inline->import(<<HERE);
# Our function:
myfunction5
=partial_derivative(inner, x)
# Supportive declarations:
inner(=)$function(x*y)^2
x (:=)


arg0
y             (:=) arg1
HERE
};
ok( $@, 'example 3 is mostly whitespace insensitive ;)' );

eval {
    Math::SymbolicX::Inline->import(<<HERE);
y (:=) arg1
x (:=) arg0
# Our function:
myfunction6 = partial_derivative(inner, x)
# Supportive declarations:
inner (=) $function(x*y)^2
HERE
};
ok( !$@, 'example 4 (order)' );
ok(
    (
              myfunction6( 2, 7 ) - EPSILON < 5424.62052876086
          and myfunction6( 2, 7 ) + EPSILON > 5424.62052876086
    ),
    'example 4 prints correct results'
);

eval {
    Math::SymbolicX::Inline->import(<<"HERE");
fancy = partial_derivative((y*x)^((x^2/y)+5*x), x)
x_inner (:=) (arg0-arg1)*arg2
x (:=) partial_derivative(x_inner^2, arg0)
y (:=) x*(arg1-2)
HERE
};
ok( !$@, 'fancy example compiles (wow!)' );
ok(
    (
              fancy( 6.4, 4.2, 0.1 ) - EPSILON < -7.23092504324084
          and fancy( 6.4, 4.2, 0.1 ) + EPSILON > -7.23092504324084
    ),
    'example 4 prints correct results'
);

