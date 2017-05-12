package IndexConfig::BadTokenizer;

use Elastic::Doc;

has_mapping { _all => { enabled => 0 } };

#===================================
has 'string' => (
#===================================
    is             => 'ro',
    isa            => 'Str',
    index_analyzer => 'bad',
);

1;
