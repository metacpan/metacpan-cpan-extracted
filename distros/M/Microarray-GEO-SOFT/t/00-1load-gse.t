use Test::More tests => 20;
use strict;

use_ok('Microarray::GEO::SOFT::GSE');

can_ok('Microarray::GEO::SOFT::GSE', 'new');
can_ok('Microarray::GEO::SOFT::GSE', 'parse');
can_ok('Microarray::GEO::SOFT::GSE', 'soft_dir');
can_ok('Microarray::GEO::SOFT::GSE', 'set_meta');
can_ok('Microarray::GEO::SOFT::GSE', 'set_table');
can_ok('Microarray::GEO::SOFT::GSE', 'meta');
can_ok('Microarray::GEO::SOFT::GSE', 'table');
can_ok('Microarray::GEO::SOFT::GSE', 'accession');
can_ok('Microarray::GEO::SOFT::GSE', 'title');
can_ok('Microarray::GEO::SOFT::GSE', 'platform');
can_ok('Microarray::GEO::SOFT::GSE', 'rownames');
can_ok('Microarray::GEO::SOFT::GSE', 'colnames');
can_ok('Microarray::GEO::SOFT::GSE', 'colnames_explain');
can_ok('Microarray::GEO::SOFT::GSE', 'matrix');
can_ok('Microarray::GEO::SOFT::GSE', '_parse_series');
can_ok('Microarray::GEO::SOFT::GSE', 'set_list');
can_ok('Microarray::GEO::SOFT::GSE', 'list');
can_ok('Microarray::GEO::SOFT::GSE', 'merge');
can_ok('Microarray::GEO::SOFT::GSE', '_merge_gsm');
