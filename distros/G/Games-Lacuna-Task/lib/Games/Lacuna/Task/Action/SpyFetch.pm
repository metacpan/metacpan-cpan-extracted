package Games::Lacuna::Task::Action::SpyFetch;

use 5.010;
our $VERSION = $Games::Lacuna::Task::VERSION;

use Moose -traits => 'NoAutomatic';
extends qw(Games::Lacuna::Task::Action);
with 'Games::Lacuna::Task::Role::Stars',
    'Games::Lacuna::Task::Role::CommonAttributes' => { attributes => ['target_planet','home_planet'] };

has 'spy_count' => (
    isa         => 'Int',
    is          => 'ro',
    predicate   => 'has_spy_count',
    documentation=> 'Number of spies to be fetched',
);

sub description {
    return q[Fetch spies from enemy planets];
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

    my $fetchable_spies = $self->request(
        object      => $spaceport_object,
        method      => 'prepare_fetch_spies',
        params      => [$planet_target->{id},$planet_home->{id}],
    );
    
    unless (scalar @{$fetchable_spies->{spies}}) {
        $self->log('err','No spies available to fetch');
        return;
    }
    
    my ($send_ship) = sort { $b->{stealth} <=> $a->{stealth} } @{$fetchable_spies->{ships}};
    
    return $self->log('error','Could not find ship to send')
        unless ($send_ship);
    
    my @fetch_spies;
    foreach my $spy (@{$fetchable_spies->{spies}}) {
        push(@fetch_spies,$spy);
        last
            if $self->has_spy_count && scalar @fetch_spies >= $self->spy_count;
    }
    
    $self->request(
        object      => $spaceport_object,
        method      => 'fetch_spies',
        params      => [$planet_target->{id},$planet_home->{id},$send_ship->{id},\@fetch_spies],
    );
    
    $self->log('notice','Fetched %i spies with %s from %s',scalar(@fetch_spies),$send_ship->{name},$planet_target->{name});
}

__PACKAGE__->meta->make_immutable;
no Moose;
1;