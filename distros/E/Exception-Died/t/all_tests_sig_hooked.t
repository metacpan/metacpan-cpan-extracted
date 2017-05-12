#!/usr/bin/perl

use 5.006;
use strict;
use warnings;

use Test::Unit::Lite;
use Test::Assert;

use Exception::Base max_arg_nums => 0, max_arg_len => 200, verbosity => 4,
    'Exception::DiedTest::Warning';
use Exception::Died '%SIG' => 'die', verbosity => 4;
use Exception::Assertion verbosity => 4;

local $SIG{__WARN__} = sub { Exception::DiedTest::Warning->throw( join('', @_), ignore_level => 1 ) };

Test::Unit::HarnessUnit->new->start('Test::Unit::Lite::AllTests');
