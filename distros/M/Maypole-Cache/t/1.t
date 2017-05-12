# vim:ft=perl
use Test::More;
use lib 't/ex'; # Where BeerCache should live
BEGIN { if (eval { require BeerCache }) { 
            plan tests => 23;
        } else { Test::More->import(skip_all =>"SQLite not working or BeerCache module not found: $@") }
      }
use Maypole::CLI qw(BeerCache);
use Maypole::Constants;

# Clear the damned cache before running!
use Cache::FileCache;
Cache::FileCache->new({namespace => "BeerCache"})->Clear;

@ARGV = ("http://localhost/beerdb/beer/timetest");
is(BeerCache->handler, OK, "OK");
like($Maypole::CLI::buffer, qr/Time test: (\d+)/, "We've served something");
$Maypole::CLI::buffer=~ /: (\d+)/;
is ($1, 1, "First call");

#Do it again!
@ARGV = ("http://localhost/beerdb/beer/timetest");
is(BeerCache->handler, OK, "OK");
like($Maypole::CLI::buffer, qr/Time test: (\d+)/, "Rerun the test");
$Maypole::CLI::buffer=~ /: (\d+)/;
is($1, 1, "Cached first call");

#Do it again!
@ARGV = ("http://localhost/beerdb/beer/timetest");
is(BeerCache->handler, OK, "OK");
like($Maypole::CLI::buffer, qr/Time test: (\d+)/, "Rerun the test");
$Maypole::CLI::buffer=~ /: (\d+)/;
is($1, 1, "Still first call");

# Now do the uncached version
@ARGV = ("http://localhost/beerdb/beer/timetest_nocache");
is(BeerCache->handler, OK, "OK");
like($Maypole::CLI::buffer, qr/Time test: (\d+)/, "Uncached version");
$Maypole::CLI::buffer=~ /: (\d+)/;
is($1, 2, "Second call");

@ARGV = ("http://localhost/beerdb/beer/timetest_nocache");
is(BeerCache->handler, OK, "OK");
like($Maypole::CLI::buffer, qr/Time test: (\d+)/, "Uncached version");
$Maypole::CLI::buffer=~ /: (\d+)/;
is($1, 3, "Third");

#Do it again!
@ARGV = ("http://localhost/beerdb/beer/timetest");
is(BeerCache->handler, OK, "OK");
like($Maypole::CLI::buffer, qr/Time test: (\d+)/, "First again?");
$Maypole::CLI::buffer=~ /: (\d+)/;
is($1, 1, "Back to first call");

# Break authentication
{ 
local *BeerCache::authenticate = sub { return -1 };
@ARGV = ("http://localhost/beerdb/beer/timetest");
is(BeerCache->handler, -1, "Auth failed")
}

# Break the cache module
BeerCache->config->{cache_options}{class} = "NoNeSuCh::ClAsS";
$SIG{__WARN__} = sub { ok(1, "Warning called") };
@ARGV = ("http://localhost/beerdb/beer/timetest_nocache");
is(BeerCache->handler, OK, "OK");
like($Maypole::CLI::buffer, qr/Time test: (\d+)/, "With broken cache class");
$Maypole::CLI::buffer=~ /: (\d+)/;
is($1, 4, "Called anyway");
