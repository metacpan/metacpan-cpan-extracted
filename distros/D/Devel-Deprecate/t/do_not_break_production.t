#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 4;
use lib 't/lib';
use TestDeprecate;

use Devel::Deprecate 'deprecate';

{
    local $ENV{HARNESS_ACTIVE};              # true means 'do run'
    local $ENV{PERL_DEVEL_DEPRECATE_OFF};    # true means 'do not run'
    check { deprecate() };
    ok !is_deprecated, 'If not testing, deprecate() should be a no-op';
}

{
    local $ENV{HARNESS_ACTIVE} = 1;          # true means 'do run'
    local $ENV{PERL_DEVEL_DEPRECATE_OFF};    # true means 'do not run'
    check { deprecate() };
    ok is_deprecated, 'If testing but not forced off, deprecate() should be active';
}

{
    local $ENV{HARNESS_ACTIVE};              # true means 'do run'
    local $ENV{PERL_DEVEL_DEPRECATE_OFF} = 1;    # true means 'do not run'
    check { deprecate() };
    ok !is_deprecated, 'If not testing and deprecate forced off, we have a no-op';
}

{
    local $ENV{HARNESS_ACTIVE}           = 1;    # true means 'do run'
    local $ENV{PERL_DEVEL_DEPRECATE_OFF} = 1;    # true means 'do not run'
    check { deprecate() };
    ok !is_deprecated, 'If testing and deprecate forced off, we still have a no-op';
}
