package IndexConfig::AllOpts;

use Elastic::Doc;

has_mapping { _all => { enabled => 0 } };

#===================================
has 'string' => (
#===================================
    is                    => 'ro',
    isa                   => 'Str',
    index_analyzer        => 'custom',
    search_analyzer       => 'standard',
    search_quote_analyzer => 'quoted',
);

1;
