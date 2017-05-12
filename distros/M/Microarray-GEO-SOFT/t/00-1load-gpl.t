use Test::More tests => 15;
use strict;

use_ok('Microarray::GEO::SOFT::GPL');

can_ok('Microarray::GEO::SOFT::GPL', 'new');
can_ok('Microarray::GEO::SOFT::GPL', 'parse');
can_ok('Microarray::GEO::SOFT::GPL', 'soft_dir');
can_ok('Microarray::GEO::SOFT::GPL', 'set_meta');
can_ok('Microarray::GEO::SOFT::GPL', 'set_table');
can_ok('Microarray::GEO::SOFT::GPL', 'meta');
can_ok('Microarray::GEO::SOFT::GPL', 'table');
can_ok('Microarray::GEO::SOFT::GPL', 'accession');
can_ok('Microarray::GEO::SOFT::GPL', 'title');
can_ok('Microarray::GEO::SOFT::GPL', 'platform');
can_ok('Microarray::GEO::SOFT::GPL', 'rownames');
can_ok('Microarray::GEO::SOFT::GPL', 'colnames');
can_ok('Microarray::GEO::SOFT::GPL', 'colnames_explain');
can_ok('Microarray::GEO::SOFT::GPL', 'matrix');
