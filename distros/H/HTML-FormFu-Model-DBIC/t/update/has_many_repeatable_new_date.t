use strict;
use warnings;
use Test::More tests => 9;

use HTML::FormFu;
use lib 't/lib';
use DBICTestLib 'new_schema';
use MySchema;
use DateTime;

my $form = HTML::FormFu->new;

$form->load_config_file('t/update/has_many_repeatable_new_date.yml');

my $schema = new_schema();

my $master_rs = $schema->resultset('Master');

# filler rows
{
    # user 1
    my $m1 = $master_rs->create( { text_col => 'foo' } );

    # schedule 1
    $m1->create_related( 'schedules', {
        date => DateTime->new( year => 2008, month => 7, day => 16 ),
        note => 'a',
    } );

    # schedule 2
    $m1->create_related( 'schedules', {
        date => DateTime->new( year => 2008, month => 7, day => 17 ),
        note => 'b',
    } );
}

# rows we're going to use
{
    # user 2
    my $m2 = $master_rs->create( { text_col => 'orig text', } );

    # schedule 3
    $m2->create_related( 'schedules', {
        date => DateTime->new( year => 2008, month => 7, day => 18 ),
        note => 'c',
    } );
}

{
    $form->process( {
            'text_col'               => 'new text',
            'count'                  => 1,
            'schedules_1.id'         => 3,
            'schedules_1.date_day'   => '19',
            'schedules_1.date_month' => '07',
            'schedules_1.date_year'  => '2008',
            'schedules_1.note'       => 'hi',
        } );

    ok( $form->submitted_and_valid );

    my $row = $schema->resultset('Master')->find(2);

    $form->model->update($row);
}

{
    my $user = $schema->resultset('Master')->find(2);

    is( $user->text_col, 'new text' );

    my @schedule = $user->schedules->all;

    is( scalar @schedule, 1 );

    is( $schedule[0]->id, 3 );

    my $date = $schedule[0]->date;

    isa_ok( $date, 'DateTime' );

    is( $date->year,  2008 );
    is( $date->month, 7 );
    is( $date->day,   19 );

    is( $schedule[0]->note, 'hi' );
}
