use Test::More;
use strict; use warnings FATAL => 'all';

require List::Objects::WithUtils;

eval {; List::Objects::WithUtils->import([]) };
like $@, qr/Expected a list of imports/i, 'bad import croaks ok';

eval {; List::Objects::WithUtils->import(qw/array foo/) };
like $@, qr/Unknown import parameter/i, 'bad function croaks ok';

done_testing;
