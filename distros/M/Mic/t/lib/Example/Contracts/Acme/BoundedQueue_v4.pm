package Example::Contracts::Acme::BoundedQueue_v4;

use Example::Delegates::Queue;

use Mic::Implementation
    has  => {
        Q => { 
            default => sub { Example::Delegates::Queue::->new },
            handles => [qw( head size pop )],
        },

        MAX_SIZE => { 
            init_arg => 'max_size',
            reader   => 'max_size',
        },
    }, 
;

sub tail { 
    my ($self) = @_;

    # make postcondition fail
    \ $self->[Q]->tail;
}

sub push {
    my ($self, $val) = @_;

    $self->[Q]->push($val);

    if ($self->size > $self->[MAX_SIZE]) {
        $self->pop;        
    }
}

1;
