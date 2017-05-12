use Test::More tests => 15;
use strict;

use_ok('Microarray::GEO::SOFT::GSM');

can_ok('Microarray::GEO::SOFT::GSM', 'new');
can_ok('Microarray::GEO::SOFT::GSM', 'parse');
can_ok('Microarray::GEO::SOFT::GSM', 'soft_dir');
can_ok('Microarray::GEO::SOFT::GSM', 'set_meta');
can_ok('Microarray::GEO::SOFT::GSM', 'set_table');
can_ok('Microarray::GEO::SOFT::GSM', 'meta');
can_ok('Microarray::GEO::SOFT::GSM', 'table');
can_ok('Microarray::GEO::SOFT::GSM', 'accession');
can_ok('Microarray::GEO::SOFT::GSM', 'title');
can_ok('Microarray::GEO::SOFT::GSM', 'platform');
can_ok('Microarray::GEO::SOFT::GSM', 'rownames');
can_ok('Microarray::GEO::SOFT::GSM', 'colnames');
can_ok('Microarray::GEO::SOFT::GSM', 'colnames_explain');
can_ok('Microarray::GEO::SOFT::GSM', 'matrix');
