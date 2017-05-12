use Test::More tests => 5;

use HTML::FormFu::ExtJS::Grid;
use strict;
use warnings;

use lib qw(t/lib);

use Data::Dumper;

my $form = new HTML::FormFu::ExtJS;
$form->load_config_file('t/grid_data/dbic/basic.yml');

eval { my $data = $form->grid_data('foo') };

ok( $@, 'croak on not array ref data' );

my $data = $form->grid_data(
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

my $result = {
    'metaData' => {
        'fields' => [
            { 'name' => 'name', 'type' => 'string', mapping => 'name' },
            {
                'name'  => 'sexValue',
                'type'  => 'string',
                mapping => 'sex.value'
            },
            { 'name' => 'sex', 'type' => 'string', mapping => 'sex.label' },
            { 'name' => 'cds', 'type' => 'string', mapping => 'cds' }
        ],
        'totalProperty' => 'results',
        'root'          => 'rows',
        idProperty      => 'id',
    },
    'rows' => [
        {
            'cds'  => 3,
            'name' => 'Caterwauler McCrae',
            sex    => { label => 'male', value => 0 }
        },
        {
            'cds'  => 1,
            'name' => 'Random Boy Band',
            sex    => { label => 'female', value => 1 }
        },
        {
            'cds'  => 1,
            'name' => 'We Are Goth',
            sex    => { label => 'male', value => 0 }
        }
    ],
    'results' => 3
};

my $rows = [
    { 'cds' => 3, 'name' => 'Caterwauler McCrae', sex => 0 },
    { 'cds' => 1, 'name' => 'Random Boy Band',    sex => 1 },
    { 'cds' => 1, 'name' => 'We Are Goth',        sex => 0 }
];

$form = new HTML::FormFu::ExtJS;
$form->load_config_file('t/grid_data/dbic/advanced_1.yml');
$data = $form->grid_data($rows);
is_deeply( $data, $result );

$form = new HTML::FormFu::ExtJS;
$form->load_config_file('t/grid_data/dbic/advanced_2.yml');
$data = $form->grid_data($rows);
is_deeply( $data, $result );

$form = new HTML::FormFu::ExtJS;
$form->load_config_file('t/grid_data/dbic/advanced_3.yml');
$data = $form->grid_data($rows);
is_deeply( $data, $result );
