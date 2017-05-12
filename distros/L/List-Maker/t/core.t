use Test::More 'no_plan';

use File::Glob;

my @globbed = File::Glob::csh_glob('* .*');
my @unglobbed = qw( *  .* );

is_deeply [<* .*>],  \@globbed => 'leading glob';

{
    use List::Maker;
    is_deeply [<* .*>],  \@unglobbed   => 'scoped special behaviour';
}

if ($] < 5.010) {
    is_deeply [<* .*>],  \@unglobbed   => 'trailing file-scoped';
}
else {
    is_deeply [<* .*>],  \@globbed => 'trailing block-scoped';
}

