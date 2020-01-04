# [[[ HEADER ]]]
use RPerl;
package MLPerl::Classifier::KNeighbors::Neighbor2D;
use strict;
use warnings;
our $VERSION = 0.001_000;

# [[[ OO INHERITANCE ]]]
use parent qw(RPerl::CompileUnit::Module::Class);    # no non-system inheritance, only inherit from base class
use RPerl::CompileUnit::Module::Class;

# [[[ CRITICS ]]]
## no critic qw(ProhibitUselessNoCritic ProhibitMagicNumbers RequireCheckedSyscalls) # USER DEFAULT 1: allow numeric values & print operator
## no critic qw(RequireInterpolationOfMetachars)  # USER DEFAULT 2: allow single-quoted control characters & sigils
## no critic qw(ProhibitConstantPragma ProhibitMagicNumbers)  # USER DEFAULT 3: allow constants
## no critic qw(Capitalization ProhibitMultiplePackages ProhibitReusedNames)  # SYSTEM DEFAULT 3: allow multiple & lower case & mixed-case package names
## no critic qw(ProhibitAutomaticExportation)  # SYSTEM SPECIAL 14: allow global exports from Config.pm & elsewhere

# [[[ OO PROPERTIES ]]]
our hashref $properties = {
    data     => my number_arrayref $TYPED_data->[2 - 1] = undef,  # size 2 for 2D, undef to avoid allocating memory during construction
    distance => my number $TYPED_distance = -1,  # default to defined-but-invalid negative distance
    classification => my string $TYPED_classification = q{}      # default to defined-but-invalid empty group
};

1;    # end of class
