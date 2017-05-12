package BeerCache;
use base 'Apache::MVC';
use Maypole::Cache;
BEGIN { BeerCache->setup("dbi:SQLite:t/beerdb.db"); };
BeerCache->config->{cache_options}{class} = "Cache::FileCache";
BeerCache->config->{uri_base} = "http://localhost/beerdb/";
BeerCache->config->{rows_per_page} = 10;
BeerCache->config->{display_tables} = [qw[beer]];
1;

package BeerCache::Beer;
our $time = 1;

sub meta_info{}
sub timetest :Exported {
    my ($class,$r) = @_;
    $r->{output} = "Time test: ".$time++."\n";
}

sub timetest_nocache :Exported {
    my ($class,$r) = @_;
    $r->{output} = "Time test: ".$time++."\n";
    $r->{nocache} = 1;
}

