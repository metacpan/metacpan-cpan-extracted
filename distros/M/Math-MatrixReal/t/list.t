use Test::More;
use File::Spec;
use lib File::Spec->catfile("..","lib");
use Math::MatrixReal;

do 'funcs.pl';

my $matrix = Math::MatrixReal->new_from_rows([ [1, 2], [3, 4] ]);
my @list = $matrix->as_list;

is scalar(@list), 4, "list contains 4 elements";
is_deeply \@list, [1, 2, 3, 4], "list contains all elements from initial rows";


$matrix = Math::MatrixReal->new_from_rows([ [1, 2, 3], [3, 4, 5] ]);
@list = $matrix->as_list;

is scalar(@list), 6, "list contains 6 elements";
is_deeply \@list, [1, 2, 3, 3, 4, 5], "list contains all elements from initial rows";

done_testing;
