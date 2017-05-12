use strict;
use Test::More;

eval 'use Test::Exception';

if ($@) {
	plan (skip_all => 'Test::Exception not installed') ;
}


use Microarray::ExprSet;
my $expr = Microarray::ExprSet->new;

my $mat = [[1, 2, 3, 4, 5, 6],
           [7, 8, 9, 10, 11, 12],
           [13, 14, 15, 16, 17, 18],
           [19, 20, 21, 22, 23, 24],
           [25, 26, 27, 28, 29],
           [31, 32, 33, 34, 35, 36]];

eval q` dies_ok { $expr->set_matrix($mat) } `;

$mat = [[1, 2, 3, 4, 5, 6],
           [7, 8, 9, 10, 11, 12],
           [13, 14, 15, 16, 17, 18],
           [19, 20, 21, 22, 23, 24],
           [25, 26, 27, 28, 29, 30],
           [31, 32, 33, 34, 35, 36]];


my $probe = ["gene1", "gene2", "gene2", "gene4"];
$expr->set_feature($probe)->set_matrix($mat);

eval q` dies_ok { $expr->remove_empty_features($mat) } `;
eval q` dies_ok { $expr->unique_features($mat) } `;

$expr->new;
$expr->set_matrix($mat);

eval q` dies_ok { $expr->save('.tmp2') } `;

$probe = ["gene1", "gene2", "gene2", "gene3", "", "gene4"];
$expr->set_feature($probe);

eval q` dies_ok { $expr->save('.tmp2') } `;

$expr->{matrix} = [[1, 2, 3], [4, 5]];
eval q` dies_ok { $expr->save('.tmp2') } `;

unlink('.tmp2') if(-e '.tmp2');

done_testing();

