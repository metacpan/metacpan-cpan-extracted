use Test::More tests => 135;
use FindBin qw($Bin);
use strict;

BEGIN {
	use_ok('List::Vectorize');
}


ok( sapply([1..10], sub {sqrt}), "apply function on array" );
ok( mapply([1..10], [1..10], sub {sum(\@_)}), "apply function on several functions");
ok( mapply([1..10], 1, sub {sum(\@_)}), "apply function on function and scalar" );
ok( happly({a => 1, b => 2}, sub {$_[0]**2}), "apply function on hash" );
ok( tapply([1..10], ["a", "a", "a", "b", "b", "b", "c", "c", "d", "d"], sub {sqrt}), "apply function on category data");
ok( tapply([1..10], ["a", "a", "a", "b", "b", "b", "c", "c", "d", "d"],
                    [1, 2, 1, 2, 1, 2, 1, 2, 1, 2], sub {sqrt}), "apply function on data under more than one categories" );
ok( initial_array(10), "initial array with undefined value" );
ok( initial_array(10, "a"), "initial array with repeated data");
ok( initial_array(10, [1, 2]), "initial array from array" );
ok( initial_array(10, sub {rand}), "initial array from function" );
ok( initial_matrix(3, 3), "initial matrix with undefined value");
ok( initial_matrix(3, 3, 1), "initial matrix with repeated value" );
ok( initial_matrix(3, 3, sub {rand}), "initial matrix from function" );
ok( order([4, 1, 2, 9]), "order array with default sort function");
ok( order([4, 1, 2, 9], sub {$_[1] <=> $_[0]}), "order array with self-defined function");
ok( rank([4, 1, 2, 9]), "rank array with default sort function");
ok( rank([4, 1, 2, 9], sub {$_[1] <=> $_[0]}), "rank array with self-defined function");
ok( sort_array([4, 1, 2, 9]) );
ok( sort_array([4, 1, 2, 9], sub {$_[1] <=> $_[0]}) );
ok( reverse_array([4, 1, 2, 9]) );
ok( repeat(1, 10) );
ok( repeat(1, 10, 1) );
ok( repeat([1, 2, 3], 10) );
ok( repeat([1, 2, 3], 10, 1) );
ok( rep(1, 10) );
ok( rep(1, 10, 1) );
ok( rep([1, 2, 3], 10) );
ok( rep([1, 2, 3], 10, 1) );
ok( copy([1, 2, 3]) );
ok( copy(\1) );
ok( copy({a => 1, b => 2}) );
ok( paste("x", [1..10]) );
ok( paste("x", [1..10], "") );
ok( seq(1, 10) );
ok( seq(1, 10, 2) );
ok( c(1, 2, 3) );
ok( c(1, [2, 3]) );
ok( c([1, 2], [3, 4]) );
ok( c([[1, 2], [3, 4]], \[5, 6]) );
ok( test([1..10], sub {$_[0] % 2}) );
ok( unique(["a", "a", "b", "c"]) );
ok( subset([1..10], sub {$_[0] % 2}) );
ok( subset([1..10], [0, 1, 0, 1, 0, 1, 0, 1, 0, 1]) );
ok( subset_value([1..10], sub {$_[0] % 2}, 0) );
ok( subset_value([1..10], sub {$_[0] % 2}, [-1, -1, -1, -1, -1]) );
ok( subset_value([1..10], [2, 4, 6, 8, 10], 0) );
ok( subset_value([1..10], [2, 4, 6, 8, 10], [-1, -1, -1, -1, -1]) );
ok( del_array_item([1..10], 3) );
ok( del_array_item([1..10], [1..5]) );
ok( which([0, 1, 0, 0, 1, 1]) );
ok( all([1, 1, 1, 1]) );
ok( any([0, 1, 0, 1]) );
ok( dim([[1, 2], [3, 4]]) );
ok( t([[1, 2], [3, 4]]) );
ok( matrix_prod([[1, 2], [3, 4]], [[1, 2], [3, 4]]) );
ok( matrix_prod([[1, 2], [3, 4]], [[1, 2], [3, 4]], [[1, 2], [3, 4]]) );
ok( is_array_identical([1, 2], [1, 2]) );
ok( is_matrix_identical([[1, 2], [3, 4]], [[1, 2], [3, 4]]) );
ok( outer([1, 2], [1, 2]) );
ok( outer([1, 2], [1, 2], sub {$_[0] + $_[1]}) );
ok( inner([1, 2], [1, 2]) );
ok( inner([1, 2], [1, 2], sub {$_[0] + $_[1]}) );
ok( match([1..10], [5..12]) );
ok( plus([1..10], 1) );
ok( plus([1..10], [1..10]) );
ok( plus([1..10], [1..10], [1..10]) );
ok( minus([1..10], 1) );
ok( minus([1..10], [1..10]) );
ok( minus([1..10], [1..10], [1..10]) );
ok( divide([1..10], 1) );
ok( divide([1..10], [1..10]) );
ok( divide([1..10], [1..10], [1..10]) );
ok( multiply([1..10], 1) );
ok( multiply([1..10], [1..10]) );
ok( multiply([1..10], [1..10], [1..10]) );

ok( intersect(["a", "b", "c"], ["b", "c"]) );
ok( intersect(["a", "b", "c"], ["b", "c"], ["c", "d"]) );
ok( union(["a", "b", "c"], ["b", "c"]) );
ok( union(["a", "b", "c"], ["b", "c"], ["c", "d"]) );
ok( setdiff(["a", "b", "c"], ["b", "c"]) );
ok( setequal(["b", "c"], ["b", "c"]) );
ok( is_element("a", ["a", "b", "c"]) );

{
	local *STDOUT;
	if($^O eq "MSWin32") {
		open STDOUT, ">", "NUL";
	} else {
		open STDOUT, ">", "/dev/null";
	}
	ok( print_ref([1..3]) );
	ok( print_ref({a => 1, b => 2}) );
	ok( print_ref(\1) );
	ok( print_ref(sub {1}) );
	ok( print_matrix([[1, 2], [3, 4]]) );

	my $fh = *STDOUT;
	ok( print_ref($fh, [1..3]) );
	ok( print_ref($fh, {a => 1, b => 2}) );
	ok( print_ref($fh, \1) );
	ok( print_ref($fh, sub {1}) );
	ok( print_matrix($fh, [[1, 2], [3, 4]]) );
}

my $foo;
ok( write_table([[1, 2], [3, 4]], "file" => "$Bin/.tmp", "row.names" => ["r1", "r2"]) );
ok( $foo = read_table("$Bin/.tmp") );
ok( $foo = read_table("$Bin/.tmp", "quote" => "", "sep" => "\t") );
ok( $foo = read_table("$Bin/.tmp", "quote" => "", "sep" => "\t", "row.names" => 1, "col.names" => 0) );
unlink("$Bin/.tmp") if(-e "$Bin/.tmp");


ok( sign(1) );
ok( sum([1..10]) );
ok( mean([1..10]) );
ok( mean([1..10]) );
ok( geometric_mean([1..10]) );
ok( sd([1..10]) );
ok( sd([1..10], 5.5) );
ok( var([1..10]) );
ok( var([1..10], 5.5) );
ok( cov([1..10], [11..20]) );
ok( cor([1..10], [11..20]) );
ok( cor([1..10], [11..20], 'pearson') );
ok( dist([1..10], [11..20]) );
ok( dist([1..10], [11..20], 'spearman') );
ok( freq(["a", "a", "b", "b"]) );
ok( freq(["a", "a", "b", "b"], [1,1,2,2]) );
ok( table(["a", "a", "b", "b"]) );
ok( table(["a", "a", "b", "b"], [1,1,2,2]) );
ok( scale([1..10]) );
ok( scale([1..10], 'shpere') );
ok( sample([1..10], 2) );
ok( sample([1..10], 2, "replace" => 1) );
ok( rnorm(10) );
ok( rnorm(10, 1) );
ok( rnorm(10, 1, 2) );
ok( rbinom(10) );
ok( rbinom(10, 0.1) );
ok( max([1..10]) );
ok( min([1..10]) );
ok( which_max([1..10]) );
ok( which_min([10, 2, 5, 9]) );
ok( median([1..10]) );
ok( quantile([1..10]) );
ok( quantile([1..10], 0.3) );
ok( quantile([1..10], [0.25, 0.75]) );
ok( iqr([1..10]) );
ok( cumf([1..10]) );
ok( cumf([1..10], sub {sum(\@_)}) );

diag('prototype for all subroutines');
