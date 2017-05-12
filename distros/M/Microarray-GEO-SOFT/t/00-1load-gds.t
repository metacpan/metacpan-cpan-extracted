use Test::More tests => 19;
use strict;


use_ok('Microarray::GEO::SOFT::GDS');

can_ok('Microarray::GEO::SOFT::GDS', 'new');
can_ok('Microarray::GEO::SOFT::GDS', 'parse');
can_ok('Microarray::GEO::SOFT::GDS', '_parse_dataset');
can_ok('Microarray::GEO::SOFT::GDS', 'soft_dir');
can_ok('Microarray::GEO::SOFT::GDS', 'set_meta');
can_ok('Microarray::GEO::SOFT::GDS', 'set_table');
can_ok('Microarray::GEO::SOFT::GDS', 'meta');
can_ok('Microarray::GEO::SOFT::GDS', 'table');
can_ok('Microarray::GEO::SOFT::GDS', 'accession');
can_ok('Microarray::GEO::SOFT::GDS', 'title');
can_ok('Microarray::GEO::SOFT::GDS', 'platform');
can_ok('Microarray::GEO::SOFT::GDS', 'rownames');
can_ok('Microarray::GEO::SOFT::GDS', 'colnames');
can_ok('Microarray::GEO::SOFT::GDS', 'colnames_explain');
can_ok('Microarray::GEO::SOFT::GDS', 'matrix');
can_ok('Microarray::GEO::SOFT::GDS', 'get_subset');
can_ok('Microarray::GEO::SOFT::GDS', 'id_convert');
can_ok('Microarray::GEO::SOFT::GDS', 'soft2exprset');
