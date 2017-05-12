use Test::More tests => 72;
use strict;

use_ok("List::Vectorize", qw(sapply mapply happly tapply initial_array initial_matrix order
                 rank sort_array reverse_array repeat rep copy paste seq c test 
                 unique subset subset_value which all any dim t matrix_prod is_array_identical 
                 is_matrix_identical outer inner match len abs plus minus multiply divide
                 print_ref print_matrix read_table write_table intersect union
                 setdiff setequal is_element sign sum mean geometric_mean 
                 sd var cov cor dist freq table scale sample del_array_item 
                 rnorm rbinom max min which_max which_min median quantile iqr cumf
                 is_empty));

can_ok("main", "sapply");
can_ok("main", "mapply");
can_ok("main", "tapply");
can_ok("main", "happly");
can_ok("main", "print_ref");
can_ok("main", "print_matrix");
can_ok("main", "read_table");
can_ok("main", "write_table");
can_ok("main", "initial_array");
can_ok("main", "initial_matrix");
can_ok("main", "order");
can_ok("main", "rank");
can_ok("main", "sort_array");
can_ok("main", "reverse_array");
can_ok("main", "repeat");
can_ok("main", "rep");
can_ok("main", "copy");
can_ok("main", "paste");
can_ok("main", "seq");
can_ok("main", "c");
can_ok("main", "test");
can_ok("main", "unique");
can_ok("main", "subset");
can_ok("main", "subset_value");
can_ok("main", "which");
can_ok("main", "all");
can_ok("main", "any");
can_ok("main", "dim");
can_ok("main", "t");
can_ok("main", "matrix_prod");
can_ok("main", "is_array_identical");
can_ok("main", "is_matrix_identical");
can_ok("main", "outer");
can_ok("main", "inner");
can_ok("main", "match");
can_ok("main", "len");
can_ok("main", "is_empty");
can_ok("main", "del_array_item");
can_ok("main", "plus");
can_ok("main", "minus");
can_ok("main", "multiply");
can_ok("main", "divide");
can_ok("main", "intersect");
can_ok("main", "union");
can_ok("main", "setdiff");
can_ok("main", "setequal");
can_ok("main", "is_element");
can_ok("main", "sign");
can_ok("main", "sum");
can_ok("main", "mean");
can_ok("main", "geometric_mean");
can_ok("main", "sd");
can_ok("main", "var");
can_ok("main", "cov");
can_ok("main", "cor");
can_ok("main", "dist");
can_ok("main", "freq");
can_ok("main", "table");
can_ok("main", "scale");
can_ok("main", "sample");
can_ok("main", "rnorm");
can_ok("main", "rbinom");
can_ok("main", "max");
can_ok("main", "min");
can_ok("main", "which_max");
can_ok("main", "which_min");
can_ok("main", "median");
can_ok("main", "quantile");
can_ok("main", "iqr");
can_ok("main", "cumf");
can_ok("main", "abs");
