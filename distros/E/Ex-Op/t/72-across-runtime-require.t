#!perl
use 5.010;
use strict;
use warnings;
use lib 't/lib';
use Test::More;
use EO::Ops;

sub early { my $r = Ops::Late::late(1); $r }

is_deeply( op_calls('main::early'), [0, 1], 'a call compiled before its module is loaded is an ordinary call' );

require Ops::Late;
Ops::Late->import('late');

is( early(), 'late 1', '... and works once the module is loaded' );
is_deeply( op_calls('main::early'), [0, 1], '... and stays ordinary' );

my $later = eval q{ sub { my $r = late(2); $r } } or die $@;
is( $later->(), 'late 2', 'a call compiled after the run-time import' );
is_deeply( op_calls($later), [1, 0], '... is an op call' );

done_testing;
