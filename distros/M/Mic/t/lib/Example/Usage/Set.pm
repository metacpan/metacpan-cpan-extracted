package Example::Usage::Set;

use Mic;

Mic->define_class({
    interface => { 
        object => {
            add => {},
            has => {},
        },
        class => { new => {} }
    },

    via => 'Example::Usage::HashSet',
});

package Example::Usage::HashSet;

use Mic::Impl
    has => { SET => { default => sub { {} } } },
;

sub has {
    my ($self, $e) = @_;
    exists $self->[SET]{$e};
}

sub add {
    my ($self, $e) = @_;
    ++$self->[SET]{$e};
}

1;
