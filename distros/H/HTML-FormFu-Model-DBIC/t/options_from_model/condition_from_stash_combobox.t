use strict;
use warnings;
use Test::More tests => 11;

use HTML::FormFu;
use lib 't/lib';
use DBICTestLib 'new_schema';
use MySchema;
my $form = HTML::FormFu->new;

$form->load_config_file('t/options_from_model/condition_from_stash_combobox.yml');

my $schema = new_schema();

$form->stash->{schema} = $schema;

my $master_rs = $schema->resultset('Master');
my $user_rs   = $schema->resultset('User');

{
    my $m1 = $master_rs->create({ text_col => 'foo' });

    $m1->create_related( 'user', { name => 'a' } );
    $m1->create_related( 'user', { name => 'b' } );
    $m1->create_related( 'user', { name => 'c' } );
}

{
    my $m2 = $master_rs->create({ text_col => 'bar' });

    $m2->create_related( 'user', { name => 'd' } );
    $m2->create_related( 'user', { name => 'e' } );
    $m2->create_related( 'user', { name => 'f' } );
    $m2->create_related( 'user', { name => 'g' } );

    # master_id contains unique id
    $form->stash->{master_id} = $m2->id;
}

$form->process;

{
    my $option = $form->get_field('user')->options;

    ok( @$option == 5 );

    is( $option->[0]->{label}, '' );
    is( $option->[1]->{label}, 'd' );
    is( $option->[2]->{label}, 'e' );
    is( $option->[3]->{label}, 'f' );
    is( $option->[4]->{label}, 'g' );
}

$form = HTML::FormFu->new;
$form->load_config_file('t/options_from_model/condition_from_stash_combobox.yml');
$form->stash->{schema} = $schema;
$form->stash->{master_id} = {'!=' => '2' };
$form->process;

{
    my $option = $form->get_field('user')->options;

    ok( @$option == 4 );

    is( $option->[0]->{label}, '' );
    is( $option->[1]->{label}, 'a' );
    is( $option->[2]->{label}, 'b' );
    is( $option->[3]->{label}, 'c' );
}

