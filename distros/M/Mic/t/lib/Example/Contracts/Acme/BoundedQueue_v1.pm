package Example::Contracts::Acme::BoundedQueue_v1;

use Example::Delegates::Queue;

use Mic::Implementation
    has  => {
        Q => {
            default => sub { Example::Delegates::Queue::->new },
            handles => [qw( head tail size pop )],
        },

        MAX_SIZE => {
            init_arg => 'max_size',
            reader   => 'max_size',
        },
    }, 
;

sub push {
    my ($self, $val) = @_;

    if ($self->size == $self->[MAX_SIZE]) {
        $self->pop;        
    }

    $self->[Q]->push($val);
}

1;
