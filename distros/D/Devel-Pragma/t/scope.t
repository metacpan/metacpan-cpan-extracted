#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 10;
use Devel::Pragma qw(scope);

use vars qw($scope1 $scope2 $scope3 $warning);

BEGIN { $scope1 = scope() }

{
    BEGIN { $scope2 = scope() }

    {
        BEGIN { $scope3 = scope() }
        BEGIN {
            is(scope, $scope3, 'scope 3 is scope 3');
            isnt(scope, $scope1, 'scope 3 is not scope 1');
            isnt(scope, $scope2, 'scope 3 is not scope 2');
        }
    }

    BEGIN {
        is(scope(), $scope2, 'scope 2 is scope 2');
        isnt(scope, $scope1, 'scope 2 is not scope 1');
        isnt(scope, $scope3, 'scope 2 is not scope 3');
    }
}

BEGIN {
    is(scope(), $scope1, 'scope 1 is scope 1');
    isnt(scope, $scope2, 'scope 1 is not scope 2');
    isnt(scope, $scope3, 'scope 1 is not scope 3');
}

BEGIN { $^H &= ~0x20000 } # turn off HINT_LOCALIZE_HH

BEGIN {
    $warning = 0;
    local $SIG{__WARN__} = sub { $warning = 1 };
    scope();
    ok($warning, "calling scope when the HINT_LOCALIZE_HH bit is not set generates a warning");
}
