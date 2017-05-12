package Games::Lacuna::TaskRunner;

use 5.010;
our $VERSION = $Games::Lacuna::Task::VERSION;

use Moose;
extends qw(Games::Lacuna::Task);
with qw(MooseX::Getopt);

use Games::Lacuna::Task::Utils qw(class_to_name name_to_class);
use Try::Tiny;

has 'exclude'  => (
    is              => 'rw',
    isa             => 'ArrayRef[Str]',
    documentation   => 'Select which tasks NOT to run [Multiple]',
    predicate       => 'has_exclude',
);

has 'task'  => (
    is              => 'rw',
    isa             => 'ArrayRef[Str]',
    documentation   => 'Select which tasks to run [Multiple, Default all]',
    traits          => ['Array'],
    default         => sub { [] },
    handles         => {
        has_task        => 'count',
    },
);

has '+configdir' => (
    required        => 1,
);

sub run {
    my ($self) = @_;
    
    my $client = $self->client();
    
    # Call lazy builder
    $client->client;
    
    my $empire_name = $self->empire_name;
    
    $self->log('notice',("=" x ($Games::Lacuna::Task::Constants::SCREEN_WIDTH - 8)));
    $self->log('notice',"Running tasks for empire %s",$empire_name);
    
    my $global_config = $client->config->{global};
    
    $self->task($global_config->{task})
        if (defined $global_config->{task}
        && ! $self->has_task);
    $self->exclude($global_config->{exclude})
        if (defined $global_config->{exclude}
        && ! $self->has_exclude);
    
    my (@tasks,@tmp_tasks);
    if (! $self->has_task
        || 'all' ~~ $self->task) {
        @tmp_tasks = $self->all_actions;
    } else {
        foreach my $action_class ($self->all_actions) {
            my $action_name = class_to_name($action_class);
            push(@tmp_tasks,$action_class)
                if $action_name ~~ $self->task;
        }
    }
    
    foreach my $task_class (@tmp_tasks) {
        my ($ok,$error) = $self->load_action($task_class);
        push(@tasks,$task_class)
            if ($ok);   
    }
    
    # Loop all tasks
    TASK:
    foreach my $task_class (@tasks) {
        my $task_name = class_to_name($task_class);
        
        next
            if $self->has_exclude && $task_name ~~ $self->exclude;
        
        next
            if $task_class->meta->can('no_automatic')
            && $task_class->meta->no_automatic;
        
        $self->log('notice',("-" x ($Games::Lacuna::Task::Constants::SCREEN_WIDTH - 8)));
        $self->log('notice',"Running action %s",$task_name);
        try {
            my $task_config = $client->task_config($task_name);
            my $task = $task_class->new(
                %{$task_config}
            );
            $task->execute;
        } catch {
            $self->log('error',"An error occured while processing %s: %s",$task_class,$_);
        }
    }
    $self->log('notice',("=" x ($Games::Lacuna::Task::Constants::SCREEN_WIDTH - 8)));
}

__PACKAGE__->meta->make_immutable;
no Moose;
1;