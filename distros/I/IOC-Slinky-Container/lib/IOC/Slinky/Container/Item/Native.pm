package IOC::Slinky::Container::Item::Native;
use strict;
use Scalar::Util qw/weaken refaddr/;

my $VALUES = { };

sub TIESCALAR {
    my ($class, $value) = @_;
    my $scalar = '';
    my $self = bless(\$scalar, $class);
    $VALUES->{refaddr($self)} = $value;
    return $self;
}

sub FETCH {
    my ($self) = @_;
    return $VALUES->{refaddr($self)};
}

sub DESTROY {
    my ($self) = @_;
    delete $VALUES->{refaddr($self)};
}

1;

__END__

