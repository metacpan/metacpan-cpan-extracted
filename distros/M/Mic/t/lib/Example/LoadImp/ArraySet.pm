package Example::LoadImp::ArraySet;

use Mic::Implementation

    has => { SET => { default => sub { [] } } },
;

sub has {
    my ($self, $e) = @_;
    scalar grep { $_ == $e } @{ $self->{$SET} };
}

sub add {
    my ($self, $e) = @_;

    if ( ! $self->has($e) ) {
        push @{ $self->{$SET} }, $e;
    }
}

1;
