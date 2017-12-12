package Example::Contracts::Acme::BoundedQueue_v6;

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

sub BUILD { 
    my ($self) = @_;

    # make constructor postcondition fail
    $self->[Q]->push(1);
}

sub push {
    my ($self, $val) = @_;

    $self->[Q]->push($val);

    if ($self->size > $self->[MAX_SIZE]) {
        $self->pop;        
    }
}

1;
