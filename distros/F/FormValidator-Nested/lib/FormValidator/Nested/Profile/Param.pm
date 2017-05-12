package FormValidator::Nested::Profile::Param;
use Any::Moose;
use Any::Moose 'X::AttributeHelpers';
use namespace::clean -except => 'meta';

use FormValidator::Nested::Profile::Param::Validator;
use FormValidator::Nested::Profile::Param::Filter;
use FormValidator::Nested::Validator::Internal;
use FormValidator::Nested::Result;

use UNIVERSAL::require;

has 'profile' => (
    is  => 'ro',
    isa => 'FormValidator::Nested::Profile',
    required => 1,
    weak_ref => 1,
);
has 'key' => (
    is  => 'ro',
    isa => 'Str',
    required => 1,
);
has 'name' => (
    is  => 'ro',
    isa => 'Str',
    default => '',
);
has 'data' => (
    is  => 'ro',
    isa => 'HashRef',
    required => 1,
);
has 'array' => (
    is  => 'ro',
    isa => 'Bool',
    default => 0,
);
has 'nested' => (
    is  => 'ro',
    isa => 'FormValidator::Nested::Profile',
);
has 'validators' => (
    metaclass  => 'Collection::Array',
    is         => 'ro',
    isa        => 'ArrayRef[FormValidator::Nested::Profile::Param::Validator]',
    lazy_build => 1,
    provides   => {
        elements => 'get_validators',
        get      => 'get_validator',
    },
);
has 'filters' => (
    metaclass  => 'Collection::Array',
    is         => 'ro',
    isa        => 'ArrayRef[FormValidator::Nested::Profile::Param::Filter]',
    lazy_build => 1,
    provides   => {
        elements => 'get_filters',
        get      => 'get_filter',
    },
);
__PACKAGE__->meta->make_immutable;

sub BUILD {
    my $self = shift;

    # processorの初期化
    $self->validators;
    $self->filters;
}

sub _build_validators {
    my $self = shift;

    my @internal_validators = ();
    if ( $self->nested ) {
        # nestしてる場合はハッシュチェックも
        push @internal_validators, FormValidator::Nested::Profile::Param::Validator->new({
            param   => $self,
            class   => 'FormValidator::Nested::Validator::Internal',
            method  => 'nested_hash',
        });
    }

    return [@internal_validators, $self->__build_processors('validators')];
}
sub _build_filters {
    my $self = shift;

    return [$self->__build_processors('filters')];
}
sub __build_processors {
    my $self = shift;
    my $name = shift;
    my ($name_single) = $name =~ m/^(.*)s$/;

    my $processor_class = 'FormValidator::Nested::Profile::Param::' . ucfirst($name_single);

    my @processors = ();
    foreach my $processor ( @{$self->data->{$name}} ) {
        my $class_method = $processor;
        my $options = {};
        if ( ref $processor ) {
            ($class_method) = keys   %{$processor};
            ($options)      = values %{$processor};
        }

        my ( $class, $method ) = split /#/, $class_method;
        if ( $name eq 'validators' ) {
            if ( $class =~ /^\+(.*)/ ) {
                $class = $1;
            }
            else {
                $class = 'FormValidator::Nested::Validator::' . $class;
            }
        }
        elsif ( $name eq 'filters' ) {
            if ( $class =~ /^\+(.*)/ ) {
                $class = $1;
            }
            else {
                $class = 'FormValidator::Nested::Filter::' . $class;
            }
        }
        if ( !$class->require ) {
            die("no require $class");
        }
        push @processors, $processor_class->new({
            param   => $self,
            class   => $class,
            method  => $method,
            options => $options,
        });
    }
    return @processors;
}

sub validate {
    my ( $self, $req, $parent_names ) = @_;

    my $values_ref = $self->get_values($req);
    my $param_result = FormValidator::Nested::Result->new;

    foreach my $validator ( $self->get_validators ) {
        $param_result->merge($validator->process($req, $values_ref, $self->key, $parent_names));
    }

    if ( $self->nested && !$param_result->has_error && $values_ref  ) {
        if ( $self->array ) {
            for my $count ( 0 .. $#{$values_ref} ) {
                $param_result->merge(
                    $self->nested->validate(
                        $values_ref->[$count],
                        $parent_names ? [@{$parent_names}, $self->key, $count] : [$self->key, $count]
                    )
                );
            }
        }
        else {
            $param_result->merge(
                $self->nested->validate(
                    $values_ref,
                    $parent_names ? [@{$parent_names}, $self->key] : [$self->key]
                )
            );
        }
    }
    return $param_result;
}

sub get_values {
    my $self = shift;
    my $req  = shift;

    if ( $self->array ) {
        return [$req->param($self->key)];
    }
    else {
        my @values = $req->param($self->key);
        if ( @values > 1 ) {
            # なんかエラーだす必要あるかも
        }
        return $values[0];
    }
}


1;

