package Games::Lacuna::Task::Action::Mission;

use 5.010;
our $VERSION = $Games::Lacuna::Task::VERSION;

use Moose;
extends qw(Games::Lacuna::Task::Action);
with qw(Games::Lacuna::Task::Role::PlanetRun
    Games::Lacuna::Task::Role::Storage);

sub description {
    return q[Automatically accept missions];
}

has 'missions' => (
    is              => 'rw',
    isa             => 'ArrayRef[Str]',
    required        => 1,
    documentation   => 'Automatic missions [Required, Multiple]',
);

sub process_planet {
    my ($self,$planet_stats) = @_;
    
    my $timestamp = time();
    
    # Get mission command
    my $missioncommand = $self->find_building($planet_stats->{id},'MissionCommand');
    return
        unless $missioncommand;
    my $missioncommand_object = $self->build_object($missioncommand);
    
    my $mission_data = $self->request(
        object  => $missioncommand_object,
        method  => 'get_missions',
    );
    
    my $plans;
    my $glyphs;
    
    MISSIONS:
    foreach my $mission (@{$mission_data->{missions}}) {
        next MISSIONS
            unless $mission->{name} ~~ $self->missions;
        
        my $objectives = $self->parse_mission($mission->{objectives});
        
        # Check if we have the required resources
        my @used_plans;
        foreach my $objective (@{$objectives}) {
            given ($objective->{type}) {
                when ('plan') {
                    $plans ||= $self->plans_stored($planet_stats->{id});
                    my $found_plan = 0;
                    PLANS:
                    foreach my $plan (@$plans) {
                        next PLANS
                            unless $plan->{name} eq $objective->{plan};
                        next PLANS
                            if $plan->{level} != $objective->{level};
                        next PLANS
                            if $plan->{extra_build_level} != $objective->{extra_build_level};
                        next PLANS
                            if grep { $plan == $_ } @used_plans;
                        push (@used_plans,$plan);
                        $found_plan ++;
                        last PLANS;
                    }
                    next MISSIONS
                        unless $found_plan;
                }
                when ('resource') {
                    next MISSIONS
                        if $objective->{quantity} > $self->check_stored($planet_stats,$objective->{resource});
                }
            }
        }
        
        my $rewards = $self->parse_mission($mission->{rewards});
        
        my %rewards_resources = map { $_ => 0 } @Games::Lacuna::Task::Constants::RESOURCES;
        # Check if we have can handle the reward
        foreach my $reward (@{$rewards}) {
            if ($reward->{type} eq 'resource') {
                my $resource_type = $self->resource_type($reward->{resource});
                $rewards_resources{$resource_type} += $reward->{quantity};
            }
        }
        
        foreach my $resource_type (@Games::Lacuna::Task::Constants::RESOURCES) {
            my $capacity = $planet_stats->{$resource_type.'_capacity'} - $planet_stats->{$resource_type.'_stored'} - $rewards_resources{$resource_type};
            next MISSIONS
                if $capacity < -100000;
        }
        
        $self->log('notice',"Completing mission %s on %s",$mission->{name},$planet_stats->{name});
        
        my $response = $self->request(
            object      => $missioncommand_object,
            method      => 'complete_mission',
            params      => [$mission->{id}],
            catch       => [
                [
                    1013,
                    sub {
                        my ($error) = @_;
                        $self->log('debug',"Could not complete mission %s: %s",$mission->{name},$error->message);
                        next MISSION;
                    }
                ]
            ],
            
        );
        $planet_stats = $response->{status}{body};
            
        my $body = sprintf("We have completed the mission *%s* on {Planet %i %s}\nObjective: %s\nReward:%s",
            $mission->{name},
            $planet_stats->{id},
            $planet_stats->{name},
            join (", ",@{$mission->{objectives}}),
            join (", ",@{$mission->{rewards}}),
        );
            
        $self->send_message('Mission completed',$body);
    }
}

sub parse_mission {
    my ($self,$list) = @_;
    
    my @parsed;
    
    foreach my $element (@{$list}) {
        given ($element) {
            when (m/^
                (?<plan>[^(]+)
                \s
                \(
                    (>=\s)?
                    (?<level>\d+)
                    (\+(?<extra_build_level>\d+))?
                \)
                \s
                plan$/x) {
                
                push(@parsed,{
                    type                => 'plan',
                    level               => $+{level},
                    plan                => $+{plan},
                    extra_build_level   => ($+{extra_build_level} // 0)
                });
            }
            when (m/^(?<quantity>[,0-9]+)\s(?<resource>.+)$/) {
                my $quantity = $+{quantity};
                my $resource = $+{resource};
                $quantity =~ s/\D//g;
                $quantity += 0;
                push(@parsed,{
                    type                => 'resource',
                    resource            => $resource,
                    quantity            => $quantity,
                });
            }
            when (m/^(?<glyph>.+)\sglyph$/) {
                push(@parsed,{
                    type                => 'glyph',
                    glyph               => $+{glyph},
                });
            }
            when (m/^
                (?<ship>[^(]+)
                \s
                \(
                    speed \s >= \s (?<speed>[0-9,]+),
                    \s
                    stealth \s >= \s (?<stealth>[0-9,]+),
                    \s
                    hold \s size \s >= \s (?<hold>[0-9,]+),
                    \s
                    combat \s >= \s (?<combat>[0-9,]+)
                \)
                $/x) {
                my $ship = $+{ship};
                my $speed = $+{speed};
                my $hold = $+{hold};
                my $stealth = $+{stealth};
                my $combat = $+{combat};
                $speed =~ s/\D//g;
                $hold =~ s/\D//g;
                $stealth =~ s/\D//g;
                $combat =~ s/\D//g;
                push(@parsed,{
                    type                => 'ship',
                    ship                => $ship,
                    stealth             => $stealth,
                    hold                => $hold,
                    combat              => $combat,
                    speed               => $speed,
                });
            }
            when (m/^Send 
                \s 
                (?<ship>.+?) 
                \s to \s 
                (?<planet>.+?) 
                \s 
                \(
                (?<x>-?\d+)
                ,
                (?<y>-?\d+)
                \)/x) {
                push(@parsed,{
                    type                => 'send',
                    ship                => $+{ship},
                    planet              => $+{planet},
                    x                   => $+{x},
                    y                   => $+{y},
                });
            }
            default {
                $self->log("warn","Unknown mission item: %s",$_);
            }
        }
    }
    
    return \@parsed;
}

__PACKAGE__->meta->make_immutable;
no Moose;
1;