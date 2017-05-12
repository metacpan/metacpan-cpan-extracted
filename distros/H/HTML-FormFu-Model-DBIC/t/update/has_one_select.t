use strict;
use warnings;
use Test::More tests => 5;

use HTML::FormFu;
use lib 't/lib';
use DBICTestLib 'new_schema';
use MySchema;

my $form = HTML::FormFu->new;

$form->load_config_file('t/update/has_one_select.yml');

my $schema = new_schema();

$form->stash->{schema} = $schema;

my $rs = $schema->resultset('Master');

# filler rows
{
    # master 1
    $rs->create( { text_col => 'xxx' } );

    # master 2
    my $m2 = $rs->create( { text_col => 'yyy' } );

    # user 1
    $m2->create_related( 'user', { name => 'zzz' } );
}

# rows we're going to use
{
    # master 3
    my $m3 = $rs->create( { text_col => 'b' } );

    # user 2
    $m3->create_related( 'user', { name => 'xxx' } );
}


{
    $form->process( {
        "id"        => 3,
        "text_col"  => 'a',
        "user"   => 1,
    } );

    ok( $form->submitted_and_valid );

    my $row = $schema->resultset('Master')->find(3);

    $form->model->update($row);

    is($row->user->id, 1);

        $form->process( {
        "id"        => 3,
        "text_col"  => 'a',
        "user"   => 99,
    } );

    ok( $form->submitted_and_valid );
}

{
    my $row = $schema->resultset('Master')->find(3);

    $form->model->update($row);

    is($row->user->id, 1);

    $form = HTML::FormFu->new;

    $form->stash->{schema} = $schema;

    $form->load_config_file('t/update/has_one_select.yml');

    $form->model->default_values($row);

    $form->process;

    like($form, qr/value="1" selected=/);
}

