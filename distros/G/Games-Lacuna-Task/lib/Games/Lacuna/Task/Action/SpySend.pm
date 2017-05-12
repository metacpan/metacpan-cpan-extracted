package Games::Lacuna::Task::Action::SpySend;

use 5.010;
our $VERSION = $Games::Lacuna::Task::VERSION;

use Moose -traits => 'NoAutomatic';
extends qw(Games::Lacuna::Task::Action);
with 'Games::Lacuna::Task::Role::Stars',
    'Games::Lacuna::Task::Role::CommonAttributes' => { attributes => ['target_planet','home_planet'] };

has 'spy_name' => (
    isa         => 'Str',
    is          => 'ro',
    predicate   => 'has_spy_name',
    documentation=> q[Name of spy to be sent],
);

has 'spy_count' => (
    isa         => 'Int',
    is          => 'ro',
    required    => 1,
    default     => 1,
    documentation=> 'Number of spies to be sent [Default: 1]',
);

has 'best_spy' => (
    isa         => 'Bool',
    is          => 'ro',
    required    => 1,
    default     => 1,
    documentation=> 'Send best available spy [Default: true]',
);

sub description {
    return q[Send spies to another planet];
}

sub run {
    my ($self) = @_;
    my $planet_home = $self->home_planet_data();
    my $planet_target = $self->target_planet_data();
    
    # Get spaceport
    my ($spaceport) = $self->find_building($planet_home->{id},'Spaceport');
    return $self->log('error','Could not find spaceport')
        unless (defined $spaceport);
    my $spaceport_object = $self->build_object($spaceport);

    my $sendable_spies = $self->request(
        object      => $spaceport_object,
        method      => 'prepare_send_spies',
        params      => [$planet_home->{id},$planet_target->{id}],
    );
    
    unless (scalar @{$sendable_spies->{spies}}) {
        $self->log('err','No spies available to send');
        return;
    }
    
    my @spies;
    if ($self->best_spy) {
        @spies = sort { $b->{offense_rating} <=> $a->{offense_rating} } @{$sendable_spies->{spies}};
    } else {
        @spies = sort { $a->{offense_rating} <=> $b->{offense_rating} } @{$sendable_spies->{spies}};
    }
    
    my @send_spies;
    foreach my $spy (@spies) {
        next 
            if $self->has_spy_name && $spy->{name} !~ m/$spy->name/;
        next 
            if $spy->{name} =~ m/!/;
        push(@send_spies,$spy);
        last
            if scalar @send_spies >= $self->spy_count;
    }
    
    return $self->log('error','Could not find spies to send')
        unless (scalar @send_spies);
    
    my ($send_ship) = sort { $b->{stealth} <=> $a->{stealth} } @{$sendable_spies->{ships}};
    
    return $self->log('error','Could not find ship to send')
        unless ($send_ship);
    
    $self->request(
        object      => $spaceport_object,
        method      => 'send_spies',
        params      => [$planet_home->{id},$planet_target->{id},$send_ship->{id},\@send_spies],
    );
    
    $self->log('notice','Sent %i spies with %s to %s',scalar(@send_spies),$send_ship->{name},$planet_target->{name});
}

__PACKAGE__->meta->make_immutable;
no Moose;
1;