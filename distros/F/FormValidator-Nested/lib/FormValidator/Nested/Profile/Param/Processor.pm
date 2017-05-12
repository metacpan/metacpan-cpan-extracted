package FormValidator::Nested::Profile::Param::Processor;
use Any::Moose '::Role';
use Any::Moose 'X::AttributeHelpers';
use namespace::clean -except => 'meta';

has 'param' => (
    is  => 'ro',
    isa => 'FormValidator::Nested::Profile::Param',
    required => 1,
    weak_ref => 1,
);
has 'class' => (
    is  => 'ro',
    isa => 'ClassName',
    required => 1,
);
has 'method' => (
    is  => 'ro',
    isa => 'Str',
    required => 1,
);
has 'method_ref' => (
    is  => 'ro',
    isa => 'CodeRef',
    lazy_build => 1,
);
has 'options' => (
    metaclass => 'Collection::Hash',
    is        => 'ro',
    isa       => 'HashRef',
    default   => sub { {} },
    provides  => {
        get      => 'get_option',
        exists   => 'exists_option',
    },
);
requires 'process_array';
requires 'process_scalar';


sub _build_method_ref {
    my $self = shift;
    my $method = $self->class->can($self->method);
    if ( !$method ) {
        die("method not found " . $self->class . "::" . $self->method);
    }
    return $method;
}



sub process {
    my $self  = shift;

    if ( $self->param->array ) {
        return $self->process_array(@_);
    }
    else {
        return $self->process_scalar(@_);
    }

}

sub _make_param_name {
    my ( $self, $parent_names, $param_name ) = @_;

    if ( $parent_names ) {
        my $parent_count = @{$parent_names};
        return sprintf('%s' . '[%s]' x $parent_count, @${parent_names}, $param_name);
    }
    else {
        return $param_name;
    }

}

1;
