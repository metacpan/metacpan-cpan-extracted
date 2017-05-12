package Games::Lacuna::Task::Action::CounterIntelligence;

use 5.010;
our $VERSION = $Games::Lacuna::Task::VERSION;

use Moose;
extends qw(Games::Lacuna::Task::Action);
with qw(Games::Lacuna::Task::Role::PlanetRun
    Games::Lacuna::Task::Role::Stars
    Games::Lacuna::Task::Role::Intelligence);

use List::Util qw(min);
use Games::Lacuna::Task::Utils qw(parse_date);

sub description {
    return q[Manage counter intelligence activities (not working due to captcha)];
}

sub process_planet {
    my ($self,$planet_stats) = @_;
    
    my $timestamp = time();
    
    # Get intelligence ministry
    my ($intelligence_ministry) = $self->find_building($planet_stats->{id},'Intelligence');
    return
        unless $intelligence_ministry;
    
    my $intelligence_ministry_object = $self->build_object($intelligence_ministry);
    
    # Get security ministry
    my ($security_ministry) = $self->find_building($planet_stats->{id},'Security');
    my @foreign_spies_active;
    my $foreign_spies_count = 0;
    if ($security_ministry) {
        my $security_ministry_object = $self->build_object($security_ministry);
        
        my $foreign_spy_data = $self->paged_request(
            object  => $security_ministry_object,
            method  => 'view_foreign_spies',
            total   => 'spy_count',
            data    => 'spies',
        );
        
        $foreign_spies_count = $foreign_spy_data->{spy_count};
        
        # Check if we have active foreign spies (not idle) that can be discovered via security sweep
        if ($foreign_spy_data->{spy_count} > 0) {
            $self->log('warn',"There are %i foreign spies on %s",$foreign_spy_data->{spy_count},$planet_stats->{name});
            foreach my $spy (@{$foreign_spy_data->{spies}}) {
                my $next_mission = parse_date($spy->{next_mission});
                if ($next_mission > $timestamp) {
                    $self->log('warn',"%s (%i) on %s is active and vulnerable to a security sweep",$spy->{name},$spy->{level},$planet_stats->{name});
                    push(@foreign_spies_active,$spy->{level})
                }
            }
        }
    }
    
    my $spy_data = $self->paged_request(
        object  => $intelligence_ministry_object,
        method  => 'view_spies',
        total   => 'spy_count',
        data    => 'spies',
    );
    
    # Loop all spies
    my $defensive_spy_count = 0;
    my %defensive_spy_assignments;
    foreach my $spy (@{$spy_data->{spies}}) {
        # Spy is on this planet
        if ($spy->{assigned_to}{body_id} == $planet_stats->{id}) {
            $defensive_spy_assignments{$spy->{assignment}} ||= [];
            push(@{$defensive_spy_assignments{$spy->{assignment}}},$spy);
            $defensive_spy_count ++;
        # Spy is on another planet
        } else {
            next
                unless $spy->{is_available};
            next
                unless $spy->{assignment} eq 'Idle';
            
            my $assigned_to_type = $self->assigned_to_type($spy->{assigned_to});
            
            if ($assigned_to_type ~~ [qw(ally own)]) {
                $self->log('notice',"Assigning defensive spy %s on %s to counter espionage",$spy->{name},$spy->{assigned_to}{name});
                my $response = $self->request(
                    object  => $intelligence_ministry_object,
                    method  => 'assign_spy',
                    params  => [$spy->{id},'Counter Espionage'],
                );
            } else {
                $self->log('notice',"Offensive spy %s on %s is currently idle",$spy->{name},$spy->{assigned_to}{name});
            }
        }
    }
    
    # Assign local spies
    foreach my $spy (@{$spy_data->{spies}}) {
        next
            unless $spy->{is_available};
        next
            unless $spy->{assigned_to}{body_id} == $planet_stats->{id};
        
        my $assignment;
        
        # Run security sweep
        if (scalar @foreign_spies_active
            && ! defined $defensive_spy_assignments{'Security Sweep'}
            && min(@foreign_spies_active)-1 <= $spy->{level} 
            && $defensive_spy_count > $foreign_spies_count) {
            $assignment = 'Security Sweep';
        # Assign to counter espionage
        } elsif ($spy->{assignment} eq 'Idle') {
            $assignment = 'Counter Espionage';
        }
        
        # Set new assignment
        if ($assignment) {
            $defensive_spy_assignments{$assignment} ||= [];
            push(@{$defensive_spy_assignments{$assignment}},$spy);
            $self->log('notice',"Assigning defensive spy %s on %s to %s",$spy->{name},$planet_stats->{name},$assignment);
            $self->request(
                object  => $intelligence_ministry_object,
                method  => 'assign_spy',
                params  => [$spy->{id},$assignment],
            );
        }
    }
}

__PACKAGE__->meta->make_immutable;
no Moose;
1;