package Games::Lacuna::Task::Action::WasteProduction;

use 5.010;
our $VERSION = $Games::Lacuna::Task::VERSION;

use Moose;
extends qw(Games::Lacuna::Task::Action);
with 'Games::Lacuna::Task::Role::Waste',
    'Games::Lacuna::Task::Role::PlanetRun',
    'Games::Lacuna::Task::Role::CommonAttributes' => { attributes => ['plan_for_hours'] };

use List::Util qw(min);

sub description {
    return q[Maintain minimum waste levels for waste recycling buildings];
}

sub process_planet {
    my ($self,$planet_stats) = @_;
    
    # Get stored waste
    my $waste_stored = $planet_stats->{waste_stored};
    my $waste_hour = $planet_stats->{waste_hour};
    my $waste_empty = $waste_stored + ($self->plan_for_hours * $waste_hour);
    my $waste_capacity = int($planet_stats->{waste_capacity} * 0.9 - $waste_stored);
    
    return 
        if $waste_hour > 0;
        
    return
        if $waste_empty > 0;
    
    my $waste_dump = int($waste_empty * -1.1);
    $waste_dump = min($waste_dump,$waste_capacity);
    
    $self->convert_waste($planet_stats,$waste_dump);
}

__PACKAGE__->meta->make_immutable;
no Moose;
1;