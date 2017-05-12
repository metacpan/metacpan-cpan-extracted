#!/usr/bin/env perl -w


use strict;
use warnings;
use File::Spec;
use Test::More;

BEGIN { require "t/utils.pl" }
our (@available_drivers);

use constant TESTS_PER_DRIVER => 68;

my $total = scalar(@available_drivers) * TESTS_PER_DRIVER;
plan tests => $total;

foreach my $d ( @available_drivers ) {
SKIP: {
        unless( has_schema( 'TestApp', $d ) ) {
                skip "No schema for '$d' driver", TESTS_PER_DRIVER;
        }
        unless( should_test( $d ) ) {
                skip "ENV is not defined for driver '$d'", TESTS_PER_DRIVER;
        }

        my $handle = get_handle( $d );
        connect_handle( $handle );
        isa_ok($handle->dbh, 'DBI::db', "Got handle for $d");

        {my $ret = init_schema( 'TestApp', $handle );
        isa_ok($ret,'DBI::st', "Inserted the schema. got a statement handle back" );}

        my $emp = TestApp::Employee->new( handle => $handle );
        my $e_id = $emp->create( name => 'RUZ' );
        ok($e_id, "Got an id for the new employee: $e_id");
        $emp->load($e_id);
        is($emp->id, $e_id);
        is($emp->pid, $$);

        my $phone_collection = $emp->phones;
        isa_ok($phone_collection, 'TestApp::PhoneCollection');

        {
                my ($val, $msg);
                eval { ($val, $msg) = $emp->set_phones(1,2,3); };
                ok(not($@), 'set does not die') or warn $@;
                ok($@ !~ /^DBD::.*::st execute failed: /,
                        "no stacktrace emitted"
                        );
                ok(! $val, $msg) or warn "msg: $msg";
                ok($msg =~ m/Collection column '.*' not writable/,
                        '"not writable" message'
                        );
        }
        
        {
            my $ph = $phone_collection->next;
            is($ph, undef, "No phones yet");
        }
        
        my $phone = TestApp::Phone->new( handle => $handle );
        isa_ok( $phone, 'TestApp::Phone');
        my $p_id = $phone->create( employee => $e_id, phone => '+7(903)264-03-51');
        is($p_id, 1, "Loaded phone $p_id");
        $phone->load( $p_id );

        my $obj = $phone->employee;

        ok($obj, "Employee #$e_id has phone #$p_id");
        isa_ok( $obj, 'TestApp::Employee');
        is($obj->id, $e_id);
        is($obj->name, 'RUZ');
        
        {
            $phone_collection->redo_search;
            my $ph = $phone_collection->next;
            isa_ok($ph, 'TestApp::Phone');
            is($ph->id, $p_id, 'found first phone');
            is($ph->phone, '+7(903)264-03-51');
            is($phone_collection->next, undef);
        }

        # tests for no object mapping
        my $val = $phone->phone;
        is( $val, '+7(903)264-03-51', 'Non-object things still work');
        
        my $emp2 = TestApp::Employee->new( handle => $handle );
        isa_ok($emp2, 'TestApp::Employee');
        my $e2_id = $emp2->create( name => 'Dave' );
        ok($e2_id, "Got an id for the new employee: $e2_id");
        $emp2->load($e2_id);
        is($emp2->id, $e2_id);

        my $phone2_collection = $emp2->phones;
        isa_ok($phone2_collection, 'TestApp::PhoneCollection');

        {
            my $ph = $phone2_collection->next;
            is($ph, undef, "new emp has no phones");
        }
        
        {
            $phone_collection->redo_search;
            my $ph = $phone_collection->next;
            isa_ok($ph, 'TestApp::Phone');
            is($ph->id, $p_id, 'first emp still has phone');
            is($ph->phone, '+7(903)264-03-51');
            is($phone_collection->next, undef);
        }

        $phone->set_employee($e2_id);
        
                
        my $emp3 = $phone->employee;
        isa_ok($emp3, 'TestApp::Employee');
        is($emp3->name, 'Dave', 'changed employees by ID');
        is($emp3->id, $emp2->id);

        {
            $phone_collection->redo_search;
            is($phone_collection->next, undef, "first emp lost phone");
        }

        {
            $phone2_collection->redo_search;
            my $ph = $phone2_collection->next;
            isa_ok($ph, 'TestApp::Phone');
            is($ph->id, $p_id, 'new emp stole the phone');
            is($ph->phone, '+7(903)264-03-51');
            is($phone2_collection->next, undef);
        }


        $phone->set_employee($emp);

        my $emp4 = $phone->employee;
        isa_ok($emp4, 'TestApp::Employee');
        is($emp4->name, 'RUZ', 'changed employees by obj');
        is($emp4->id, $emp->id);

        {
            $phone2_collection->redo_search;
            is($phone2_collection->next, undef, "second emp lost phone");
        }

        {
            $phone_collection->redo_search;
            my $ph = $phone_collection->next;
            isa_ok($ph, 'TestApp::Phone');
            is($ph->id, $p_id, 'first emp stole the phone');
            is($ph->phone, '+7(903)264-03-51');
            is($phone_collection->next, undef);
        }
        
        my $phone2 = TestApp::Phone->new( handle => $handle );
        isa_ok( $phone2, 'TestApp::Phone');
        my $p2_id = $phone2->create( employee => $e_id, phone => '123456');
        ok($p2_id, "Loaded phone $p2_id");
        $phone2->load( $p2_id );
        
        {
            $phone_collection->redo_search;
            my $ph = $phone_collection->next;
            isa_ok($ph, 'TestApp::Phone');
            is($ph->id, $p_id, 'still has this phone');
            is($ph->phone, '+7(903)264-03-51');
            $ph = $phone_collection->next;
            isa_ok($ph, 'TestApp::Phone');
            is($ph->id, $p2_id, 'now has that phone');
            is($ph->phone, '123456');
            is($phone_collection->next, undef);
        }
        
        # Test Create with obj as argument
        my $phone3 = TestApp::Phone->new( handle => $handle );
        isa_ok( $phone3, 'TestApp::Phone');
        my $p3_id = $phone3->create( employee => $emp, phone => '7890');
        ok($p3_id, "Loaded phone $p3_id");
        $phone3->load( $p3_id );
        
        {
            $phone_collection->redo_search;
            my $ph = $phone_collection->next;
            isa_ok($ph, 'TestApp::Phone');
            is($ph->id, $p_id, 'still has this phone');
            is($ph->phone, '+7(903)264-03-51');
            $ph = $phone_collection->next;
            isa_ok($ph, 'TestApp::Phone');
            is($ph->id, $p2_id, 'still has that phone');
            is($ph->phone, '123456');
            $ph = $phone_collection->next;
            isa_ok($ph, 'TestApp::Phone');
            is($ph->id, $p3_id, 'even has this other phone');
            is($ph->phone, '7890');
            is($phone_collection->next, undef);
        }
        
        

        cleanup_schema( 'TestApp', $handle );
        disconnect_handle( $handle );
}} # SKIP, foreach blocks

1;


package TestApp;
sub schema_sqlite {
[
q{
CREATE table employees (
        id integer primary key,
        name varchar(36)
)
}, q{
CREATE table phones (
        id integer primary key,
        employee integer NOT NULL,
        phone varchar(18)
) }
]
}

sub schema_mysql {
[ q{
CREATE TEMPORARY table employees (
        id integer AUTO_INCREMENT primary key,
        name varchar(36)
)
}, q{
CREATE TEMPORARY table phones (
        id integer AUTO_INCREMENT primary key,
        employee integer NOT NULL,
        phone varchar(18)
)
} ]
}

sub schema_pg {
[ q{
CREATE TEMPORARY table employees (
        id serial PRIMARY KEY,
        name varchar
)
}, q{
CREATE TEMPORARY table phones (
        id serial PRIMARY KEY,
        employee integer references employees(id),
        phone varchar
)
} ]
}

package TestApp::PhoneCollection;
use base qw/Jifty::DBI::Collection/;

sub table {
    my $self = shift;
    my $tab = $self->new_item->table();
    return $tab;
}

package TestApp::Employee;
use base qw/Jifty::DBI::Record/;

BEGIN {
    use Jifty::DBI::Schema;
    use Jifty::DBI::Record schema {
        column name => type is 'varchar';
        column phones => references TestApp::PhoneCollection by 'employee';
        column pid => is computed;
    };

    sub pid { $$ }
}

sub _value  {
  my $self = shift;
  my $x =  ($self->__value(@_));
  return $x;
}


package TestApp::Phone;

BEGIN {
    use Jifty::DBI::Schema;
    use Jifty::DBI::Record schema {;
    column employee => refers_to TestApp::Employee; # "refers_to" is the old synonym to "references"
    column phone    => type is 'varchar';
    }
}


1;
