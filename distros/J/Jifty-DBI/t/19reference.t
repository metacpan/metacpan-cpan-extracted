#!/usr/bin/env perl -w

use strict;

use Test::More;
BEGIN { require "t/utils.pl" }
our (@available_drivers);

use constant TESTS_PER_DRIVER => 40;

my $total = scalar(@available_drivers) * TESTS_PER_DRIVER;
plan tests => $total;

foreach my $d ( @available_drivers ) {
SKIP: {
        unless( has_schema( 'TestApp::User', $d ) ) {
                skip "No schema for '$d' driver", TESTS_PER_DRIVER;
        }
        unless( should_test( $d ) ) {
                skip "ENV is not defined for driver '$d'", TESTS_PER_DRIVER;
        }
        diag("start testing with '$d' handle") if $ENV{TEST_VERBOSE};

        my $handle = get_handle( $d );
        connect_handle( $handle );
        isa_ok($handle->dbh, 'DBI::db');

        {my $ret = init_schema( 'TestApp::User', $handle );
        isa_ok($ret,'DBI::st', "Inserted the schema. got a statement handle back" );}

        {my $ret = init_schema( 'TestApp::Currency', $handle );
        isa_ok($ret,'DBI::st', "Inserted the schema. got a statement handle back" );}

        {my $ret = init_schema( 'TestApp::Food', $handle );
        isa_ok($ret,'DBI::st', "Inserted the schema. got a statement handle back" );}

        # USD
        my $usd = TestApp::Currency->new( handle => $handle );
        isa_ok($usd, 'Jifty::DBI::Record');

        my ($id) = $usd->create( name => "USD" );
        ok($id, "got id");
        ok($usd->load($id), "loaded the just created currency record (USD)");
        is($usd->name, "USD", "same name");

        # GBP
        my $gbp = TestApp::Currency->new(handle=>$handle);
        isa_ok($usd, 'Jifty::DBI::Record');

        my ($gid) = $gbp->create( name => "GBP" );
        ok($gid, "got id");
        ok($gbp->load($gid), "loaded the just created currency record (GBP)");
        is($gbp->name, "GBP", "same name");
        
        my $rec = TestApp::Food->new( handle => $handle );
        isa_ok($rec, 'Jifty::DBI::Record');

        my ($paella) = $rec->create( name => "paella" );
        $rec->create( name => "nigiri" );

        # create using currency string
        $rec = TestApp::User->new( handle => $handle );
        ($id) = $rec->create( currency => 'USD' );

        ok($id);
        ok($rec->load($id), "Loaded the record");
        isa_ok($rec->currency, 'TestApp::Currency');
        is($rec->currency->name, 'USD');

        is( $rec->food, undef, 'null_reference option in effect' );
        
        {
            no warnings 'once';
            local *TestApp::User::null_reference = sub {0};
            $rec->load($id);
            isa_ok($rec->food, 'TestApp::Food', 'referee is null but shuold still return an object');
            is($rec->food->id, undef);
        }

        # create using currency object
        $rec = TestApp::User->new( handle => $handle );
        ($id) = $rec->create( currency => $usd );

        ok($id);
        ok($rec->load($id), "Loaded the record");
        isa_ok($rec->currency, 'TestApp::Currency');
        is($rec->currency->name, 'USD');

        my $food = TestApp::Food->new( handle => $handle );
        $food->load($paella);

        # create with undef, set using currency string
        $rec = TestApp::User->new( handle => $handle );
        ($id) = $rec->create(food => $food);

        ok($id);
        ok($rec->load($id), "Loaded the record");
        is($rec->currency, undef, 'No currency object');
        $rec->set_currency('USD');
        isa_ok($rec->currency, 'TestApp::Currency');
        is($rec->currency->name, 'USD');

        # create with undef, set using currency object
        $rec = TestApp::User->new( handle => $handle );
        ($id) = $rec->create(food => $food);

        ok($id);
        ok($rec->load($id), "Loaded the record");
        is($rec->currency, undef, 'No currency object');
        $rec->set_currency($gbp);
        isa_ok($rec->currency, 'TestApp::Currency');
        is($rec->currency->name, 'GBP');

        # load_by_cols with object
        $rec = TestApp::User->new(handle=>$handle);
        $rec->load_by_cols( currency => $usd );

        ok($rec->id, "got id");
        is($rec->currency->name, "USD", "got currency");

        # limit with object
        my $users = TestApp::UserCollection->new(handle => $handle);
        $users->limit( column => 'currency', value => $usd );

        is($users->count, 3, "got 3 users");
        is($users->first->currency->name, "USD", "got USD");

        $users = TestApp::UserCollection->new(handle => $handle);
        $users->limit( column => 'currency', value => $gbp );
        is($users->count, 1, "got 1 users");
        
        # limit with mixed array
        $users = TestApp::UserCollection->new(handle => $handle);
        $users->limit( column => 'currency', value => [$gbp, 'USD'] );
        is($users->count, 4, "got 4 users");
}
}

package TestApp::Currency;
use base qw/Jifty::DBI::Record/;
sub schema_sqlite {

<<EOF;
CREATE table currencies (
        id integer primary key,
        name varchar
)
EOF

}

sub schema_mysql {

<<EOF;
CREATE TEMPORARY table currencies (
        id integer auto_increment primary key,
        name varchar(50)
)
EOF

}

sub schema_pg {

<<EOF;
CREATE TEMPORARY table currencies (
        id serial primary key,
        name varchar
)
EOF
}

use Jifty::DBI::Schema;
use Jifty::DBI::Record schema {

column name => type is 'varchar';

};

package TestApp::Food;
use base qw/Jifty::DBI::Record/;

sub schema_sqlite {

<<EOF;
CREATE table foods (
        id integer primary key,
        name varchar
)
EOF

}

sub schema_mysql {

<<EOF;
CREATE TEMPORARY table foods (
        id integer auto_increment primary key,
        name varchar(50)
)
EOF

}

sub schema_pg {

<<EOF;
CREATE TEMPORARY table foods (
        id serial primary key,
        name varchar
)
EOF
}

use Jifty::DBI::Schema;
use Jifty::DBI::Record schema {

column name    =>
  type is 'varchar';

};


package TestApp::User;
use base qw/Jifty::DBI::Record/;

sub schema_sqlite {

<<EOF;
CREATE table users (
        id integer primary key,
        food integer,
        currency varchar
)
EOF

}

sub schema_mysql {

<<EOF;
CREATE TEMPORARY table users (
        id integer auto_increment primary key,
        food integer,
        currency varchar(50)
)
EOF

}

sub schema_pg {

<<EOF;
CREATE TEMPORARY table users (
        id serial primary key,
        food integer,
        currency varchar
)
EOF

}

use Jifty::DBI::Schema;
use Jifty::DBI::Record schema {

column currency    =>
  type is 'varchar',
  refers_to TestApp::Currency by 'name';

column food    =>
  refers_to TestApp::Food;

};

package TestApp::UserCollection;
use base qw/Jifty::DBI::Collection/;

1;
