use strict;
use warnings;
use Test::More tests => 3;

use HTML::FormFu;
use lib 't/lib';
use DBICTestLib 'new_schema';
use MySchema;

my $form = HTML::FormFu->new;

$form->load_config_file('t/default_values/empty_rows_zero.yml');

my $schema = new_schema();

my $master = $schema->resultset('Master')->create({ id => 1 });

# filler

$master->create_related( 'user', {
        name      => 'filler',
        addresses => [ { address => 'somewhere', } ] } );

$master->create_related( 'user', { name => 'filler2', } );
$master->create_related( 'user', { name => 'filler3', } );

# row we're going to use

$master->create_related( 'user', {
        name      => 'nick' } );

{
    my $row = $schema->resultset('User')->find(4);

    $form->model->default_values($row);

    is( $form->get_field('id')->default,    '4' );
    is( $form->get_field('count')->default, '0' );

    my $block = $form->get_all_element( { nested_name => 'addresses' } );

    my @reps = @{ $block->get_elements };

    is( scalar @reps, 0 );

}
