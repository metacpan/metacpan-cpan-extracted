package IOC::Slinky::Container::Item::Constructed;
use strict;
use Class::Load qw/load_class/;
use Scalar::Util qw/weaken refaddr/;

my $SPEC = { };


sub TIESCALAR {
    my ($class, $container, $ns, $new, $ctor, $ctor_passthru, $setter, $singleton) = @_;
    my $scalar = '';
    my $self = bless(\$scalar, $class);
    $SPEC->{refaddr($self)} = [ { }, $container, $ns, $new, $ctor, $ctor_passthru, $setter, $singleton ];
    return $self;
}

sub FETCH {
    my ($self) = @_;
    my $spec = $SPEC->{refaddr($self)};
    my ($tmp, $container, $ns, $new, $ctor, $ctor_passthru, $setter, $singleton) = @$spec;
    if ($singleton) {
        # short circuit the process
        if (exists $tmp->{last_inst}) {
            return $tmp->{last_inst};
        }
    }
    # class loader
    load_class($ns);
    
    # constructor
    # -----------
    if ($ctor_passthru) {
        # passthru forces the constructor args as is
        $tmp->{last_inst} = $ns->$new($ctor);
    }
    elsif (ref($ctor) eq 'HASH') {
        # pass as hash
        $tmp->{last_inst} = $ns->$new(%$ctor);
    }
    elsif (ref($ctor) eq 'ARRAY') {
        # pass as list
        $tmp->{last_inst} = $ns->$new(@$ctor);
    }
    else {
        # pass as scalar
        $tmp->{last_inst} = $ns->$new($ctor);
    }
    # set setter args
    # ---------------
    while (my ($k,$v) = each(%$setter)) {
        $container->wire($container, $v);
        $tmp->{last_inst}->$k($v);
    }
    return $tmp->{last_inst};
}


sub DESTROY {
    my ($self) = @_;
    delete $SPEC->{refaddr($self)};
}

1;

__END__
