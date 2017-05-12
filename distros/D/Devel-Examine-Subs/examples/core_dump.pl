#!/usr/bin/perl
use strict;
use warnings FATAL => 'all';

use Devel::Examine::Subs;

my $des = Devel::Examine::Subs->new(file => 't/sample.data', engine => 'all');

$des->run({core_dump => 1});
