use strict;
use warnings;
use Test::More tests => 5;

use HTML::FormFu;
use lib 't/lib';
use DBICTestLib 'new_schema';
use MySchema;

my $form = HTML::FormFu->new;

$form->load_config_file('t/update/ignore_if_empty.yml');

my $schema = new_schema();

my $rs = $schema->resultset('User')->create( {
        master => 1,
        name   => "foo",
        title  => 'bar'
    } );

is( $rs->name, "foo" );

{
    $form->process( { name => 'test' } );

    $form->model->update($rs);

    is( $rs->name, "test" );
}

{
    $form->process( { name => undef } );

    $form->model->update($rs);

    is( $rs->name, "test" );
}

{
    $form->process( { name => 0 } );

    $form->model->update($rs);

    is( $rs->name, "0" );
}

{
    $form->process( { name => " " } );

    $form->model->update($rs);

    is( $rs->name, " " );
}
