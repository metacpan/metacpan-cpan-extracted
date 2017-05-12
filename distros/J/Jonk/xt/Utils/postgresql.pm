package xt::Utils::postgresql;

use strict;
use warnings;
use Test::postgresql;
use Test::More;
use t::Utils;

my $pgsql = Test::postgresql->new
    or plan skip_all => $Test::postgresql::errstr;

{
    no warnings "redefine";
    sub t::Utils::setup {
        my ($class, $table) = @_;
        my $dbh = DBI->connect($pgsql->dsn);
        local $dbh->{"Warn"} = 0;
        $dbh->do(t::Utils::_get_schema($dbh, $table));
        $dbh;
    }
}

1;
