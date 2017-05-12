use strict;
use warnings;
use Test::More tests => 4;

use HTML::FormFu;
use lib 't/lib';
use DBICTestLib 'new_schema';
use MySchema;

my $form = HTML::FormFu->new;

$form->load_config_file('t/update/has_one.yml');

my $schema = new_schema();

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
}

{
    $form->process( {
        "id"        => 3,
        "text_col"  => 'a',
        "user.name" => 'bar',
    } );

    ok( $form->submitted_and_valid );

    my $row = $schema->resultset('Master')->find(3);

    $form->model->update($row);
}

{
    my $row = $schema->resultset('Master')->find(3);

    is( $row->text_col, 'a' );

    my $user = $row->user;

    is( $user->id,   2 );
    is( $user->name, 'bar' );
}

