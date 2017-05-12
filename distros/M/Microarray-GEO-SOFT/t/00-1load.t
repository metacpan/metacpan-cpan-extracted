use Test::More tests => 16;
use strict;

use_ok('Microarray::GEO::SOFT');

can_ok('Microarray::GEO::SOFT', 'new');
can_ok('Microarray::GEO::SOFT', 'parse');
can_ok('Microarray::GEO::SOFT', 'soft_dir');
can_ok('Microarray::GEO::SOFT', 'set_meta');
can_ok('Microarray::GEO::SOFT', 'set_table');
can_ok('Microarray::GEO::SOFT', 'meta');
can_ok('Microarray::GEO::SOFT', 'table');
can_ok('Microarray::GEO::SOFT', 'accession');
can_ok('Microarray::GEO::SOFT', 'title');
can_ok('Microarray::GEO::SOFT', 'platform');
can_ok('Microarray::GEO::SOFT', 'rownames');
can_ok('Microarray::GEO::SOFT', 'colnames');
can_ok('Microarray::GEO::SOFT', 'colnames_explain');
can_ok('Microarray::GEO::SOFT', 'matrix');
can_ok('Microarray::GEO::SOFT', 'download');

diag( "Testing Microarray::GEO::SOFT $Microarray::GEO::SOFT::VERSION" );
