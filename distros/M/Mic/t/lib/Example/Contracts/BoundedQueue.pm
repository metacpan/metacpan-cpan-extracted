package Example::Contracts::BoundedQueue;

use Mic::Class
    interface => {
        class => {
            new => {
                require => {
                    positive_int_size => sub {
                        my (undef, $arg) = @_;
                        $arg->{max_size} =~ /^\d+$/ && $arg->{max_size} > 0;
                    },
                },
                ensure => {
                    zero_sized => sub {
                        my ($obj) = @_;
                        $obj->size == 0;
                    },
                }
            },
        },
        object => {
            head => {},
            tail => {},
            size => {},
            max_size => {},

            push => {
                ensure => {
                    size_increased => sub {
                        my ($self, $old) = @_;

                        return $self->size < $self->max_size
                          ? $self->size == $old->size + 1
                          : 1;
                    },
                    tail_updated => sub {
                        my ($self, $old, $results, $item) = @_;
                        $self->tail == $item;
                    },
                }
            },

            pop => {
                require => {
                    not_empty => sub {
                        my ($self) = @_;
                        $self->size > 0;
                    },
                },
                ensure => {
                    returns_old_head => sub {
                        my ($self, $old, $results) = @_;
                        $results->[0] == $old->head;
                    },
                }
            },
        },
        invariant => {
            max_size_not_exceeded => sub {
                my ($self) = @_;
                $self->size <= $self->max_size;
            },
        },
    },

    implementation => 'Example::Contracts::Acme::BoundedQueue_v1',
;

1;
