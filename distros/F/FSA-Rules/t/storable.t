#!/usr/bin/perl -w

use strict;
use Test::More;
use Carp;
$SIG{__DIE__} = \&Carp::confess;
BEGIN {
    eval 'use Storable 2.05 qw(freeze thaw)';
    plan skip_all => 'Storable 2.05 or later cannot be loaded.' if $@;

    eval 'use B::Deparse 0.61';
    plan skip_all => 'B::Deparse 0.61 or later cannot be loaded.' if $@;

    plan tests => 12;
    use_ok 'FSA::Rules' or die;
}

$Storable::Deparse = $Storable::Deparse || 1;
$Storable::Eval    = $Storable::Eval || 1;

ok my $fsa = FSA::Rules->new(
    0 => { rules => [ 1 => [ 1, sub { shift->machine->{count}++ } ] ] },
    1 => { rules => [ 0 => [ 1, sub { $_[0]->done($_[0]->machine->{count} == 3 ) } ] ] },
),'Construct a rules object for serialization';

isa_ok $fsa, 'FSA::Rules';
is $fsa->run, $fsa, '... Run should return the FSA object';
is $fsa->{count}, 3,
    '... And it should have run through the proper number of iterations.';

ok my $frozen = freeze($fsa), 'Freeze the FSA object';
ok $fsa = thaw($frozen), 'Thaw the FSA object';
isa_ok $fsa, 'FSA::Rules', 'The thawed object';
is $fsa->{count}, 3,
    '... And it should still have its internal data';

$fsa->{count} = 0;
is $fsa->reset, $fsa, '... We should be able to reset';

is $fsa->run, $fsa, '... Run should still return the FSA object';
is $fsa->{count}, 3,
    '... And it should have run through the proper number of iterations.';

