use strict;
use warnings;
use Test::More 'no_plan';
use lib 't/lib';
use CLR;

my $root_a  = CLR->new;
my $child_a = $root_a->new(status  => sub { 'OK!' });
my $child_b = $child_a->new(status => sub { 'ok?' });

eval { $root_a->status };
like($@, qr/\Aunknown method status called on CLR obj/, "no status on root");

is(
  $child_a->status,
  'OK!',
  'child object answers status method',
);

is(
  $child_b->status,
  'ok?',
  'grandchild object answers status method, too',
);

{
  my $method = 'status';
  is(
    $child_b->$method,
    'ok?',
    'grandchild object answers status method (as str), too',
  );
}

$child_a->set(generation => 2);

my $call;

is(
  $root_a->get('generation'),
  undef,
  'no generation value on root',
);

is(
  $child_a->get('generation'),
  2,
  'we got a generation value from child',
);

is(
  $child_a->get('generation'),
  2,
  '...which is inherited by the grandchild',
);

