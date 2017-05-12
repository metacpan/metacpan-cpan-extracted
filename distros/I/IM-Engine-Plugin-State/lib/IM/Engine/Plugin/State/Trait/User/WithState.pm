package IM::Engine::Plugin::State::Trait::User::WithState;
use Moose::Role;

has _state_plugin => (
    is       => 'ro',
    isa      => 'IM::Engine::Plugin::State',
    required => 1,
);

# Unfortunately this can't be delegation because we need to pass the user to
# each remote method
for (
    [get_state   => 'get_user_state'],
    [set_state   => 'set_user_state'],
    [clear_state => 'clear_user_state'],
    [has_state   => 'has_user_state'],
) {
    my ($local, $remote) = @$_;
    __PACKAGE__->meta->add_method($local => sub {
        my $self = shift;
        $self->_state_plugin->$remote($self, @_)
    });
}

1;

