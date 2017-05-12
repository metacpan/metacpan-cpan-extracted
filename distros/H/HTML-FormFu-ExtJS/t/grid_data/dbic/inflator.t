use Test::More;

use HTML::FormFu::ExtJS::Grid;
use strict;
use warnings;

use lib qw(t/lib);


use Data::Dumper;

BEGIN {
	eval "use DBIx::Class; use DBIx::Class::InflateColumn::DateTime; use DBD::SQLite; use HTML::FormFu::Model::DBIC;";
    plan ( skip_all => 'needs DBIx::Class, HTML::FormFu::Model::DBIC and DBD::SQLite for testing' ) if $@;
}

use DBICTest;
use Data::Dumper;
use DateTime;



my $schema = DBICTest->init_schema();
my $a1 = $schema->resultset('Artist')->create({artistid => 100, birthday => DateTime->new(year => '2009', month => '10', day => '22')});

my $a2 = $schema->resultset('Artist')->create({artistid => 101, birthday => undef});


my $form = new HTML::FormFu::ExtJS;
$form->load_config_file('t/grid_data/dbic/inflator.yml');

my $result = {
    'metaData' => {
        'fields' => [
            { 'name' => 'artistid', 'type' => 'string', mapping => 'artistid' },
            { 'name' => 'birthday',  'type' => 'date', dateFormat => 'Y-m-d', mapping => 'birthday' },
        ],
        'totalProperty' => 'results',
        'root'          => 'rows',
        idProperty => 'id',
    },
    'rows' => [
        { artistid => '100', birthday => '2009-10-22',},
        { artistid => '101', birthday => undef,},
    ],
    'results' => 2
};


my $data = $form->grid_data( [$a1, $a2] );
is_deeply( $data, $result );

done_testing;