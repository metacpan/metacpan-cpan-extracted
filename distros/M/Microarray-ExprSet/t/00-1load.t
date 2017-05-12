use Test::More tests => 13;
use strict;

use_ok('Microarray::ExprSet');

can_ok('Microarray::ExprSet', 'feature');
can_ok('Microarray::ExprSet', 'phenotype');
can_ok('Microarray::ExprSet', 'set_feature');
can_ok('Microarray::ExprSet', 'set_phenotype');
can_ok('Microarray::ExprSet', 'matrix');
can_ok('Microarray::ExprSet', 'set_matrix');
can_ok('Microarray::ExprSet', 'is_valid');
can_ok('Microarray::ExprSet', 'remove_empty_features');
can_ok('Microarray::ExprSet', 'unique_features');
can_ok('Microarray::ExprSet', 'n_feature');
can_ok('Microarray::ExprSet', 'n_phenotype');
can_ok('Microarray::ExprSet', 'save');

diag( "Testing Microarray::ExprSet $Microarray::ExprSet::VERSION" );
