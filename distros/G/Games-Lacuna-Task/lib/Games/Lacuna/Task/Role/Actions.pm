package Games::Lacuna::Task::Role::Actions;

use 5.010;
our $VERSION = $Games::Lacuna::Task::VERSION;

use Moose::Role;

use Class::Load qw();
use Games::Lacuna::Task::Utils qw(class_to_name);

use Module::Pluggable 
    search_path => ['Games::Lacuna::Task::Action'],
    sub_name    => '_all_actions';

our @ALL_ACTIONS;

sub load_action {
    my ($self,$action_class) = @_;
    
    my $action_name = class_to_name($action_class);
    
    my ($ok,$error) = Class::Load::try_load_class($action_class);
       
    if (! $ok) {
        return (0,sprintf("Could not load task '%s': %s",$action_name,$error));
    }
    
    my $action_class_meta = $action_class->meta;
    if ($action_class_meta->can('deprecated')) {
        return (0,sprintf("Task '%s' is deprecated",$action_name));
    }
    
    return (1,undef);
}

sub all_actions {
    my ($self) = @_;
    
    return @ALL_ACTIONS
        if scalar @ALL_ACTIONS;
    
    @ALL_ACTIONS = _all_actions();
    return @ALL_ACTIONS;
}

1;