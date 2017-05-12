# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as
# `perl Filter-BoxString.t'

#########################

use Test::More tests => 2;

BEGIN {

    use_ok('Filter::BoxString');
}

TEST:
{
    my $sql = eval {

        my $sql = +
                  | SELECT *
                  | FROM the_table
                  | WHERE this = 'that'
                  | AND those = 'these'
                  | ORDER BY things ASC
                  +;
    };

    my $expected_sql
        = " SELECT *\n"
        . " FROM the_table\n"
        . " WHERE this = 'that'\n"
        . " AND those = 'these'\n"
        . " ORDER BY things ASC\n";

    is( $sql, $expected_sql, 'sql content' );
}

