use strict;
use warnings;
use Test::More;
use Test::InDistDir;
use Capture::Tiny 'capture';
use File::pushd;
use Path::Tiny;
use Locale::Simple::CLI;

# scripts/smoke-binary.sh runs this scrape with the packed binary and compares the output byte for
# byte with t/data/scrape-smoke.pot. This test keeps that file equal to what the Perl scraper writes.
my $expected = path('t/data/scrape-smoke.pot')->absolute->slurp_raw;
my ( $out, $rc );
{
    my $g = pushd('t/data/n-fixtures');
    ( $out, undef, $rc ) = capture { Locale::Simple::CLI::run('scrape') };
}
is $rc, 0, 'scrape of the smoke fixture exits 0';
ok length $expected > 500, 'the expectation is not empty';
is $out, $expected, 't/data/scrape-smoke.pot is what scrape writes in t/data/n-fixtures'
  or diag 'regenerate: (cd t/data/n-fixtures && perl -I../../../lib ../../../bin/locale-simple scrape 2>/dev/null > ../scrape-smoke.pot)';

done_testing;
