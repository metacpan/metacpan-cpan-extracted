package MyApp::User;

use Elastic::Doc;

#===================================
has 'name' => (
#===================================
    is    => 'rw',
    isa   => 'Str',
    store => 1,
    multi => {
        ngrams    => { analyzer => 'edge_ngrams' },
        untouched => { index    => 'not_analyzed' },
    }
);

#===================================
has 'email' => (
#===================================
    is  => 'rw',
    isa => 'Str',
);

no Elastic::Doc;

1;
