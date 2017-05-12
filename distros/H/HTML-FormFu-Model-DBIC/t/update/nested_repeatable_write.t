use strict;
use warnings;
use Test::More tests => 7;

use HTML::FormFu;
use lib 't/lib';
use DBICTestLib 'new_schema';
use MySchema;

my $form = HTML::FormFu->new;

$form->load_config_file('t/update/nested_repeatable_write.yml');

my $schema = new_schema();

my $master = $schema->resultset('Master')->create({ id => 1 });

# first sub-record
{
    # schedule 1
    my $u1 = $master->create_related( 'schedules', { note => 'some appointment',
                                                     date => '02-02-2009' } );

    # task 1
    $u1->create_related( 'tasks' => { detail => 'associated to do item' } );
}

# second sub-record
{
    # schedule 2
    my $u2 = $master->create_related( 'schedules', { note => 'some other appointment',
                                                     date => '03-03-2009' } );

    # task 2
    $u2->create_related( 'tasks', { detail => 'action item 1' } );

    # task 3
    $u2->create_related( 'tasks', { detail => 'action item 2' } );
}

{
    $form->process( {
            'sched_count'                 => 2,
            'schedules_2.id'              => 2,
            'schedules_2.note'            => 'new appointment',
            'schedules_2.count'           => 2,
            'schedules_2.tasks_1.id'      => 2,
            'schedules_2.tasks_1.detail'  => 'new action item 1',
            'schedules_2.tasks_2.id'      => 3,
            'schedules_2.tasks_2.detail'  => 'new action item 2',
        } );

    ok( $form->submitted_and_valid );

    my $row = $schema->resultset('Master')->find(1);

    $form->model->update($row);
}

{
    my $schedule = $schema->resultset('Schedule')->find(2);

    is( $schedule->note, 'new appointment' );

    my @add = $schedule->tasks->all;

    is( scalar @add, 2 );

    is( $add[0]->id,      2 );
    is( $add[0]->detail, 'new action item 1' );

    is( $add[1]->id,      3 );
    is( $add[1]->detail, 'new action item 2' );

}

