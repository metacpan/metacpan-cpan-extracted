use strict;
use warnings;
use Test::More tests => 6;

use HTML::FormFu;
use lib 't/lib';
use DBICTestLib 'new_schema';
use MySchema;
my $form = HTML::FormFu->new;

$form->load_config_file('t/options_from_model/enum_select.yml');

my $schema = new_schema();

$form->stash->{schema} = $schema;

my $master_rs = $schema->resultset('Master');

$form->process;

{
    my $option = $form->get_field('enum_col')->options;

    is( scalar( @$option ), 3 );

    is( $option->[0]->{label}, 'a' );
    is( $option->[1]->{label}, 'b' );
    is( $option->[2]->{label}, 'c' );
}

# ensure the options are set in time for the AutoSet constraint to work

{
    $form->process({
        enum_col => 'a',
    });

    ok( $form->valid('enum_col') );
}

{
    $form->process({
        enum_col => 'd',
    });

    ok( ! $form->valid('enum_col') );
}
