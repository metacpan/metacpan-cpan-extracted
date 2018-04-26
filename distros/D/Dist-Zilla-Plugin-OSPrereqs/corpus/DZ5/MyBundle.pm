package MyBundle;

use Moose;
with 'Dist::Zilla::Role::PluginBundle::Easy';
sub configure {
    my ($self) = @_;
    # as seen in at least one distribution in the wild...
    $self->add_plugins([ 'OSPrereqs' => { 'Foo::Bar' => 0 } ]);
}

1;
