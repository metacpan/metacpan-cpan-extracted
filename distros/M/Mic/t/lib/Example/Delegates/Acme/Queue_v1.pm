package Example::Delegates::Acme::Queue_v1;

use Mic::Implementation
    has  => {
        Q => { default => sub { [ ] } },
    }, 
;

sub head {
    my ($self) = @_;
    $self->{$Q}[0];
}

sub tail {
    my ($self) = @_;
    $self->{$Q}[-1];
}

sub size {
    my ($self) = @_;
    scalar @{ $self->{$Q} };
}

sub push {
    my ($self, $val) = @_;

    push @{ $self->{$Q} }, $val;
}

sub pop {
    my ($self) = @_;
    shift @{ $self->{$Q} };
}

1;
