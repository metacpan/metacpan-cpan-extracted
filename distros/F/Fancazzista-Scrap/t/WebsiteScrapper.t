use strict;
use warnings;
use Mock::Quick;
use Test::More;
use Data::Dumper;

BEGIN { use_ok('Fancazzista::Scrap::WebsiteScrapper'); }

use Fancazzista::Scrap::WebsiteScrapper;

my $WebsiteScrapperMock = qtakeover(
    'Fancazzista::Scrap::WebsiteScrapper' => (
        getWebsiteHtml => sub {
            return '
                <div>
                    <div class="status-publish">
                        <div class="entry-title">
                            <a href="https://example.com/index">index</a>
                        </div>
                    </div>
                    <div class="status-publish">
                        <div class="entry-title">
                            <a href="https://example.com/home">home</a>
                        </div>
                    </div>
                </div>
            ';
        }
    )
);

my $scrapper = $WebsiteScrapperMock->new();
my %config   = (
    websites => [
        {
            name         => "Korben",
            url          => "https://korben.info",
            selector     => ".status-publish .entry-title",
            linkSelector => "a",
            textSelector => "a"
        }
    ]
);

my @websites = $scrapper->scrap( \%config );
my @articles = @{ $websites[0]{articles} };

can_ok( $scrapper, 'scrap' );

is( $websites[0]{name}, 'Korben' );
is( $websites[0]{url},  'https://korben.info' );

is( scalar @websites, 1, 'Website loaded' );
is( scalar @articles, 2, "Two articles found" );

is( $articles[0]{text}, 'index',                     'found first article text' );
is( $articles[0]{link}, 'https://example.com/index', 'found first article link' );

is( $articles[1]{text}, 'home',                     'found second article text' );
is( $articles[1]{link}, 'https://example.com/home', 'found second article link' );

done_testing();
