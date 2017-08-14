package Example::ArrayImps::HashSet;

use Mic::ArrayImpl
    has => { SET => { default => sub { {} } } },
;

sub has {
    my ($self, $e) = @_;
    exists $self->[ $SET ]{$e};
}

sub add {
    my ($self, $e) = @_;
    ++$self->[ $SET ]{$e};
    log_info($self);
}

sub log_info {
    my ($self) = @_;

    warn sprintf "[%s] I have %d element(s)\n", scalar(localtime), scalar(keys %{ $self->[$SET] });
}

1;
