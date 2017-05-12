use strict;
use warnings;
use Test::More tests => 10;

use HTML::FormFu;
use lib 't/lib';
use DBICTestLib 'new_schema';
use MySchema;

my $form = HTML::FormFu->new;

$form->load_config_file('t/default_values/has_many_repeatable_label.yml');

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
        name      => 'nick',
        addresses => [
            { address => 'home', my_label => 'label 1' },
            { address => 'office', my_label => 'label 2' },
            ] } );

{
    my $row = $schema->resultset('User')->find(4);

    $form->model->default_values($row);

    is( $form->get_field('id')->default,    '4' );
    is( $form->get_field('name')->default,  'nick' );
    is( $form->get_field('count')->default, '2' );

    my $block = $form->get_all_element( { nested_name => 'addresses' } );

    my @reps = @{ $block->get_elements };

    is( scalar @reps, 2 );

    is( $reps[0]->get_field('id')->default,      '2' );
    is( $reps[0]->get_field('address')->default, 'home' );
    is( $reps[0]->get_field('address')->label,   'label 1' );

    is( $reps[1]->get_field('id')->default,      '3' );
    is( $reps[1]->get_field('address')->default, 'office' );
    is( $reps[1]->get_field('address')->label,   'label 2' );
}

