use Test::More tests => 4;
use Test::NoWarnings;
use strict;
use warnings;

use LaTeX::Table;
use English qw( -no_match_vars ) ;

my $table = LaTeX::Table->new({ filename => 'out.tex',
							    label    => 'beercounter',
								maincaption => 'Beer Counter',
								caption   => 'Number of beers before and after 4pm.',
                             });

my $test_data = [ [ 1, 2, 4], [ 2, 3 ] ];
$table->_calc_data_summary($test_data);
my $summary = $table->_get_data_summary();
is_deeply($summary, ['NUMBER','NUMBER','NUMBER'], 'all integers');

$test_data = [ [ 'a', 2, 4], [ 'b', 3 ] ];
$table->_calc_data_summary($test_data);
$summary = $table->_get_data_summary();
is_deeply($summary, ['DEFAULT','NUMBER','NUMBER'], 'not all integers');

$test_data = [ [ 'a', 2, ], [ '1', 3 ] ];
$table->_calc_data_summary($test_data);
$summary = $table->_get_data_summary();
is_deeply($summary, ['DEFAULT','NUMBER'], 'not all integers');
