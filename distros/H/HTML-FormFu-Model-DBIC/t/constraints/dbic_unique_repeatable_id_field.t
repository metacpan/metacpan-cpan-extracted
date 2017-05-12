use strict;
use warnings;
use Test::More tests => 8;

use HTML::FormFu;
use lib 't/lib';
use DBICTestLib 'new_schema';
use MySchema;

my $schema = new_schema();

my $rs = $schema->resultset('User');

# Pre-existing rows
$rs->create( {
    id    => 1,
    name  => 'a',
    title => 'b',
} );

$rs->create( {
    id    => 2,
    name  => 'e',
    title => 'f',
} );

#
my $form = HTML::FormFu->new;

$form->load_config_file('t/constraints/dbic_unique_repeatable_id_field.yml');

$form->stash->{'schema'} = $schema;

# not valid
# try updating row#1 with the same name as row#2
# fails Unique
{
    $form->process( {
        'user_1.id'    => 1,
        'user_1.name'  => 'e',
        'user_1.title' => 'title',
    } );

    ok( !$form->submitted_and_valid );

    ok( $form->has_errors('user_1.name') );

    like( $form->get_field({ nested_name => 'user_1.name' }), qr/Value already exists/i );
}

# valid
# update row#1 with the same name it already has
{
    $form->process( {
        'user_1.id'    => 1,
        'user_1.name'  => 'a',
        'user_1.title' => 'title',
    } );

    ok( $form->submitted_and_valid );
}

# not valid
# try creating a new row with the same name as row#1
{
    $form->process( {
        'user_1.id'    => '',
        'user_1.name'  => 'a',
        'user_1.title' => 'title',
    } );

    ok( !$form->submitted_and_valid );

    ok( $form->has_errors('user_1.name') );

    like( $form->get_field({ nested_name => 'user_1.name' }), qr/Value already exists/i );
}

# valid
# create new row with a unique name
{
    $form->process( {
        'user_1.id'    => '',
        'user_1.name'  => 'snowflake',
        'user_1.title' => 'title',
    } );

    ok( $form->submitted_and_valid );
}
