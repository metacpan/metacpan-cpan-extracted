package Tamagotchi;
use Mo qw(default build);

use FindBin;
use lib "$FindBin::Bin/../../lib";
use EventStore::Tiny;

has _event_store => EventStore::Tiny->new;

sub data {shift->_event_store->snapshot->state}
sub _register_event {shift->_event_store->register_event(@_)}
sub _store_event {shift->_event_store->store_event(@_)}

sub BUILD {
    my $self = shift;

    # prepare all possible event templates
    $self->_register_events;
}

sub _register_events {
    my $self = shift;

    # user events
    $self->_register_event(UserAdded => sub {
        my ($state, $data) = @_;
        $state->{users}{$data->{user_id}} = {
            id      => $data->{user_id},
            name    => $data->{user_name},
        };
    });
    $self->_register_event(UserRenamed => sub {
        my ($state, $data) = @_;
        $state->{users}{$data->{user_id}}{name} = $data->{user_name};
    });
    $self->_event_store->register_event(UserRemoved => sub {
        my ($state, $data) = @_;
        delete $state->{users}{$data->{user_id}};
    });

    # tamagotchi events
    $self->_register_event(TamagotchiAdded => sub {
        my ($state, $data) = @_;
        $state->{tamas}{$data->{tama_id}} = {
            id      => $data->{tama_id},
            user_id => $data->{user_id},
            health  => 100,
        };
    });
    $self->_register_event(TamagotchiFed => sub {
        my ($state, $data) = @_;
        my $tama = $state->{tamas}{$data->{tama_id}};
        $tama->{health} += 20;
        $tama->{health} = 100 if $tama->{health} > 100;
    });
    $self->_register_event(TamagotchiDayPassed => sub {
        my ($state, $data) = @_;
        my $tama = $state->{tamas}{$data->{tama_id}};
        $tama->{health} -= 30;
    });
    $self->_register_event(TamagotchiDied => sub {
        my ($state, $data) = @_;
        delete $state->{tamas}{$data->{tama_id}};
    });
}

sub add_user {
    my ($self, $name) = @_;

    # find free user id
    my $user_id = 0;
    $user_id++ while exists $self->data->{users}{$user_id};

    # ok, store event
    $self->_store_event(UserAdded => {
        user_id     => $user_id,
        user_name   => $name,
    });

    # tell them how to address the user
    return $user_id;
}

sub rename_user {
    my ($self, $user_id, $name) = @_;

    # try to find user
    die "Unknown user: $user_id\n"
        unless exists $self->data->{users}{$user_id};

    # ok, store rename event
    $self->_store_event(UserRenamed => {
        user_id     => $user_id,
        user_name   => $name,
    });
}

sub remove_user {
    my ($self, $user_id) = @_;

    # try to find user
    die "Unknown user: $user_id\n"
        unless exists $self->data->{users}{$user_id};

    # ok, store removal event
    $self->_store_event(UserRemoved => {user_id => $user_id});
}

sub add_tamagotchi {
    my ($self, $user_id) = @_;

    # try to find user
    die "Unknown user: $user_id\n"
        unless exists $self->data->{users}{$user_id};

    # find free tamagotchi id
    my $tama_id = 0;
    $tama_id++ while exists $self->data->{tamas}{$tama_id};

    # ok, store event
    $self->_store_event(TamagotchiAdded => {
        user_id => $user_id,
        tama_id => $tama_id,
    });

    # tell them how to address the tamagotchi
    return $tama_id;
}

sub feed_tamagotchi {
    my ($self, $tama_id) = @_;

    # try to find tamagotchi
    die "Unknown tamagotchi: $tama_id\n"
        unless exists $self->data->{tamas}{$tama_id};

    # ok, feed it
    $self->_store_event(TamagotchiFed => {tama_id => $tama_id});
}

sub age_tamagotchi {
    my ($self, $tama_id) = @_;

    # try to find tamagotchi
    die "Unknown tamagotchi: $tama_id\n"
        unless exists $self->data->{tamas}{$tama_id};

    # ok, feed it
    $self->_store_event(TamagotchiDayPassed => {
        tama_id => $tama_id
    });
}

sub die_tamagotchi {
    my ($self, $tama_id) = @_;

    # try to find tamagotchi
    die "Unknown tamagotchi: $tama_id\n"
        unless exists $self->data->{tamas}{$tama_id};

    # ok, murder it
    $self->_store_event(TamagotchiDied => {tama_id => $tama_id});
}

1;
__END__
