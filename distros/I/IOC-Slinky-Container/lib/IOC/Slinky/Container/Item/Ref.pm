package IOC::Slinky::Container::Item::Ref;
use strict;
use Scalar::Util qw/weaken refaddr/;

my $CONTAINERS = { };
my $REF_KEYS = { };

sub TIESCALAR {
    my ($class, $container, $ref_key) = @_;
    my $scalar = '';
    my $self = bless(\$scalar, $class);
    $REF_KEYS->{refaddr($self)} = $ref_key;
    weaken $container;
    $CONTAINERS->{refaddr($self)} = $container;
    return $self;
}

sub FETCH {
    my ($self) = @_;
    #print STDERR $self . ": FETCH()d\n";
    my $ref_key = $REF_KEYS->{refaddr($self)};
    return $CONTAINERS->{refaddr($self)}->lookup($ref_key);
}

sub DESTROY {
    my ($self) = @_;
    delete $REF_KEYS->{refaddr($self)};
    delete $CONTAINERS->{refaddr($self)};
}

1;

__END__
