#!/usr/bin/env perl
# test the lexicon index.

use warnings;
use strict;
use lib 'lib', '../lib';

use Test::More tests => 1;

use Log::Report;
use Log::Report::Dispatcher;

my $stack;

my $start = __LINE__;
sub hhh(@) { $stack = Log::Report::Dispatcher->collectStack(3) }
sub ggg(@) { shift; hhh(@_) }
sub fff(@) { ggg(reverse @_) }

fff(42, 3.2, "this is a text");

is_deeply($stack,
  [ [ 'main::hhh(3.2, 42)',                   $0, $start+2 ]
  , [ 'main::ggg("this is a text", 3.2, 42)', $0, $start+3 ]
  , [ 'main::fff(42, 3.2, "this is a text")', $0, $start+5 ]
  ]
);
