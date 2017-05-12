package IndexConfig::NoAnalyzer;

use Elastic::Doc;

has_mapping { _all => { enabled => 0 } };

#===================================
has 'string' => (
#===================================
    is  => 'ro',
    isa => 'Str',
);

1;
