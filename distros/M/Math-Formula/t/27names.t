#!/usr/bin/env perl
  
use warnings;
use strict;
use utf8;

use Math::Formula ();
use Math::Formula::Context ();
use Test::More;

my $expr = Math::Formula->new(test => 1);

is_deeply $expr->_tokenize('mark'),       [ MF::NAME->new('mark') ];
is_deeply $expr->_tokenize('_mark_42'),   [ MF::NAME->new('_mark_42') ];

if($] =~ m/^5\.2[01]/)
{	diag "utf8 names are broken in 5.20";  # regexp issue: get double encoded in $+
}
else
{	is_deeply $expr->_tokenize('Зеленський'), [ MF::NAME->new('Зеленський') ];
}

is_deeply $expr->_tokenize('tic tac toe'), [MF::NAME->new('tic'), MF::NAME->new('tac'), MF::NAME->new('toe')];

my $context = Math::Formula::Context->new(name => 'test',
	formulas => { live => '42' },
);
ok defined $context, 'Testing existence';

is $context->value('live'), 42, '... live';
is $context->run('exists live')->token, 'true';
is $context->run('not exists live')->token, 'false';
is $context->run('exists green_man')->token, 'false', '... green man';
is $context->run('not exists green_man')->token, 'true';

is $context->run('live // green_man')->value, 42, 'default, not needed';
is $context->run('green_man // live')->value, 42, '... needed';
is $context->run('green_man // missing // no_not_here // 13')->value, 13, '... into constant';

done_testing;
