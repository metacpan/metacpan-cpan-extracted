package MyApp;

use Elastic::Model;

#===================================
has_namespace 'myapp' => {
#===================================
    user => 'MyApp::User',
    post => 'MyApp::Post'
};

#===================================
has_namespace 'myapp1' => {
#===================================
    user => 'MyApp::User',
    post => 'MyApp::Post'
    },
    fixed_domains => ['myapp1_fixed'];

#===================================
has_analyzer 'edge_ngrams' => (
#===================================
    tokenizer => 'standard',
    filter    => [ 'standard', 'lowercase', 'edge_ngrams_2_20' ]
);

#===================================
has_filter 'edge_ngrams_2_20' => (
#===================================
    type     => 'edge_ngram',
    min_gram => 2,
    max_gram => 20,
);

no Elastic::Model;

1;
