use strict;
use Test::More 'no_plan';
use List::Vectorize;
use Microarray::ExprSet;
my $expr = Microarray::ExprSet->new;

my $mat = [[1, 2, 3, 4, 5, 6],
           [7, 8, 9, 10, 11, 12],
           [13, 14, 15, 16, 17, 18],
           [19, 20, 21, 22, 23, 24],
           [25, 26, 27, 28, 29, 30],
           [31, 32, 33, 34, 35, 36]];
my $probe = ["gene1", "gene2", "gene2", "gene3", "", "gene4"];
my $sample = ["c1", "c1", "c1", "c2", "c2", "c2"];

is_deeply($expr, {feature => undef,
                  phenotype => undef,
				  matrix => undef,
				  error => undef});
$expr->set_feature($probe)->set_phenotype($sample)->set_matrix($mat);

is_deeply($expr->feature, $probe);
is_deeply($expr->phenotype, $sample);
is_deeply($expr->matrix, $mat);

# test is_validate
$expr->{matrix} = undef;
is($expr->is_valid, 0);
is($expr->{error}, "Expression matrix is not defined");

$expr->{matrix} = [[1, 2, 3], [4, 5]];
is($expr->is_valid, 0);
is($expr->{error}, "Not a matrix");

$expr->{matrix} = $mat;
$expr->{feature} = undef;
$expr->{phenotype} = undef;
is($expr->is_valid, 1);

$expr->{feature} = ["r1", "r2"];
is($expr->is_valid, 0);
is($expr->{error}, "Length of feature names is not identical to the number of matrix rows");

$expr->{feature} = undef;
$expr->{phenotype} = ["c1", "c2"];
is($expr->is_valid, 0);
is($expr->{error}, "Length of phenotype names is not identical to the number of matrix columns");

$expr->set_feature($probe)->set_phenotype($sample)->set_matrix($mat);
is($expr->is_valid, 1);
is($expr->n_feature, 6);
is($expr->n_phenotype, 6);

# test remove_empty_features
$expr->set_feature($probe)->set_phenotype($sample)->set_matrix($mat);
$expr->remove_empty_features;
is_deeply($expr->matrix, [[1, 2, 3, 4, 5, 6],
                          [7, 8, 9, 10, 11, 12],
                          [13, 14, 15, 16, 17, 18],
                          [19, 20, 21, 22, 23, 24],
                          [31, 32, 33, 34, 35, 36]]);
is_deeply($expr->feature, ["gene1", "gene2", "gene2", "gene3", "gene4"]);

# test unique_features
$expr->unique_features;
$expr->{matrix} = subset($expr->matrix, order($expr->feature, sub { $_[0] cmp $_[1] }));
$expr->{feature} = sort_array($expr->feature, sub { $_[0] cmp $_[1] });
is_deeply($expr->matrix, [[1, 2, 3, 4, 5, 6],
                          [10, 11, 12, 13, 14, 15],
                          [19, 20, 21, 22, 23, 24],
                          [31, 32, 33, 34, 35, 36]]);
is_deeply($expr->feature, ["gene1", "gene2", "gene3", "gene4"]);

$expr->set_feature(["gene1", "gene1", "gene1", "gene4"]);
$expr->unique_features('median');
is_deeply($expr->matrix, [[10, 11, 12, 13, 14, 15],
                          [31, 32, 33, 34, 35, 36]]);
is_deeply($expr->feature, ["gene1", "gene4"]);

# save
$expr->save(".tmp");
my $copy = read_table(".tmp", "row.names" => 1, "col.names" => 1);
is_deeply($expr->matrix, $copy);
unlink(".tmp") if(-e ".tmp");
