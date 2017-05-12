package t::lib::Test;

use strict;
use warnings;
use parent 'Test::Builder::Module';

use Test::More;
use Test::Differences;
use Devel::REPL;

our @EXPORT = (
    @Test::More::EXPORT,
    @Test::Differences::EXPORT,
    qw(
        repl_eval_line
    )
);

sub import {
    unshift @INC, 't/lib';

    strict->import;
    warnings->import;

    goto &Test::Builder::Module::import;
}

1;
