+{
    providers => [
        'Lingr' => {
            host => '127.0.0.1',
            port => 1199,
        },
    ],
    'handlers' => [
        Karma => {
            path => 'karma.bdb',
        },
        'LLEval',
        'IkachanForwarder' => {
            url => 'http://127.0.0.1:4979',
            channel => '#hiratara',
        },
        'PerldocJP',
        'URLFetcher',
        'CoreList',
    ],
};
