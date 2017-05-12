package Games::Lacuna::Task::Role::Building;

use 5.010;
our $VERSION = $Games::Lacuna::Task::VERSION;

use Moose::Role;

use Games::Lacuna::Task::Utils qw(parse_date);

sub check_upgrade_building {
    my ($self,$planet_stats,$building_data) = @_;
    
    my $building_object = $self->build_object($building_data);
    my $building_detail = $self->request(
        object  => $building_object,
        method  => 'view',
    );
    
    return 0
        unless $building_detail->{building}{upgrade}{can};
    
    # Check if we really can afford the upgrade
    return 0
        unless $self->can_afford($planet_stats,$building_detail->{'building'}{upgrade}{cost});
    
    # Check if upgraded building is sustainable
    {
        no warnings 'once';
        foreach my $resource (@Games::Lacuna::Task::Constants::RESOURCES) {
            my $resource_difference = -1 * ($building_detail->{'building'}{$resource.'_hour'} - $building_detail->{'building'}{upgrade}{production}{$resource.'_hour'});
            return 0
                if ($planet_stats->{$resource.'_hour'} + $resource_difference <= 0);
        }
    }
    
    return 1;
}

sub upgrade_building {
    my ($self,$planet_stats,$building_data) = @_;
    
    my $building_object = $self->build_object($building_data);
    
    $self->log('notice',"Upgrading %s on %s",$building_data->{'name'},$planet_stats->{name});
    
    # Upgrade request
    $self->request(
        object  => $building_object,
        method  => 'upgrade',
    );
    
    $self->clear_cache('body/'.$planet_stats->{id}.'/buildings');
    
    return 1;
}

sub find_buildspot {
    my ($self,$body) = @_;
    
    my $body_data = $self->my_body_status($body);
    
    return []
        unless $body_data;
    
    my @occupied;
    foreach my $building_data ($self->buildings_body($body_data)) {
        push (@occupied,$building_data->{x}.';'.$building_data->{y});
    }
    
    my @buildable;
    for my $x (-5..5) {
        for my $y (-5..5) {
            next
                if $x.';'.$y ~~ @occupied;
            push(@buildable,[$x,$y]);
        }
    }
    
    return \@buildable;
}

sub build_queue_size {
    my ($self,$body) = @_;
    
    my @buildings = $self->buildings_body($body);
    my $timestamp = time();
    
    my $building_count = 0;
    
    # Get build queue size
    foreach my $building_data (@buildings) {
        if (defined $building_data->{pending_build}) {
            my $date_end = parse_date($building_data->{pending_build}{end});
            $building_count ++
                if $timestamp < $date_end;
        }
    }
    
    return $building_count;
}

no Moose::Role;
1;

=encoding utf8

=head1 NAME

Games::Lacuna::Task::Role::Building - Helper methods for buildings

=head1 SYNOPSIS

 package Games::Lacuna::Task::Action::MyTask;
 use Moose;
 extends qw(Games::Lacuna::Task::Action);
 with qw(Games::Lacuna::Task::Role::Building);

=head1 DESCRIPTION

This role provides building-related helper methods.

=head1 METHODS

=head3 find_buildspot

 my $avaliable_buildspots = $self->find_buildspot($planet_id);

Returns all available build spots as an Array Reference.

=head3 upgrade_building

 my $upgrade_ok = $self->upgrade_building($planet_stats,$building_data);

Tries to upgrade the given building while performing various checks.

=head3 build_queue_size

 my $count = $self->build_queue_size($planet_stats);

Calculates the build queue size

=head3 check_upgrade_building

 my $is_upgradeable = $self->check_upgrade_building($planet_stats,$building_data);

Checks if a building is upgradeable

=cut