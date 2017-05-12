# -*- mode: Perl; -*-
package PgSqlTypeTextTest;

use parent qw(Eve::Test);

use strict;
use warnings;

use Test::More;

use DBD::Pg ();

use Eve::PgSqlType::Text;

sub test_type : Test {
    is(Eve::PgSqlType::Text->new()->get_type(), DBD::Pg::PG_TEXT);
}

1;
