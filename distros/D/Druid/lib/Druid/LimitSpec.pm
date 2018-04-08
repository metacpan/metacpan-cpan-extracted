package Druid::LimitSpec;

use Moo;

has limit   => (is => 'ro');
has columns => (is  => 'ro', default => sub { [] });

sub build {
    my $self = shift;

    my $limit_spec = {
        'type'      => 'default',
        'limit'     => $self->limit,
        'columns'   => $self->columns,
    };

    return $limit_spec;

}


1;