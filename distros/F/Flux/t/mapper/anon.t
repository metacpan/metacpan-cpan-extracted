#!/usr/bin/perl

use strict;
use warnings;

use lib 'lib';
use Test::More;
use Test::Fatal;

use Flux::Mapper::Anon;

is exception { Flux::Mapper::Anon->new(cb => sub { return () }) }, undef;

my $mapper = Flux::Mapper::Anon->new(cb => sub { return shift() * 2 });
is $mapper->write(5), 10;

is scalar($mapper->commit), undef;
is_deeply [$mapper->commit], [];

done_testing;
