#!/usr/bin/perl

# [[[ PREPROCESSOR ]]]
# <<< EXECUTE_SUCCESS: '3141592653	:10' >>>
# <<< EXECUTE_SUCCESS: '5897932384	:20' >>>
# <<< EXECUTE_SUCCESS: '6264338327	:30' >>>
# <<< EXECUTE_SUCCESS: '9502884197	:40' >>>
# <<< EXECUTE_SUCCESS: '1693993751	:50' >>>
# <<< EXECUTE_SUCCESS: '8074462379	:460' >>>
# <<< EXECUTE_SUCCESS: '9627495673	:470' >>>
# <<< EXECUTE_SUCCESS: '5188575272	:480' >>>
# <<< EXECUTE_SUCCESS: '4891227938	:490' >>>
# <<< EXECUTE_SUCCESS: '1830119491	:500' >>>

# [[[ HEADER ]]]
use RPerl;
use strict;
use warnings;
our $VERSION = 0.001_000;

# [[[ CRITICS ]]]
## no critic qw(ProhibitUselessNoCritic ProhibitMagicNumbers RequireCheckedSyscalls)  # USER DEFAULT 1: allow numeric values & print operator

# [[[ INCLUDES ]]]
use MathPerl::Geometry::PiDigits;

# [[[ OPERATIONS ]]]
MathPerl::Geometry::PiDigits::display_pi_digits(500);
