use strict;
use warnings;

use Test::More tests => 2;

use Input::Validator;

my $v = Input::Validator->new;

$v->field('foo');
$v->field('bar')->multiple(1)->inflate(sub { +{id => $_} });
$v->when('foo')->regexp(qr/^1$/)
  ->then(sub { shift->field('bar')->required(1) });

ok $v->validate({foo => 1, bar => [1, 2, 3, 4, 5]}), 'valid params';
is_deeply $v->values, {foo => 1, bar => [map { +{id => $_} } 1 .. 5]},
  'proper values';
