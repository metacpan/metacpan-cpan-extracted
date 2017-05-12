use strict;
use warnings;
use Test::More tests => 3;

use HTML::FormFu;
use lib 't/lib';
use DBICTestLib 'new_schema';
use MySchema;

my $form = HTML::FormFu->new;

$form->load_config_file('t/update/might_have.yml');

my $schema = new_schema();

my $rs = $schema->resultset('Master');

# filler rows
{
    # master 1
    $rs->create( { text_col => 'xxx' } );

    # master 2
    my $m2 = $rs->create( { text_col => 'yyy' } );

    # note 1
    $m2->new_related( 'note', { note => 'zzz' } );
}

# rows we're going to use
{
    # master 3
    my $m3 = $rs->create( { text_col => 'b' } );

    # note 2
    $m3->new_related( 'note', { note => 'aaa' } );
}

{
    $form->process( {
        "id"        => 3,
        "text_col"  => 'a',
        "note.id"   => 2,
        "note.note" => 'abc',
    } );

    my $row = $schema->resultset('Master')->find(3);

    $form->model->update($row);
}

{
    my $row = $schema->resultset('Master')->find(3);

    is( $row->text_col, 'a' );

    my $note = $row->note;

    is( $note->id,   2 );
    is( $note->note, 'abc' );
}

