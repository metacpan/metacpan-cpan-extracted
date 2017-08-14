package Example::Extension::BoundedQueue_v2;

use Mic::Class
    interface => { 
        extends => [qw/Example::Delegates::Queue/],

        object => {
            max_size => {},
        },

        invariant => {
            max_size_not_exceeded => sub {
                my ($self) = @_;
                $self->size <= $self->max_size;
            },
        },
    },

    implementation => 'Example::Delegates::Acme::BoundedQueue_v1',
;

1;
