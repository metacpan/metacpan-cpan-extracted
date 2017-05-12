package IndexConfig;

use Elastic::Model;
use utf8;

#===================================
has_namespace 'good' => {
#===================================
    all_opts    => 'IndexConfig::AllOpts',
    no_analyzer => 'IndexConfig::NoAnalyzer'
};

#===================================
has_namespace 'bad' => {
#===================================
    bad_analyzer  => 'IndexConfig::BadAnalyzer',
    bad_tokenizer => 'IndexConfig::BadTokenizer'

};

#===================================
has_char_filter 'map_ss' => (
#===================================
    type     => 'mapping',
    mappings => [ 'ß' => 'ss' ]
);

#===================================
has_filter 'truncate_20' => (
#===================================
    type   => 'truncate',
    length => 20
);

#===================================
has_tokenizer 'edge_ngrams' => (
#===================================
    type     => 'edge_ngram',
    min_gram => 1,
    max_gram => 10
);

#===================================
has_analyzer 'custom' => (
#===================================
    tokenizer   => 'edge_ngrams',
    filter      => [ 'truncate_20', 'lowercase' ],
    char_filter => 'map_ss'
);

#===================================
has_analyzer 'quoted' => (
#===================================
    tokenizer => 'whitespace',
);

#===================================
has_analyzer 'bad' => (
#===================================
    tokenizer => 'foo'
);

no Elastic::Model;

1;
