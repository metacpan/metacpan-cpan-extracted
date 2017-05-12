#!/usr/bin/perl -w
use strict;
use warnings;

use Test::More tests => 3;

use_ok qw(Gapp::Form::Stash);

my $o = Gapp::Form::Stash->new;

isa_ok $o, 'Gapp::Form::Stash';

$o->store( 'data', { foo => 'bar' } );

is_deeply $o->fetch( 'data' ), { foo => 'bar' }, 'stored/retrieved data';