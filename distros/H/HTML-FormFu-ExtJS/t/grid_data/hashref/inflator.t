use Test::More;

use HTML::FormFu::ExtJS::Grid;
use strict;
use warnings;

use lib qw(t/lib);

use Data::Dumper;

my $form = new HTML::FormFu::ExtJS;
$form->load_config_file('t/grid_data/hashref/inflator.yml');

my $result = {
    'metaData' => {
        'fields' => [
            { 'name' => 'id', 'type' => 'string', mapping => 'id' },
            {
                'name'     => 'date',
                'type'     => 'date',
                dateFormat => 'Y-m-d',
                mapping    => 'date'
            },
        ],
        'totalProperty' => 'results',
        'root'          => 'rows',
        idProperty      => 'id',
    },
    'rows' => [
        { id => 'foo', date => '2009-10-22', },
        { id => 'foo', date => '2008-12-12', },
        { id => 'bar', date => undef, },
    ],
    'results' => 3
};

my $rows = [
    { 'id' => 'foo', date   => '22.10.2009', },
    { id   => 'foo', 'date' => '12.12.2008', },
    { id   => 'bar', 'date' => undef, },
];

my $data = $form->grid_data($rows);
is_deeply( $data, $result );

done_testing;
