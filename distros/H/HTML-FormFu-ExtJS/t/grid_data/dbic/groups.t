use Test::More;

use HTML::FormFu::ExtJS;
use strict;
use warnings;

use lib qw(t/lib);

BEGIN {
	eval "use DBIx::Class; use DBIx::Class::InflateColumn::DateTime; use DBD::SQLite; use HTML::FormFu::Model::DBIC;";
    plan $@
        ? ( skip_all => 'needs DBIx::Class, HTML::FormFu::Model::DBIC and DBD::SQLite for testing' )
      
      : ( tests => 1 );
}

use DBICTest;
use Data::Dumper;

my $schema = DBICTest->init_schema();

$Data::Dumper::Indent = 0;

my $result = {
    'metaData' => {
        'fields' => [
            { 'name' => 'name',       'type' => 'string', mapping => "name" },
            { 'name' => 'producerid', 'type' => 'string' , mapping => 'producerid' },
            { 'name' => 'cdsValue', 'type' => 'string' , mapping => 'cds.value' },
            { 'name' => 'cds', 'type' => 'string' , mapping => 'cds.label' }
        ],
        'totalProperty' => 'results',
        'root'          => 'rows',
        idProperty => 'id',
    },
    'rows' => [
        { 'cds' => 1, 'name' => 'Matt S Trout',       'producerid' => '1' },
        { 'cds' => 2, 'name' => 'Bob The Builder',    'producerid' => '2' },
        { 'cds' => 1, 'name' => 'Fred The Phenotype', 'producerid' => '3' }
    ],
    'results' => 3
};
my $rs = $schema->resultset("Producer");

my $form = new HTML::FormFu::ExtJS;
$form->load_config_file('t/grid_data/dbic/groups.yml');
is_deeply( $form->grid_data( [ $rs->all ] ), $result );


$result = {
    'metaData' => {
        'fields' => [
            { 'name' => 'name',       'type' => 'string', mapping => "name" },
            { 'name' => 'producerid', 'type' => 'string' , mapping => 'producerid' },
            { 'name' => 'cdsValue', 'type' => 'string' , mapping => 'cds.value' },
            { 'name' => 'cds', 'type' => 'string' , mapping => 'cds.label' }
        ],
        'totalProperty' => 'results',
        'root'          => 'rows',
        idProperty => 'id',
    },
    'rows' => [
        { 'cds' => undef, 'name' => 'Matt S Trout',       'producerid' => '1' },
        { 'cds' => undef, 'name' => 'Bob The Builder',    'producerid' => '2' },
        { 'cds' => undef, 'name' => 'Fred The Phenotype', 'producerid' => '3' }
    ],
    'results' => 3
};
