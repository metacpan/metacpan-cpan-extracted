#!/usr/bin/perl

use 5.006;

use strict;
use warnings;

use Test::Unit::Lite;

use Exception::Base
    max_arg_nums => 0, max_arg_len => 200, verbosity => 4;
use Exception::Warning '%SIG' => 'die';

Test::Unit::HarnessUnit->new->start('Test::Unit::Lite::AllTests');
