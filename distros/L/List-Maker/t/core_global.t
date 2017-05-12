use Test::More 'no_plan';

use File::Glob;

BEGIN {
    *CORE::GLOBAL::glob = sub { return 'a'..'d'; };
}

my @overloaded = ('a'..'d');
my @unglobbed = qw( *  .* );

is_deeply [<* .*>],  \@overloaded => 'leading glob';

{
    use List::Maker;
    is_deeply [<* .*>],  \@unglobbed   => 'scoped special behaviour';
}

if ($] < 5.010) {
    is_deeply [<* .*>],  \@unglobbed   => 'trailing file-scoped';
}
else {
    is_deeply [<* .*>],  \@overloaded => 'trailing block-scoped';
}

