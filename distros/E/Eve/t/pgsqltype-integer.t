# -*- mode: Perl; -*-
package PgSqlTypeIntegerTest;

use parent qw(Eve::Test);

use strict;
use warnings;

use Test::More;

use DBD::Pg ();

use Eve::PgSqlType::Integer;

sub test_type : Test {
    is(Eve::PgSqlType::Integer->new()->get_type(), DBD::Pg::PG_INT4);
}

1;
