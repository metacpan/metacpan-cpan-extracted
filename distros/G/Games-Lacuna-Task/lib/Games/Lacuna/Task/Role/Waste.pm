package Games::Lacuna::Task::Role::Waste;

use 5.010;
our $VERSION = $Games::Lacuna::Task::VERSION;

use Moose::Role;

use List::Util qw(max sum min);

our %STORAGE_BUILDINGS = (
    ore     => 'OreStorage',
    food    => 'FoodReserve',
    water   => 'WaterStorage',
    energy  => 'EnergyReserve',
);

sub disposeable_waste {
    my ($self,$planet_stats) = @_;
    
    my $recycleable_waste = 0;
    my $keep_waste_hours = 24;
    $keep_waste_hours = $self->keep_waste_hours
        if $self->can('keep_waste_hours');
    
    # Get recycleable waste
    if ($planet_stats->{waste_hour} > 0) {
        $recycleable_waste = $planet_stats->{waste_stored};
    } else {
        $recycleable_waste = $planet_stats->{waste_stored} + ($planet_stats->{waste_hour} * $keep_waste_hours)
    }
    
    return max($recycleable_waste,0);
}

sub convert_waste {
    my ($self,$planet_stats,$quantity) = @_;
    
    my @resources_ordered = sort { $planet_stats->{$b.'_stored'} <=> $planet_stats->{$a.'_stored'} } 
        @Games::Lacuna::Task::Constants::RESOURCES;
    
#    my $resources_total = sum map { $planet_stats->{$_.'_stored'} } @resource_types;
#    my $resources_avg = $resources_total / scalar @resource_types;
    
    RESOURCE_TYPE:
    foreach my $resource_type (@resources_ordered) {
        my $resource_dump = $quantity;
        my $resources_stored = $planet_stats->{$resource_type.'_stored'} * 0.9;
        
        my $storage_builiding = $self->find_building($planet_stats->{id},$STORAGE_BUILDINGS{$resource_type});
        my $storage_builiding_object = $self->build_object($storage_builiding);
        
        my ($resource_subtype,@dump_params);
        
        if ($resource_type ~~ [qw(food ore)]) {
            my $response = $self->request(
                object  => $storage_builiding_object,
                method  => 'view',
            );
            
            my $resources_sub_stored = $response->{$resource_type.'_stored'};
            
            ($resource_subtype) = 
                sort { $resources_sub_stored->{$b} <=> $resources_sub_stored->{$a} }
                keys %{$resources_sub_stored};
            
            $resource_dump = min($resources_sub_stored->{$resource_subtype},$resource_dump);
            
            push(@dump_params,$resource_subtype);
            
            $self->log('notice','Dumping %i %s on %s',$quantity,$resource_subtype,$planet_stats->{name});
        } else {
            $resource_dump = min($resources_stored,$resource_dump);
            
            $self->log('notice','Dumping %i %s on %s',$quantity,$resource_type,$planet_stats->{name});
        }
        
        push(@dump_params,$resource_dump);
        
        $self->request(
            object  => $storage_builiding_object,
            method  => 'dump',
            params  => \@dump_params,
        );
        
        $quantity -= $resource_dump;
        
        last RESOURCE_TYPE
            if $quantity <= 0;
    }
}

no Moose::Role;
1;

=encoding utf8

=head1 NAME

Games::Lacuna::Task::Role::Waste - Waste helper methods

=head1 SYNOPSIS

    package Games::Lacuna::Task::Action::MyTask;
    use Moose;
    extends qw(Games::Lacuna::Task::Action);
    with qw(Games::Lacuna::Task::Role::Waste);

=head1 DESCRIPTION

This role provides helper method to work with waste diposal

=head1 METHODS

=head2 disposeable_waste

 my $quantity = $self->disposeable_waste($planet_stats);

Returns the amout of waste that is available for disposal

=head2 convert_waste

 $self->convert_waste($planet_stats,$quantity);

Produces the requested amout of waste by dumping resources from storage

=cut