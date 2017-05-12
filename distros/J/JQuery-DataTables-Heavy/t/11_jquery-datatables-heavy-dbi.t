#/usr/bin/env perl
use warnings;
use strict;
use t::Utils;
use Test::More;
use Test::Mock::Guard qw(mock_guard);

BEGIN{
    use_ok('JQuery::DataTables::Heavy::DBI');
}

{
    my $dbh = t::Utils->setup_dbh('test.db');
    my $attr = {
        param => {},
        dbh   => $dbh,
        table => 'table_name',
    };
    t::Utils->base_test(
        JQuery::DataTables::Heavy::DBI->new($attr),
        'v1_9.dat',
    );
}

done_testing;
