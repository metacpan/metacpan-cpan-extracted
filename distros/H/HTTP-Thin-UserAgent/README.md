HTTP::Thin::UserAgent
===================

HTTP::Thin::UserAgent --  A Thin Wrapper around HTTP::Thin

    use HTTP::Thin::UserAgent;

    my $data = http( POST 'http://api.metacpan.org/v0/release/_search')->as_json(
        {   query  => { match_all => {} },
            size   => 5000,
            fields => ['distribution'],
            filter => {
                and => [
                    {   term => {
                            'release.dependency.module' => 'MooseX::NonMoose'
                        }
                    },
                    { term => { 'release.maturity' => 'released' } },
                    { term => { 'release.status'   => 'latest' } }
                ]
            }
        }
    )->decoded_content;

    my $results = http(GET 'http://www.imdb.com/find?q=Kevin+Bacon')->scraper(
        scraper {
            process '.findResult', 'results[]' => scraper {
                process '.result_text', text => 'TEXT';
                process '.result_text > a', link => '@href';
            }
        }
    )->decoded_content;


