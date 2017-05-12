#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 16;
use Devel::Pragma qw(new_scope);

{
    BEGIN {
        is(new_scope(), 1, 'new_scope returns true the first time it is called in the outer scope');
    }

    BEGIN {
        is(new_scope(), 0, 'new_scope returns false the second time it is called in the outer scope');
    }

    BEGIN {
        is(new_scope('Test1'), 1, 'new_scope("Test1") returns true the first time it is called in the outer scope');
    }

    BEGIN {
        is(new_scope('Test1'), 0, 'new_scope("Test1") returns false the second time it is called in the outer scope');
    }

    {
        BEGIN {
            is(new_scope(), 1, 'new_scope returns true the first time it is called in a nested scope');
        }

        BEGIN {
            is(new_scope(), 0, 'new_scope returns false the second time it is called in a nested scope');
        }

        BEGIN {
            is(new_scope('Test1'), 1, 'new_scope("Test1") returns true the first time it is called in a nested scope');
        }

        BEGIN {
            is(new_scope('Test1'), 0, 'new_scope("Test1") returns false the second time it is called in a nested scope');
        }

        BEGIN {
            is(new_scope('Test2'), 1, 'new_scope("Test2") returns true the first time it is called in a nested scope');
        }

        BEGIN {
            is(new_scope('Test2'), 0, 'new_scope("Test2") returns false the second time it is called in a nested scope');
        }
    }

    BEGIN {
        is(new_scope(), 0, 'new_scope returns false the third time it is called in the outer scope');
    }

    BEGIN {
        is(new_scope('Test1'), 0, 'new_scope("Test1") returns false the third time it is called in the outer scope');
    }

    BEGIN {
        is(new_scope('Test2'), 1, 'new_scope("Test2") returns true the first time it is called in the outer scope');
    }

    BEGIN {
        is(new_scope('Test2'), 0, 'new_scope("Test2") returns false the second time it is called in the outer scope');
    }

    BEGIN {
        is(new_scope('Test3'), 1, 'new_scope("Test3") returns true the first time it is called in the outer scope');
    }

    BEGIN {
        is(new_scope('Test3'), 0, 'new_scope("Test3") returns fals3 the second time it is called in the outer scope');
    }
}
