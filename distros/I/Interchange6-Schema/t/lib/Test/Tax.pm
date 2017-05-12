package Test::Tax;

use DateTime;
use Test::Exception;
use Test::MockTime qw( :all );
use Test::Roo::Role;

test 'tax tests' => sub {

    my $self = shift;

    my ( %countries, %states, $rset, @data, $result, %data, $data, $tax );

    my $dt = DateTime->now;

    # fixtures
    $self->countries;
    $self->states;

    cmp_ok( $self->taxes->count, '==', 37, "37 taxes in the table" );

    # some country-level taxes + EU reverse charge

#<<<
@data = (
    [ 'DE VAT Reduced', 'DE VAT Reduced Rate',          7, '1983-07-01', 'DE' ],
    [ 'DE VAT Exempt',  'DE VAT Exempt',                0, '1968-01-01', 'DE' ],
    [ 'MT VAT Reduced', 'Malta VAT Reduced Rate',       5, '1995-01-01', 'MT' ],
    [ 'MT VAT Hotel',   'Malta VAT Hotel Accomodation', 7, '2011-01-01', 'MT' ],
    [ 'MT VAT Exempt',  'Malta VAT Exempt',             0, '1995-01-01', 'MT' ],
    [ 'GB VAT Reduced', 'GB VAT Reduced Rate',          5, '1997-09-01', 'GB' ],
    [ 'GB VAT Exempt',  'GB VAT Exempt',                0, '1973-04-01', 'GB' ],
    [ 'EU reverse charge', 'EU B2B reverse charge',    0, '2000-01-01', undef ],
    [ 'CA GST',         'Canada Goods and Service Tax', 5, '2008-01-01', 'CA' ],
);
#>>>

    lives_ok(
        sub {
            $result = $self->taxes->populate(
                [
                    [
                        'tax_name', 'description',
                        'percent',  'valid_from',
                        'country_iso_code',
                    ],
                    @data
                ]
            );
        },
        "Populate tax table"
    );

    cmp_ok( $self->taxes->count, '==', 46, "46 taxes in the table" );

    # test some incorrect tax entries

    $data = {
        tax_name         => 'IE VAT Standard',
        description      => 'Ireland VAT Standard Rate',
        country_iso_code => 'FooBar',
        percent          => 21,
        valid_from       => '2010-01-01',
        valid_to         => '2011-12-31'
    };
    throws_ok(
        sub { $self->taxes->create($data) },
        qr/iso_code not valid/,
        "Fail create with bad country_iso_code"
    );

    cmp_ok( $self->taxes->count, '==', 46, "46 taxes in the table" );

    # create an old IE rate

    $data = {
        tax_name         => 'IE VAT Standard',
        description      => 'Ireland VAT Standard Rate',
        country_iso_code => 'IE',
        percent          => 21,
        valid_from       => '2010-01-01',
        valid_to         => '2011-12-31'
    };

    lives_ok(
        sub { $result = $self->taxes->create($data) },
        "Create previous IE VAT Standard rate"
    );

    cmp_ok( $self->taxes->count, '==', 47, "47 taxes in the table" );

    throws_ok(
        sub { $result = $self->taxes->create($data) },
        qr/overlaps existing date range/,
        "Fail to create identical tax"
    );

    cmp_ok( $self->taxes->count, '==', 47, "47 taxes in the table" );

    $data->{valid_from} = '2011-01-01';
    $data->{valid_to}   = undef;
    throws_ok(
        sub { $result = $self->taxes->create($data) },
        qr/overlaps existing date range/,
        "Fail to create valid_from in tax 1 and valid_to undef"
    );

    $data->{valid_from} = '2013-01-01';
    throws_ok(
        sub { $result = $self->taxes->create($data) },
        qr/overlaps existing date range/,
        "Fail to create valid_from in tax 2 and valid_to undef"
    );

    $data->{valid_from} = '2009-01-01';
    throws_ok(
        sub { $result = $self->taxes->create($data) },
        qr/overlaps existing date range/,
        "Fail to create valid_from before tax 1 and valid_to undef"
    );

    $data->{valid_to} = '2010-01-01';
    throws_ok(
        sub { $result = $self->taxes->create($data) },
        qr/overlaps existing date range/,
        "Fail to create valid_from before tax 1 and valid_to in tax 1"
    );

    $data->{valid_from} = '2011-01-01';
    $data->{valid_to}   = '2013-01-01';
    throws_ok(
        sub { $result = $self->taxes->create($data) },
        qr/overlaps existing date range/,
        "Fail to create valid_from in tax 1 and valid_to in tax 2"
    );

    $data->{valid_from} = '2011-01-01';
    $data->{valid_to}   = '2011-01-01';
    throws_ok(
        sub { $result = $self->taxes->create($data) },
        qr/valid_to is not later than valid_from/,
        "Fail to create valid_from eq valid_to"
    );

    $data->{valid_from} = '2011-01-01';
    $data->{valid_to}   = '2010-01-01';
    throws_ok(
        sub { $result = $self->taxes->create($data) },
        qr/valid_to is not later than valid_from/,
        "Fail to create valid_from > valid_to"
    );

    cmp_ok( $self->taxes->count, '==', 47, "47 taxes in the table" );

    # calculate tax

    throws_ok(
        sub { $tax = $self->taxes->current_tax() },
        qr/tax_name not supplied/,
        "Exception if no tax_name supplied"
    );

    throws_ok(
        sub { $tax = $self->taxes->current_tax('FooBar') },
        qr/not found.*FooBar/,
        "Exception if tax_name not found"
    );

    lives_ok( sub { $tax = $self->taxes->current_tax('MT VAT Standard') },
        "Get current MT tax" );

    cmp_ok( $tax->calculate( { price => 13.47, tax_included => 1 } ),
        '==', 2.05, "Tax on gross 13.47 should be 2.05" );

    cmp_ok( $tax->calculate( { price => 13.47, tax_included => 0 } ),
        '==', 2.42, "Tax on nett 13.47 should be 2.42" );

    lives_ok( sub { $tax = $self->taxes->current_tax('IE VAT Standard') },
        "Get current IE tax" );

    cmp_ok( $tax->calculate( { price => 13.47, tax_included => 0 } ),
        '==', 3.10, "Tax on nett 13.47 should be 3.10" );

    set_absolute_time('2011-01-01T00:00:00Z');

        lives_ok( sub { $tax = $self->taxes->current_tax('IE VAT Standard') },
            "Get IE tax for this historical date" );

        cmp_ok( $tax->calculate( { price => 13.47, tax_included => 0 } ),
            '==', 2.83, "Tax on nett 13.47 should be 2.83" );

    restore_time();

    lives_ok( sub { $tax = $self->taxes->current_tax('IE VAT Standard') },
        "Get current IE tax" );

    cmp_ok( $tax->calculate( { price => 13.47, tax_included => 0 } ),
        '==', 3.10, "Tax on nett 13.47 should be 3.10" );

    # mock time to before any valid ranges

    set_absolute_time('1950-01-01T00:00:00Z');

    throws_ok(
        sub { $tax = $self->taxes->current_tax('IE VAT Standard') },
        qr/not found.*IE VAT/,
        "Exception when tax not found for current date"
    );

    restore_time();

    # some weird decimal_places/ceil/floor taxes

    $data = {
        tax_name         => 'testing',
        description      => 'description',
        country_iso_code => 'IE',
        percent          => 21.333,
        valid_from       => '2010-01-01',
        decimal_places   => 2,
    };
    lives_ok( sub { $tax = $self->taxes->create($data) },
        "Create 21.33% decimal_places 2" );
    cmp_ok( $tax->calculate( { price => 13.47 } ),
        '==', 2.87, "Tax on nett 13.47 should be 2.87" );

    lives_ok( sub { $tax->rounding('f') }, "set rounding floor" );
    cmp_ok( $tax->rounding, 'eq', 'f', "rounding is f" );
    cmp_ok( $tax->calculate( { price => 13.47 } ),
        '==', 2.87, "Tax on nett 13.47 should be 2.87" );

    lives_ok( sub { $tax->rounding('c') }, "set rounding ceiling" );
    cmp_ok( $tax->rounding, 'eq', 'c', "rounding is c" );
    cmp_ok( $tax->calculate( { price => 13.47 } ),
        '==', 2.88, "Tax on nett 13.47 should be 2.88" );

    lives_ok( sub { $tax->rounding(undef) }, "set rounding default" );
    is( $tax->rounding, undef, "rounding is undef" );
    lives_ok( sub { $tax->decimal_places(3) }, "set decimal_places 3" );
    cmp_ok( $tax->calculate( { price => 13.47 } ),
        '==', 2.874, "Tax on nett 13.47 should be 2.874" );

    lives_ok( sub { $tax->rounding('f') }, "set rounding floor" );
    cmp_ok( $tax->calculate( { price => 13.47 } ),
        '==', 2.873, "Tax on nett 13.47 should be 2.873" );

    lives_ok( sub { $tax->rounding('c') }, "set rounding ceiling" );
    cmp_ok( $tax->calculate( { price => 13.47 } ),
        '==', 2.874, "Tax on nett 13.47 should be 2.874" );

    # invalid/missing price

    throws_ok( sub { $tax->calculate( { price => "qw" } ) },
        qr/price.*not.*valid.*qw/, "Exception on invalid price" );
    throws_ok(
        sub { $tax->calculate( { price => undef } ) },
        qr/price is missing/,
        "Exception on undef price"
    );
    throws_ok(
        sub { $tax->calculate( {} ) },
        qr/price is missing/,
        "Exception on no price"
    );

    # rounding input checks

    $data = {
        tax_name       => '1',
        description    => 'description',
        percent        => 21.333,
        valid_from     => '2010-01-01',
        rounding       => 'c',
        decimal_places => 2,
    };
    lives_ok( sub { $tax = $self->taxes->create($data) },
        "new tax with rounding c" );
    cmp_ok( $tax->rounding, 'eq', 'c', "rounding is c" );

    my $taxid = $tax->taxes_id;

    throws_ok(
        sub { $tax->update( { rounding => 2 } ) },
        qr/value for rounding not/,
        "fail rounding 2"
    );

    lives_ok( sub { $tax = $self->taxes->find($taxid) },
        "reload tax from database" );
    cmp_ok( $tax->rounding, 'eq', 'c', "rounding is still c" );

    lives_ok( sub { $tax->update( { rounding => 'C' } ) },
        "set rounding to C" );
    cmp_ok( $tax->rounding, 'eq', 'c', "rounding is c" );
    lives_ok( sub { $tax->update( { rounding => 'F' } ) },
        "set rounding to F" );
    cmp_ok( $tax->rounding, 'eq', 'f', "rounding is f" );

    # exception when impossible rounding value found in database

    lives_ok {
        $self->ic6s_schema->storage->dbh_do(
            sub {
                my ( $storage, $dbh ) = @_;
                $dbh->do(q| UPDATE taxes SET rounding='x' WHERE tax_name='1' |);
            }
        );
    }
    "change rounding to illegal value 'x'";

    lives_ok( sub { $rset = $self->taxes->search( { tax_name => '1' } ) },
        "search for tax with bad rounding in db" );

    cmp_ok( $rset->count, '==', 1, "found it" );

    $tax = $rset->next;
    cmp_ok( $tax->rounding, 'eq', 'x', "rounding is x" );

    throws_ok(
        sub { $tax->calculate( { price => 13.47 } ) },
        qr/rounding value from database is invalid/,
        "Throws rounding value from database is invalid"
    );

    lives_ok( sub { $self->clear_taxes }, "clear_taxes" );

};

1;
