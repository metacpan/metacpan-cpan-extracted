use strict;
use warnings;
use Melian;
use Test::More;
use List::Util qw(first);

plan( skip_all => 'Live Melian testing disabled - set MELIAN_LIVE_TEST=1' ) unless $ENV{'MELIAN_LIVE_TEST'};

my $melian = Melian->new(
    'dsn'     => 'unix:///tmp/melian.sock',
    'timeout' => 1,
);

subtest 'Connection' => sub {
    isa_ok($melian, 'Melian');
    ok( $melian->{'socket'}, 'Socket starts established due to new() call' );
    isa_ok( $melian->{'schema'}, 'HASH' );
};

subtest 'table1 by id' => sub {
    my $record_id = 5;
    my $table_name = 'table1';
    my $column_name = 'id';
    my $table = List::Util::first( sub { $_->{'name'} eq $table_name }, @{ $melian->{'schema'}{'tables'} } );
    my $column = List::Util::first( sub { $_->{'column'} eq $column_name }, @{ $table->{'indexes'} } );
    my $payload = $melian->fetch_raw($table->{'id'}, $column->{'id'}, pack('V', 5));
    is(
        $payload,
        qq!{"id":$record_id,"name":"item_5","category":"alpha","value":"VAL_0005","description":"Mock description for item 5","created_at":"2025-10-30 14:26:47","updated_at":"2025-11-04 14:26:47","active":1}!,
        'fetch_raw table1 id',
    );

    is_deeply(
        $melian->fetch_by_int($table->{'id'}, $column->{'id'}, $record_id),
        {
            'active'      => 1,
            'category'    => 'alpha',
            'created_at'  => '2025-10-30 14:26:47',
            'description' => 'Mock description for item 5',
            'id'          => $record_id,
            'name'        => 'item_5',
            'updated_at'  => '2025-11-04 14:26:47',
            'value'       => 'VAL_0005',
        },
        "[$table_name] fetch_by_int($table->{'id'}, $column->{'id'})",
    );
};

subtest 'Table2 by id and hostname' => sub {
    my $record_id = 2;
    my $record_hostname = 'host-00002';
    my $table_name = 'table2';
    my $id_column_name = 'id';
    my $hostname_column_name = 'hostname';
    my $table = List::Util::first( sub { $_->{'name'} eq $table_name }, @{ $melian->{'schema'}{'tables'} } );
    my $id_column = List::Util::first( sub { $_->{'column'} eq $id_column_name }, @{ $table->{'indexes'} } );
    my $hostname_column = List::Util::first( sub { $_->{'column'} eq $hostname_column_name }, @{ $table->{'indexes'} } );

    my $expected = {
        'hostname' => 'host-00002',
        'id'       => $record_id,
        'ip'       => '10.0.2.0',
        'status'   => 'maintenance',
     };

    is_deeply(
        $melian->fetch_by_int($table->{'id'}, $id_column->{'id'}, $record_id),
        $expected,
        "$table_name by id",
    );

    is_deeply(
        $melian->fetch_by_string($table->{'id'}, $hostname_column->{'id'}, $record_hostname),
        $expected,
        "$table_name by hostname",
    );
};

subtest 'Schema functions' => sub {
    my $spec = 'table1#0|60|id:int,table2#1|60|id:int;hostname:string';
    my $struct = {
        "tables" => [
            {
                "name"    => "table1",
                "id"      => 0,
                "period"  => 60,
                "indexes" => [
                    {
                        "id"     => 0,
                        "column" => "id",
                        "type"   => "int",
                    }
                ]
            },
            {
                "name"    => "table2",
                "id"      => 1,
                "period"  => 60,
                "indexes" => [
                    {
                        "id"     => 0,
                        "column" => "id",
                        "type"   => "int",
                    },
                    {
                        "id"     => 1,
                        "column" => "hostname",
                        "type"   => "string",
                    }
                ]
            }
        ]
    };

    my $dsn = 'unix:///tmp/melian.sock';
    my $melian_from_spec = Melian->new(
        'dsn'         => $dsn,
        'schema_spec' => $spec,
    );

    my $melian_with_schema = Melian->new(
        'dsn'    => $dsn,
        'schema' => $struct,
    );

    my $melian_from_describe = Melian->new( 'dsn' => $dsn );

    is_deeply(
        $melian_with_schema->{'schema'},
        $melian_from_describe->{'schema'},
        'Describe produces the schema struct we think it should',
    );

    is_deeply(
        $melian_from_spec->{'schema'},
        $melian_from_describe->{'schema'},
        'Melian from spec produces the same as DESCRIBE action',
    );

};

subtest 'Fetch using names' => sub {
    is(
        $melian->fetch_raw_from( 'table1', 'id', pack( 'V', 5 ) ),
        qq!{"id":5,"name":"item_5","category":"alpha","value":"VAL_0005","description":"Mock description for item 5","created_at":"2025-10-30 14:26:47","updated_at":"2025-11-04 14:26:47","active":1}!,
        '->fetch_raw_from( "table1", "id", 5 )',
    );

    is_deeply(
        $melian->fetch_by_int_from( 'table1', 'id', 5 ),
        {
            'active'      => 1,
            'category'    => 'alpha',
            'created_at'  => '2025-10-30 14:26:47',
            'description' => 'Mock description for item 5',
            'id'          => 5,
            'name'        => 'item_5',
            'updated_at'  => '2025-11-04 14:26:47',
            'value'       => 'VAL_0005',
        },
        '->fetch_by_int_from( "table1", "id", 5 )',
    );

    is_deeply(
        $melian->fetch_by_string_from( 'table2', 'hostname', 'host-00002' ),
        {
            'hostname' => 'host-00002',
            'id'       => 2,
            'ip'       => '10.0.2.0',
            'status'   => 'maintenance',
        },
        '->fetch_by_string_from( "table2", "hostname", "host-00002" )',
    );
};

subtest 'Disconnect' => sub {
    ok($melian->disconnect(), 'Closed connection');
};

done_testing();
