package Games::Lacuna::Task::Report::Intelligence;

use 5.010;
our $VERSION = $Games::Lacuna::Task::VERSION;

use Moose::Role;
with qw(Games::Lacuna::Task::Role::Intelligence
    Games::Lacuna::Task::Role::Stars);

use Games::Lacuna::Task::Utils qw(parse_date);

sub report_intelligence {
    my ($self) = @_;
    
    my $table = Games::Lacuna::Task::Table->new(
        headline=> 'Intelligence Report',
        columns => ['Planet','Defensive spies','Offensive spies','Idle spies','Foreign spies','Foreign active spies'],
    );
    
    foreach my $planet_id ($self->my_planets) {
       $self->_report_intelligence_body($planet_id,$table);
    }
    
    return $table;
}

sub _report_intelligence_body {
    my ($self,$planet_id,$table) = @_;
    
    my $timestamp = time();
    my $planet_stats = $self->my_body_status($planet_id);
    
    # Get security & intelligence ministry
    my ($security_ministry) = $self->find_building($planet_stats->{id},'Security');
    my ($intelligence_ministry) = $self->find_building($planet_stats->{id},'Intelligence');
    
    return
        unless $security_ministry && $intelligence_ministry;
    
    my @foreign_spies_active;
    my @foreign_spies;
    
    my $security_ministry_object = $self->build_object($security_ministry);
    my $intelligence_ministry_object = $self->build_object($intelligence_ministry);
    
    my $foreign_spy_data = $self->paged_request(
        object  => $security_ministry_object,
        method  => 'view_foreign_spies',
        total   => 'spy_count',
        data    => 'spies',
    );
    
    # Check if we have active foreign spies (not idle) that can be discovered via security sweep
    if ($foreign_spy_data->{spy_count} > 0) {
        @foreign_spies = @{$foreign_spy_data->{spies}};
        foreach my $spy (@{$foreign_spy_data->{spies}}) {
            my $next_mission = parse_date($spy->{next_mission});
            if ($next_mission > $timestamp) {
                push(@foreign_spies_active,$spy)
            }
        }
    }
    
    my $my_spy_data = $self->request(
        object  => $intelligence_ministry_object,
        method  => 'view_spies',
    );
    
    my $defensive_spies = 0;
    my $offensive_spies = 0;
    my $idle_spies = 0;
    foreach my $spy (@{$my_spy_data->{spies}}) {
        if ($spy->{assignment} eq 'Idle') {
            $idle_spies ++;
        }
        my $assigned_type = $self->assigned_to_type($spy->{assigned_to});
        if ($assigned_type ~~ [qw(own ally)]) {
            $defensive_spies ++
        } else {
            $offensive_spies ++;
        }
    }
    
    $table->add_row({
        planet          => $planet_stats->{name},
        defensive_spies => $defensive_spies,
        offensive_spies => $offensive_spies,
        idle_spies      => $idle_spies,
        foreign_spies   => scalar(@foreign_spies),
        foreign_active_spies    => scalar(@foreign_spies_active),
    });
}

no Moose::Role;
1;