package Games::Lacuna::Task::Action::VrbanskBuild;

use 5.010;
our $VERSION = $Games::Lacuna::Task::VERSION;

use Moose -traits => 'NoAutomatic';
extends qw(Games::Lacuna::Task::Action);
with 'Games::Lacuna::Task::Role::Building',
    'Games::Lacuna::Task::Role::CommonAttributes' => { attributes => ['home_planet'] };

use List::Util qw(min);

has 'count' => (
    isa         => 'Int',
    is          => 'ro',
    required    => 1,
    default     => 1,
    documentation=> "Number of halls to be build [Default: 1]",
);

sub description {
    return q[Build halls of vrbansk on a given planet];
}

sub run {
    my ($self) = @_;
    
    my $planet_home = $self->home_planet_data();
    
    # Get pcc
    my $planetarycommand = $self->find_building($planet_home->{id},'PlanetaryCommand');
    return 
        unless $planetarycommand;
    
    my $planetarycommand_object = $self->build_object($planetarycommand);
    
    # Get plans
    my $plan_data = $self->request(
        object  => $planetarycommand_object,
        method  => 'view_plans',
    );
    
    my @halls;
    foreach my $plan (@{$plan_data->{plans}}) {
        next
            unless $plan->{name} eq 'Halls of Vrbansk';
        next
            if $plan->{extra_build_level} != 0;
        push(@halls,$plan_data->{id});
        last
            if scalar @halls >= $self->count;
    }
    
    return $self->log('error','Could not find plans for Hall of Vrbansk')
        if scalar(@halls) == 0;

    my $buildable_spots = $self->find_buildspot($planet_home);
    
    return $self->log('error','Could not find build spots')
        if scalar @{$buildable_spots} == 0;
    
    my $continue = 1;
    HALL:
    while ($continue && scalar @halls && scalar @{$buildable_spots}) {
        my $builspot = pop(@{$buildable_spots});
        my $vrbansk = pop(@halls);
        
        my $new_vrbansk_object = $self->build_object('/hallsofvrbansk', body_id => $planet_home->{id});
        
        $self->log('notice',"Building Hall of Vrbansk on %s",$planet_home->{name});
        
        $self->request(
            object  => $new_vrbansk_object,
            method  => 'build',
            params  => [ $planet_home->{id}, $builspot->[0],$builspot->[1]],
            catch   => [
               [
                    1009,
                    qr/That space is already occupied/,
                    sub {
                        $self->log('debug',"Could not build Hall of Vrbansk on %s: Build spot occupied",$planet_home->{name});
                        push(@halls,$vrbansk);
                        return 0;
                    }
                ],
                [
                    1009,
                    qr/There's no room left in the build queue/,
                    sub {
                        $self->log('debug',"Could not build Hall of Vrbansk on %s: Build queue full",$planet_home->{name});
                        $continue = 0;
                        return 0;
                    }
                ],
            ],
        );
    }
    
    $self->clear_cache('body/'.$planet_home->{id}.'/buildings');
}

__PACKAGE__->meta->make_immutable;
no Moose;
1;