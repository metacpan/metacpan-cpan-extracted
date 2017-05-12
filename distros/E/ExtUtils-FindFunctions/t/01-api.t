#!perl -T
use strict;
use Test::More;

plan tests => 7;

use_ok('ExtUtils::FindFunctions');
can_ok('ExtUtils::FindFunctions' => 'have_functions');

eval { have_functions() };
like( $@, q{/^error: Missing parameter 'libs'/}, 
        "calling have_functions() with no args" );

eval { have_functions(libs => '') };
like( $@, q{/^error: Missing parameter 'funcs'/}, 
        "calling have_functions() with only first arg" );

eval { have_functions(libs => '', funcs => '') };
like( $@, q{/^error: Missing parameter 'return_as'/}, 
        "calling have_functions() with first two args" );

eval { have_functions(libs => {}, funcs => '', return_as => '') };
like( $@, q{/^error: Incorrect argument for parameter 'libs'/}, 
        "calling have_functions() with invalid first arg" );

eval { have_functions(libs => '', funcs => '', return_as => 'plonk') };
like( $@, q{/^error: Incorrect value for parameter 'return_as'/}, 
        "calling have_functions() with invalid third arg" );

