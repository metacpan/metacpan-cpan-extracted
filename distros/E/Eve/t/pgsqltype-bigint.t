# -*- mode: Perl; -*-
package PgSqlTypeBigintTest;

use parent qw(Eve::Test);

use strict;
use warnings;

use Test::More;

use DBD::Pg ();

use Eve::PgSqlType::Bigint;

sub test_type : Test {
    is(Eve::PgSqlType::Bigint->new()->get_type(), DBD::Pg::PG_INT8);
}

1;
