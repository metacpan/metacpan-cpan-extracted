use strict;
use warnings;

use lib 't/lib';

use Test::More tests => 27;
use File::Basename;
use File::Spec;
use Footprintless;
use Footprintless::Util qw(
    dumper
    factory
    slurp
    spurt
    temp_dir
);

BEGIN { use_ok('Footprintless::Plugin::Database::AbstractProvider') }
BEGIN { use_ok('Footprintless::Plugin::Database') }
BEGIN { use_ok('Footprintless::Plugin::Database::Command::db') }

eval {
    require Getopt::Long;
    Getopt::Long::Configure( 'pass_through', 'bundling' );
    my $level = 'error';
    Getopt::Long::GetOptions( 'log:s' => \$level );

    require Log::Any::Adapter;
    Log::Any::Adapter->set( 'Stdout',
        log_level => Log::Any::Adapter::Util::numeric_level($level) );
};

my $logger = Log::Any->get_logger();

my $test_dir = dirname( File::Spec->rel2abs($0) );

sub csv_db {
    my ( $data_dir, $spec ) = @_;

    foreach my $table ( keys(%$spec) ) {
        write_csv( $data_dir, $table, $spec->{$table}{columns}, $spec->{$table}{values} );
    }

    my $fpl = factory(
        {   footprintless => {
                plugins                           => [ 'Footprintless::Plugin::Database' ],
                'Footprintless::Plugin::Database' => {
                    default_provider => 'csv',
                    providers        => { csv => 'Footprintless::Plugin::Database::CsvProvider' }
                }
            },
            db => { f_dir => $data_dir }
        }
    );

    return $fpl->db('db');
}

sub write_csv {
    my ( $data_dir, $table, $columns, $values ) = @_;
    my @data = ();
    push( @data, join( ',', map {"\"$_\""} @$columns ) );
    foreach my $row (@$values) {
        push( @data, join( ',', map {"\"$_\""} @$row ) );
    }

    my $file = File::Spec->catfile( $data_dir, "test" );
    spurt( join( "\n", @data ), $file );
    if ( $logger->is_trace() ) {
        $logger->tracef( "data:\n----------\n%s\n----------\n", slurp($file) );
    }
}

{
    $logger->info("test plugin");

    my $fpl = factory(
        {   footprintless => {
                plugins                           => [ 'Footprintless::Plugin::Database' ],
                'Footprintless::Plugin::Database' => {
                    default_provider => 'csv',
                    providers        => { csv => 'Footprintless::Plugin::Database::CsvProvider' }
                }
            },
            csv     => { provider => 'csv' },
            default => {},
            invalid => { provider => 'invalid' }
        }
    );

    ok( $fpl->db('default')->isa('Footprintless::Plugin::Database::CsvProvider'),
        'got my default' );
    ok( $fpl->db('csv')->isa('Footprintless::Plugin::Database::CsvProvider'), 'got my csv' );
    eval { $fpl->db('invalid')->isa('Footprintless::Plugin::Database::CsvProvider'); };
    like( $@, qr/^unsupported database provider:/, 'invalid provider' );
}

{
    $logger->info("test query");

    my $data_dir = temp_dir();
    my $spec     = {
        test => {
            columns => [ "char_col", "number_col", "string_col" ],
            values => [ [ 'a', 1, 'foo' ], [ 'b', 2, 'bar' ] ]
        }
    };

    my $db = csv_db( $data_dir, $spec );
    ok( $db, 'got my query db' );

    my @got       = ();
    my @got_where = ();
    eval {
        $db->connect();
        $db->query(
            "select char_col, number_col, string_col from test",
            sub {
                push( @got, \@_ );
            }
        );
        $db->query(
            {   sql => q[
                    select char_col, number_col, string_col
                    from test 
                    where char_col = ? 
                        or char_col = ?
                ],
                parameters => [ 'a', 'b' ]
            },
            sub {
                push( @got_where, \@_ );
            }
        );
    };
    my $error = $@;
    $db->disconnect();
    $error ? fail( 'query: ' . $@ ) : pass('query');
    is_deeply( \@got,       $spec->{test}{values}, 'query result' );
    is_deeply( \@got_where, $spec->{test}{values}, 'query where result' );
}

{
    $logger->info("test query for scalar");

    my $data_dir = temp_dir();
    my $spec     = {
        test => {
            columns => [ "char_col", "number_col", "string_col" ],
            values => [ [ 'a', 1, 'foo' ], [ 'b', 2, 'bar' ] ]
        }
    };

    my $db = csv_db( $data_dir, $spec );
    ok( $db, 'got my query_for_scalar db' );

    my $got_default;
    my $got;
    eval {
        $db->connect();
        $got_default = $db->query_for_scalar( { sql => 'select count(*) from test' } );
        $got = $db->query_for_scalar(
            {   sql => q[
                    select char_col, number_col, string_col 
                    from test
                    where char_col = ?
                ],
                parameters => ['a']
            },
            sub {
                return \@_;
            }
        );
    };
    my $error = $@;
    $db->disconnect();
    $error ? fail( 'query_for_scalar: ' . $@ ) : pass('query_for_scalar');
    is_deeply(
        $got_default,
        scalar( @{ $spec->{test}{values} } ),
        'query_for_scalar count result'
    );
    is_deeply( $got, $spec->{test}{values}[0], 'query_for_scalar result' );
}

{
    $logger->info("test query_for_list");

    my $data_dir = temp_dir();
    my $spec     = {
        test => {
            columns => [ "char_col", "number_col", "string_col" ],
            values => [ [ 'a', 1, 'foo' ], [ 'b', 2, 'bar' ] ]
        }
    };

    my $db = csv_db( $data_dir, $spec );
    ok( $db, 'got my query_for_list db' );

    my @got;
    my $got_arrayref;
    eval {
        $db->connect();
        @got = $db->query_for_list(
            { sql => "select char_col, number_col, string_col from test" },
            sub {
                return \@_;
            }
        );
        $got_arrayref = $db->query_for_list(
            { sql => "select char_col, number_col, string_col from test" },
            sub {
                return \@_;
            }
        );
    };
    my $error = $@;
    $db->disconnect();
    $error ? fail( 'query_for_list: ' . $@ ) : pass('query_for_list');
    is_deeply( \@got,         $spec->{test}{values}, 'query_for_list result' );
    is_deeply( $got_arrayref, $spec->{test}{values}, 'query_for_list result arrayref' );
}

{
    $logger->info("test query_for_map");

    my $data_dir = temp_dir();
    my $spec     = {
        test => {
            columns => [ "char_col", "number_col", "string_col" ],
            values => [ [ 'a', 1, 'foo' ], [ 'b', 2, 'bar' ] ]
        }
    };

    my $db = csv_db( $data_dir, $spec );
    ok( $db, 'got my query_for_map db' );

    my %got_default;
    my $got_hashref_default;
    my %got;
    my $got_hashref;
    eval {
        $db->connect();
        %got_default =
            $db->query_for_map( { sql => "select char_col, number_col, string_col from test" } );
        $got_hashref_default =
            $db->query_for_map( { sql => "select char_col, number_col, string_col from test" } );
        %got = $db->query_for_map(
            { sql => "select char_col, number_col, string_col from test" },
            sub {
                return [ $_[0] => \@_ ];
            }
        );
        $got_hashref = $db->query_for_map(
            { sql => "select char_col, number_col, string_col from test" },
            sub {
                return [ $_[0] => \@_ ];
            }
        );
    };
    my $error = $@;
    $db->disconnect();
    $error ? fail( 'query_for_map: ' . $@ ) : pass('query_for_map');
    my %expected = map { $_->[0] => $_ } @{ $spec->{test}{values} };
    is_deeply( \%got_default,        \%expected, 'query_for_map defaut result' );
    is_deeply( $got_hashref_default, \%expected, 'query_for_map defaut result arrayref' );
    is_deeply( \%got,                \%expected, 'query_for_map result' );
    is_deeply( $got_hashref,         \%expected, 'query_for_map result arrayref' );
}

{
    $logger->info("test execute");

    my $data_dir = temp_dir();
    my $spec     = {};

    my $db = csv_db( $data_dir, $spec );
    ok( $db, 'got my execute db' );

    my $got;
    eval {
        $db->connect();
        $got = $db->execute(
            {   sql => q[
                    create table test(
                        char_col char(1), 
                        number_col int, 
                        string_col varchar(256)
                    )]
            }
        );
    };
    my $error = $@;
    $db->disconnect();
    $error ? fail( 'execute: ' . $@ ) : pass('execute');
    is_deeply( $got, '0E0', 'execute result' );
}
