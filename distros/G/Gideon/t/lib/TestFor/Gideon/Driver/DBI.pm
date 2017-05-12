package TestFor::Gideon::Driver::DBI;
use Test::Class::Moose;
use DBI;
use DBI::Customer;
use DBI::Person;

with 'Test::Class::Moose::Role::AutoUse';

sub test_setup {
    my $self = shift;

    my $dbh = DBI->connect( 'dbi:Mock:', undef, undef, { RaiseError => 1 } );
    Gideon::Registry->register_store( 'dbi', $dbh );

    $self->{dbh}    = $dbh;
    $self->{driver} = Gideon::Driver::DBI->new;
}

sub test_find {
    my $self = shift;

    $self->{dbh}->{mock_session} = DBD::Mock::Session->new(
        test => (
            {
                statement => qr/SELECT alias, id FROM customer .*< 1/ism,
                results   => [ [ 'id', 'alias' ], [ 1, 'joe doe' ] ],
            },
            {
                statement => qr/SELECT alias, id FROM customer ORDER BY id/ism,
                results =>
                  [ [ 'alias', 'id' ], [ 'joe doe', 1 ], [ 'jack bauer', 2 ] ],
            },
        )
    );

    my $rs = $self->{driver}->_find( 'DBI::Customer', { id => 1 }, undef, 1 );
    is scalar @$rs, 1, 'find: size';
    is $rs->[0]->id,   1,         'find: id';
    is $rs->[0]->name, 'joe doe', 'find: value';

    $rs = $self->{driver}->_find( 'DBI::Customer', undef, ['id'] );
    is scalar @$rs, 2, 'find: size';
    is $rs->[0]->name, 'joe doe',    'find: value #1';
    is $rs->[1]->name, 'jack bauer', 'find: value #2';
}

sub test_save {
    my $self = shift;

    $self->{dbh}->{mock_start_insert_id} = 11;
    $self->{dbh}->{mock_session}         = DBD::Mock::Session->new(
        test => (
            {
                statement    => qr/INSERT INTO customer \( alias\)/smi,
                results      => [ ['rows'], [] ],
                bound_params => ['joe doe'],
            },
        )
    );

    my $customer = DBI::Customer->new( name => 'joe doe' );
    ok( $self->{driver}->_insert_object($customer), 'insert: result' );
    is $customer->id, 11, 'insert: serial value seeting';
}

sub test_update_object {
    my $self = shift;

    $self->{dbh}->{mock_session} = DBD::Mock::Session->new(
        test => (
            {
                statement =>
                  qr/UPDATE customer SET id = \? WHERE \( id = \? \)/sm,
                results => [ ['rows'], [] ],
                bound_params => [ 2, 1 ],
            },
            {
                statement =>
                  qr/WHERE \( \( first_name = \? AND last_name = \? \) \)/sm,
                results => [ ['rows'], [] ],
                bound_params => [ 'Joe', 'John', 'Doe' ],
            },

        )
    );

    my $customer =
      DBI::Customer->new( id => 1, name => 'joe doe', __is_persisted => 1 );

    ok( $self->{driver}->_update_object( $customer, { id => 2 } ),
        'update: object' );

    my $person = DBI::Person->new(
        first_name     => 'John',
        last_name      => 'Doe',
        __is_persisted => 1
    );

    ok( $self->{driver}->_update_object( $person, { first_name => 'Joe' } ),
        'update: object w/o PK' );
}

sub test_update_all {
    my $self = shift;

    $self->{dbh}->{mock_session} = DBD::Mock::Session->new(
        test => (
            {
                statement    => qr/UPDATE customer SET alias = \?/,
                results      => [ ['rows'], [], [], [] ],
                bound_params => [ 'jack', ],
            },
            {
                statement =>
                  qr/UPDATE customer SET alias = \? WHERE \( alias = \? \)/,
                results => [ ['rows'], [], [], [] ],
                bound_params => [ 'jack', 'joe' ],
            },

        )
    );

    ok( $self->{driver}->_update( 'DBI::Customer', { name => 'jack' } ),
        'update: all' );
    ok(
        $self->{driver}
          ->_update( 'DBI::Customer', { name => 'jack' }, { name => 'joe' } ),
        'update: all with filter'
    );
}

sub test_remove_object {
    my $self = shift;

    $self->{dbh}->{mock_session} = DBD::Mock::Session->new(
        test => (
            {
                statement    => qr/DELETE FROM customer WHERE \( id = \? \)/sm,
                results      => [ ['rows'], [] ],
                bound_params => [1],
            },
            {
                statement =>
                  qr/WHERE \( \( first_name = \? AND last_name = \? \) \)/sm,
                results => [ ['rows'], [] ],
                bound_params => [ 'John', 'Doe' ],
            }
        )
    );

    my $customer = DBI::Customer->new(
        id             => 1,
        name           => 'joe doe',
        __is_persisted => 1
    );
    ok( $self->{driver}->_remove_object($customer), 'remove: object' );

    my $person = DBI::Person->new(
        first_name     => 'John',
        last_name      => 'Doe',
        __is_persisted => 1
    );
    ok( $self->{driver}->_remove_object($person), 'remove: object w/o PK' );
}

sub test_remove_all {
    my $self = shift;

    $self->{dbh}->{mock_session} = DBD::Mock::Session->new(
        test => (
            {
                statement => qr/DELETE FROM customer/,
                results   => [ ['rows'], [], [], [] ],
            },
            {
                statement    => qr/DELETE FROM customer WHERE \( alias = \? \)/,
                results      => [ ['rows'], [], [], [] ],
                bound_params => ['jack'],
            }
        )
    );

    ok( $self->{driver}->_remove('DBI::Customer'), 'remove: all' );
    ok( $self->{driver}->_remove( 'DBI::Customer', { name => 'jack' } ),
        'remove: all with filter' );
}

1;
