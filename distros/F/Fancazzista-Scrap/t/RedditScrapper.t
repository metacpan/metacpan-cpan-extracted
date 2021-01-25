use strict;
use warnings;
use Mock::Quick;
use Test::More;
use Data::Dumper;

BEGIN { use_ok('Fancazzista::Scrap::RedditScrapper'); }

use Fancazzista::Scrap::RedditScrapper;

subtest 'test_parsing_reddit_api' => sub {
    my $control = qtakeover(
        'LWP::UserAgent' => (
            request => sub {
                my $response = qobj(
                    is_success      => 1,
                    decoded_content => '{ "data": { "children": [ { "data" : { "title": "Example JS", "url": "http://example.com/js" } } ] } }'
                );
                return $response;
            }
        )
    );
    my %subreddit = ( name => 'js', limit => 10 );
    my $scrapper  = new Fancazzista::Scrap::RedditScrapper();
    my @posts     = $scrapper->getPosts( \%subreddit );
    my %post      = %{ $posts[0] };

    is( scalar @posts, 1, 'Post loaded' );

    is( $post{text}, 'Example JS',            '' );
    is( $post{link}, 'http://example.com/js', '' );
};

subtest 'test_scrap' => sub {
    my $mock = qtakeover(
        'Fancazzista::Scrap::RedditScrapper' => (
            getPosts => sub {
                return ( { link => 'https://redit.com', 'text' => 'aritcle_1' }, { link => 'https://redit.com', 'text' => 'aritcle_2' }, );
            }
        )
    );

    my %config     = ( subreddits => [ { name => "js", } ] );
    my @subreddits = $mock->new()->scrap( \%config );
    my $js         = $subreddits[0];
    my @articles   = @{ $js->{articles} };

    is( $js->{url}, 'https://www.reddit.com/r/js', '' );

    is( scalar @subreddits, 1, 'Subreddit loaded' );
    is( scalar @articles,   2, 'Articles loaded from reddit' );
};

done_testing();
