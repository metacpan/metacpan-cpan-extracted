#!/usr/bin/env perl

use Test::More tests => 4;

use_ok('Devel::REPL');
use_ok('Devel::REPL::Plugin::DataPrinter');

my $repl;
ok($repl = Devel::REPL->new, 'new Devel::REPL');
ok($repl->load_plugin('DataPrinter'), 'loaded DataPrinter plugin');
