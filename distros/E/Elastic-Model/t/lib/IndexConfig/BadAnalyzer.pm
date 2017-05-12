package IndexConfig::BadAnalyzer;

use Elastic::Doc;

has_mapping { _all => { enabled => 0 } };

#===================================
has 'string' => (
#===================================
    is              => 'ro',
    isa             => 'Str',
    index_analyzer  => 'not_defined',
    search_analyzer => 'standard'
);

1;
