# [[[ HEADER ]]]
use RPerl;
package MLPerl::PythonShims;
use strict;
use warnings;
our $VERSION = 0.001_000;

# [[[ CRITICS ]]]
## no critic qw(ProhibitUselessNoCritic ProhibitMagicNumbers RequireCheckedSyscalls)  # USER DEFAULT 1: allow numeric values & print operator
## no critic qw(RequireInterpolationOfMetachars)  # USER DEFAULT 2: allow single-quoted control characters & sigils

# [[[ EXPORTS ]]]
use RPerl::Exporter qw(import);
our @EXPORT_OK = qw(concatenate range for_range);

# [[[ SUBROUTINES ]]]

# NEED FIX: move all subroutines to some appropriate library file
sub concatenate {
    { my number_arrayref $RETURN_TYPE };
    ( my number_arrayref $input_0, my number_arrayref $input_1 ) = @ARG;
    return [@{$input_0}, @{$input_1}];
}


# range(start, stop, step)  # PYTHON
# NEED UPGRADE: enable all 3 input parameters
sub range {
    { my integer_arrayref $RETURN_TYPE };
#    ( my integer $start, my integer $stop, my integer $step ) = @ARG;
    ( my integer $stop ) = @ARG;
    return [0 .. ($stop - 1)];
}


# NEED FIX: creates strings instead of integers, which do we want???
# create arrayref of integer repeated a certain number of times
sub for_range {
    { my string_arrayref $RETURN_TYPE };
    ( my string $input, my integer $repetitions ) = @ARG;
#    print 'in for_range(), received $input = ', $input, "\n";
#    print 'in for_range(), received $repetitions = ', $repetitions, "\n";

    my string_arrayref $input_repeated = [];

    for (my integer $i = 0; $i < $repetitions; $i++) {
        $input_repeated->[$i] = $input;
    }
    return $input_repeated;
}

1;  # end of package
