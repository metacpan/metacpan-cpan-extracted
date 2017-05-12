# -*- mode: Perl; -*-
package PgSqlTypeSmallintTest;

use parent qw(Eve::Test);

use strict;
use warnings;

use Test::More;

use DBD::Pg ();

use Eve::PgSqlType::Smallint;

sub test_type : Test {
    is(Eve::PgSqlType::Smallint->new()->get_type(), DBD::Pg::PG_INT2);
}

1;
