use strict;
use warnings;
use Test::More tests => 7;

use HTML::FormFu;
use lib 't/lib';
use DBICTestLib 'new_schema';
use MySchema;

my $form = HTML::FormFu->new;

$form->load_config_file('t/update/null_if_empty.yml');

my $schema = new_schema();

my $rs = $schema->resultset('User')->create( {
        name   => "foo",
    } );

is( $rs->name, "foo" );

{
    $form->process( { name => "foo", title => "" } );

    $form->model->update($rs);

    is( $rs->title, undef );
}

{
    $form->process( { name => "foo", title => 'test' } );

    $form->model->update($rs);

    is( $rs->title, "test" );
}

{
    $form->process( { name => "foo", title => undef } );

    $form->model->update($rs);

    is( $rs->title, undef );
}

{
    $form->process( { name => "foo", title => 0 } );

    $form->model->update($rs);

    is( $rs->title, "0" );
}

{
    $form->process( { name => "foo", title => " " } );

    $form->model->update($rs);

    is( $rs->title, " " );
}

{
    $form->get_element( name => 'title' )->model_config->{null_if_empty} = 0;

    $form->process( { name => "foo", title => "" } );

    $form->model->update($rs);

    is( $rs->title, "" );
}
