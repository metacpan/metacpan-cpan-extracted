use Test::Most;

use Geo::UK::Postcode::CodePointOpen;

ok my $cpo = Geo::UK::Postcode::CodePointOpen->new( path => 'corpus' ),
    'new object';

ok my @data_files = $cpo->data_files(), "data_files";

is_deeply [ map {"$_"} @data_files ],
    [ 'corpus/Data/CSV/xx.csv', 'corpus/Data/CSV/xy.csv' ],
    "default data_files ok";

is_deeply [ map {"$_"} $cpo->data_files('XY1') ],
    ['corpus/Data/CSV/xy.csv'],
    "data_files with outcode ok";

is_deeply [ map {"$_"} $cpo->data_files('AB10') ],
    [],
    "data_files with unmatched outcode ok";

done_testing();

