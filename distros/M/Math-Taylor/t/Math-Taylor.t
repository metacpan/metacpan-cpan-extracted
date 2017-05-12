# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Math-Taylor.t'

#########################
use strict;
use warnings;

use Test::More tests => 27;
BEGIN { use_ok('Math::Taylor') };

#########################

my $taylor;

###################
# Object creation

eval { $taylor = Math::Taylor->new() };
ok($@, 'Cannot create obj without function.');

eval { $taylor = Math::Taylor->new(function => 'x*2') };
ok(
  (not $@ and ref($taylor) eq 'Math::Taylor'),
  'Can create obj with string function.'
);

eval {
     my $obj = Math::Symbolic->parse_from_string('x*2');
     $taylor = Math::Taylor->new(function => $obj);
};
ok(
  (not $@ and ref($taylor) eq 'Math::Taylor'),
  'Can create obj with obj function.'
);

#############
# Accessors

ok(
  ref($taylor->function()) eq 'Math::Symbolic::Operator',
  'Accessor function() get'
);
ok(
  ref($taylor->function('2')) eq 'Math::Symbolic::Constant',
  'Accessor function() set'
);

ok(
  ($taylor->point() == 0),
  'Accessor point() get'
);
ok(
  $taylor->point('3') == 3,
  'Accessor function() set'
);
ok(
  $taylor->point() == 3,
  'Accessor point() get'
);

ok(
  ($taylor->variable()->to_string() eq 'x'),
  'Accessor variable() get'
);

eval { $taylor->variable('x') };
ok(
  $@,
  "Cannot set to variable which isn't contained in the function"
);

$taylor->function('x*2');
ok(
  ref($taylor->variable('x')) eq 'Math::Symbolic::Variable',
  'Accessor variable() set'
);



##################
# Cloning

$taylor = Math::Taylor->new(function => 'x*2', point => '3');
my $clone;
eval { $clone = $taylor->new() };
ok(
  (not $@ and ref($clone) eq 'Math::Taylor' and $clone->point() == 3),
  'Plain cloning.'
);

eval { $clone = $taylor->new(point => '4') };
ok(
  (not $@ and ref($clone) eq 'Math::Taylor' and $clone->point() == 4),
  'Cloning with attributes.'
);


########################
# taylor_poly

$taylor = Math::Taylor->new(function => 'x*2', point => '3');
my $poly;
eval { $poly = $taylor->taylor_poly(0) };
ok(
  !$@,
  "taylor_poly doesn't complain."
);
ok(
  defined($poly) and ref($poly) =~ /^Math::Symbolic/,
  "taylor_poly returns Math::Symbolic tree."
);

ok(
  $poly->value(x => 5) == 6,
  "taylor_poly(0)"
);

eval { $poly = $taylor->taylor_poly(1) };
ok(
  (!$@ and $poly->value(x => 5) == 6+2*5-6),
  "taylor_poly(1)"
);

eval { $poly = $taylor->taylor_poly(2) };
ok(
  (!$@ and $poly->value(x => 5) == 6+2*5-6+0),
  "taylor_poly(2)"
);


#############
# Remainders

$taylor = Math::Taylor->new(function => 'x^2*2', point => '-3');
my $rem;
eval { $rem = $taylor->remainder(0, 'theta1'); };
ok(
  (!$@ and defined($rem) and ref($rem) =~ /^Math::Symbolic/),
  'remainder() returns M::S tree'
);
ok(
  (grep {$_ eq 'theta1'} $rem->explicit_signature()),
  'remainder() contains range var'
);
eval { $rem = $taylor->remainder(); };
ok(
  (!$@),
  'remainder() without args'
);

my $rem2 = $taylor->remainder(1, 'theta');

my $val  = $rem->value(x => 2, theta => 0.3);
my $val2 = $rem2->value(x => 2, theta => 0.3);

use constant EP => 0.00001;
ok(
  (!$@ and $val <= EP()+$val2 and $val >= $val2-EP() ),
  'remainder(1, "theta") equivalent to remainder()'
);

$taylor->remainder_type('cauchy');
eval { $rem = $taylor->remainder(0, 'theta1'); };
ok(
  (!$@ and defined($rem) and ref($rem) =~ /^Math::Symbolic/),
  'remainder() returns M::S tree'
);
ok(
  (grep {$_ eq 'theta1'} $rem->explicit_signature()),
  'remainder() contains range var'
);
eval { $rem = $taylor->remainder(); };
ok(
  (!$@),
  'remainder() without args'
);

$rem2 = $taylor->remainder(1, 'theta');

$val  = $rem->value(x => 2, theta => 0.3);
$val2 = $rem2->value(x => 2, theta => 0.3);

ok(
  (!$@ and $val <= EP()+$val2 and $val >= $val2-EP() ),
  'remainder(1, "theta") equivalent to remainder()'
);



