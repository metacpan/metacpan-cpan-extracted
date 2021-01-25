use strict;
use warnings;
use Mock::Quick;
use Test::More;

BEGIN {
    use_ok('Fancazzista::Scrap');
    use_ok('Fancazzista::Scrap::WebsiteScrapper');
    use_ok('Fancazzista::Scrap::RedditScrapper');
}
use Fancazzista::Scrap;

my $website = qtakeover(
    'Fancazzista::Scrap::WebsiteScrapper' => (
        scrap => sub {
            my @websites = ("test");
            return @websites;
        }
    )
);

my $reddit = qtakeover(
    'Fancazzista::Scrap::RedditScrapper' => (
        scrap => sub {
            my @websites = ("test");
            return @websites;
        }
    )
);

my @list   = Fancazzista::Scrap::scrapContent( () );
my @values = ( 'test', 'test' );

ok( @list eq @values, "Websites and reddit posts loaded" );
is( $reddit->metrics()->{'scrap'},  1, 'reddit scrap called' );
is( $website->metrics()->{'scrap'}, 1, 'reddit scrap called' );

done_testing();
