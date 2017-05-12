# -*- mode: Perl; -*-
package PgSqlTypeDoubleTest;

use parent qw(Eve::Test);

use strict;
use warnings;

use Test::More;

use DBD::Pg ();

use Eve::PgSqlType::Double;

sub test_type : Test {
    is(Eve::PgSqlType::Double->new()->get_type(), DBD::Pg::PG_FLOAT8);
}

1;
