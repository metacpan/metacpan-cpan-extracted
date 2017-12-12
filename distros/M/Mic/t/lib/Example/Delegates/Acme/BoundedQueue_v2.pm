package Example::Delegates::Acme::BoundedQueue_v2;

use Example::Delegates::Queue;

use Mic::Implementation
    has  => {
        Q => { 
            default => sub { Example::Delegates::Queue::->new },
            handles => {
                q_size => 'size',
                q_pop  => 'pop',
            }
        },

        MAX_SIZE => { 
            init_arg => 'max_size',
        },
    }, 
;

sub push {
    my ($self, $val) = @_;

    $self->[Q]->push($val);

    if ($self->q_size > $self->[MAX_SIZE]) {
        $self->q_pop;        
    }
}

1;
