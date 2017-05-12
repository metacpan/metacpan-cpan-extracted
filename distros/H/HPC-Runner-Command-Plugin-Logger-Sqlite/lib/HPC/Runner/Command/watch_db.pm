package HPC::Runner::Command::watch_db;

use MooseX::App::Command;
use Data::Dumper;
use Log::Log4perl qw(:easy);

extends 'HPC::Runner::Command';
with 'HPC::Runner::Command::Plugin::Logger::Sqlite';

command_short_description 'Watch the sqlitedb and exit when job submissions are complete.';
command_long_description 'Watch the sqlitedb for one or more submission ids. This is only really useful for testing. In a real world application it is probably best to just have the scheduler email you on completion, unless you are submitting more jobs than you want emails.';

has 'total_processes' => (
    traits  => ['Number'],
    is      => 'rw',
    isa     => 'Num',
    default => 0,
    handles => {
        set_total_processes => 'set',
        add_total_processes => 'add',
    },
);

option 'exit_on_fail' => (
    traits  => ['Bool'],
    is      => 'rw',
    isa     => 'Bool',
    default => 0,
    documentation => 'Fail if any jobs have an exit code besides 0 - whether all tasks have completed or not',
);

option 'sleep_interval' => (
    is => 'rw',
    isa => 'Int',
    default => 10,
    documentation => 'Sleep interval in seconds to query sqlite db. For software testing you should leave as is. For longer running analyses you probably want to increase this.',
);

option 'verbose' => (
    traits  => ['Bool'],
    is      => 'rw',
    isa     => 'Bool',
    default => 0,
    documentation => 'Enable verbose logging',
);

sub execute {
    my $self = shift;

    if($self->submission_id){
        $self->app_log->info("Watching Submission Id : " . $self->submission_id);
    }
    else{
        $self->app_log->info("No submission id specified. We will watch the whole database");
    }

    my $results = $self->query_submissions;
    $self->total_tasks($results);

    while (1){

        if($self->verbose){
            $self->app_log->debug("Watching again...");
        }

        my $results = $self->query_submissions;

        my $jobs  = $results->search_related('jobs');
        my $tasks = $jobs->search_related('tasks');

        $self->query_task($tasks);

        sleep ($self->sleep_interval);
    }
}

sub query_task {
    my $self    = shift;
    my $task_rs = shift;

    if($self->verbose){
        $self->app_log->debug("Tasks in DB are ".$task_rs->count);
    }

    #If exit on fail we don't care if we have completed the number of processes - just fail
    if ($self->exit_on_fail){
        $self->check_exit_code($task_rs);
    }

    if ($task_rs->count != $self->total_processes){
        #We have
        return;
    }
    elsif($task_rs->count == $self->total_processes){
        $self->app_log->info("We have completed ".$self->total_processes." tasks. Exiting successfully");
        exit 0;
    }
    elsif($task_rs->count >= $self->total_processes){
        $self->app_log->info("More tasks were completed than were in the databases ".$self->total_processes." tasks.");
        $self->app_log->info("Were jobs restarted manually?");
        $self->app_log->info("Exiting successfully");
        exit 0;
    }
    else{
        $self->app_log->debug("Not sure how we got here...");
    }

}

sub check_exit_code {
    my $self = shift;
    my $task_rs = shift;

    my $exit_codes = $task_rs->get_column('exit_code');

    while ( my $res = $task_rs->next ) {
        if ($res->exit_code != 0){
            $self->app_log->error("A task has failed! ".$res->task_pi);
            exit 1;
        }
    }
}

sub total_tasks {
    my $self = shift;
    my $results = shift;

    while ( my $res = $results->next ) {
        $self->add_total_processes( $res->total_processes );
    }
}

sub query_submissions {
    my $self = shift;

    my $results;

    if($self->project){
        $results = $self->schema->resultset('Submission')
            ->search( { 'project' => $self->project } );
    }
    elsif ($self->submission_id){
        $results = $self->schema->resultset('Submission')
            ->search( { 'submission_pi' => $self->submission_id } );
    }
    else{
        $results = $self->schema->resultset('Submission')
            ->search();
    }

    return $results;


}

#TODO To keep or not to keep?

sub query_job {
    my $self   = shift;
    my $job_rs = shift;

    #$job_rs->result_class('DBIx::Class::ResultClass::HashRefInflator');
    #while ( my $res = $job_rs->next ) {
        #print Dumper($res);
    #}
}

# sub query_related {
#     my $self = shift;
#
#     #$ENV{DBIC_TRACE} = 1;
#
#     print "In query related\n";
#     $self->schema->storage->debug(1);
#
#     my $results = $self->schema->resultset('Submission')
#         ->search( {}, { 'prefetch' => { jobs => 'tasks' } } );
#
#     $results->result_class('DBIx::Class::ResultClass::HashRefInflator');
#
#     while ( my $res = $results->next ) {
#         print "Here is a result!\n";
#         print Dumper($res);
#     }
#
# }

1;
