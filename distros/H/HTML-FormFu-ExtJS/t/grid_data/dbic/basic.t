use Test::More;

use HTML::FormFu::ExtJS::Grid;
use strict;
use warnings;

use lib qw(t/lib);

BEGIN {
    eval
"use DBIx::Class; use DBIx::Class::InflateColumn::DateTime; use DBD::SQLite; use HTML::FormFu::Model::DBIC;";
    plan $@
      ? ( skip_all =>
'needs DBIx::Class, HTML::FormFu::Model::DBIC and DBD::SQLite for testing'
      )
      : ( tests => 5 );
}

use DBICTest;
use Data::Dumper;

my $schema = DBICTest->init_schema();

my $rs =
  $schema->resultset("Artist")->search( undef, { order_by => 'name asc' } );

my $form = new HTML::FormFu::ExtJS;
$form->load_config_file('t/grid_data/dbic/basic.yml');

eval { my $data = $form->grid_data('foo') };

ok( $@, 'croak on not array ref data' );

my $data = $form->grid_data( [ $rs->all ] );
my $expected = {
    'metaData' => {
        'fields' => [
            {
                'name'  => 'artistid',
                'type'  => 'string',
                mapping => "artistid"
            },
            { 'name' => 'name', 'type' => 'string', mapping => 'name' }
        ],
        'totalProperty' => 'results',
        'root'          => 'rows',
        idProperty      => 'id',
    },
    'rows' => [
        {
            'artistid' => '1',
            'name'     => 'Caterwauler McCrae'
        },
        {
            'artistid' => '2',
            'name'     => 'Random Boy Band'
        },
        { 'artistid' => '3', 'name' => 'We Are Goth' }
    ],
    'results' => 3
};
is_deeply( $data, $expected );
my @rows = $rs->all;
$data = $form->grid_data( \@rows );
is_deeply( $data, $expected );
$form->default_model('HashRef');
$data = $form->grid_data(
    [
        {
            'artistid' => '1',
            'name'     => 'Caterwauler McCrae'
        },
        {
            'artistid' => '2',
            'name'     => 'Random Boy Band'
        },
        { 'artistid' => '3', 'name' => 'We Are Goth' }
    ]
);

is_deeply( $data, $expected );

$form->default_model('DBIC');
$data = $form->grid_data( \@rows, { results => 99 } );

$expected->{results} = 99;
is_deeply( $data, $expected );
