package Example::Delegates::Acme::BoundedQueue_v1;

use Example::Delegates::Queue;

use Mic::Implementation
    has  => {
        Q => { 
            default => sub { Example::Delegates::Queue::->new },
            handles => [qw( size pop )],
        },

        MAX_SIZE => { 
            init_arg => 'max_size',
        },
    }, 
;

sub push {
    my ($self, $val) = @_;

    $self->{$Q}->push($val);

    if ($self->size > $self->{$MAX_SIZE}) {
        $self->pop;        
    }
}

1;
