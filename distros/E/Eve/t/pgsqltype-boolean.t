# -*- mode: Perl; -*-
package PgSqlTypeBooleanTest;

use parent qw(Eve::Test);

use strict;
use warnings;

use Test::More;

use DBD::Pg ();

use Eve::PgSqlType::Boolean;

sub test_type : Test {
    is(Eve::PgSqlType::Boolean->new()->get_type(), DBD::Pg::PG_BOOL);
}

1;
