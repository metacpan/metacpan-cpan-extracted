package Fey::Meta::Method::Constructor;

use strict;
use warnings;
use namespace::autoclean;

our $VERSION = '0.47';

use Moose;

extends 'Moose::Meta::Method::Constructor';

## no critic (Subroutines::ProhibitUnusedPrivateSubroutines)
sub _expected_method_class {
    return 'Fey::Object::Table';
}

## no critic (BuiltinFunctions::ProhibitStringyEval, ErrorHandling::RequireCheckingReturnValueOfEval)
if ( $Moose::VERSION < 1.9900 ) {
    eval <<'EOF';
# XXX - This is copied straight from Moose 0.36 because there's no
# good way to override it (note the eval it does at the end).
sub _initialize_body {
    my $self = shift;

    # TODO:
    # the %options should also include a both
    # a call 'initializer' and call 'SUPER::'
    # options, which should cover approx 90%
    # of the possible use cases (even if it
    # requires some adaption on the part of
    # the author, after all, nothing is free)
    my $source = 'sub {';
    $source .= "\n" . 'my $class = shift;';

    $source .= "\n" . 'return $class->Moose::Object::new(@_)';
    $source
        .= "\n"
        . '    if $class ne \''
        . $self->associated_metaclass->name . '\';';

    $source
        .= "\n"
        . 'my $params = '
        . $self->_generate_BUILDARGS( '$class', '@_' );

    # XXX - override
    $source .= ";\n" . $self->_inline_search_cache();

    # XXX - override
    $source .= "\n" . 'my $instance;';
    $source .= "\n" . '$class->_ClearConstructorError();';
    $source .= "\n" . 'my @args = @_;';

    # XXX - override
    $source .= "\n" . 'Try::Tiny::try {';
    $source .= "\n" . '@_ = @args;';

    # XXX - override
    $source
        .= "\n"
        . '$instance = '
        . $self->associated_metaclass()->inline_create_instance('$class');
    $source .= ";\n";

    $source .= $self->_generate_params( '$params', '$class' );
    $source .= $self->_generate_slot_initializers();
    $source .= $self->_generate_triggers();
    $source .= ";\n" . $self->_generate_BUILDALL();

    # XXX - override
    $source .= ";\n" . '}';

    # XXX - override
    $source .= "\n" . 'Try::Tiny::catch {';
    $source .= "\n"
        . '    die $_ unless Scalar::Util::blessed($_) && $_->isa(q{Fey::Exception::NoSuchRow});';
    $source .= "\n" . '    $class->_SetConstructorError($_);';
    $source .= "\n" . '    undef $instance;';
    $source .= "\n" . '};';

    # XXX - override
    $source .= "\n" . 'return unless $instance;';
    $source .= "\n" . $self->_inline_write_to_cache();

    $source .= "\n" . 'return $instance;';
    $source .= "\n" . '}';

    # XXX - override
    $source .= "\n";

    warn $source if $self->options->{debug};

    my $attrs = $self->_attributes;

    my @type_constraints
        = map { $_->can('type_constraint') ? $_->type_constraint : undef }
        @$attrs;

    my @type_constraint_bodies
        = map { defined $_ ? $_->_compiled_type_constraint : undef; }
        @type_constraints;

    my ( $code, $e ) = $self->_compile_code(
        code        => $source,
        environment => {
            '$meta'                   => \$self,
            '$metaclass'              => \( $self->associated_metaclass ),
            '$attrs'                  => \$attrs,
            '@type_constraints'       => \@type_constraints,
            '@type_constraint_bodies' => \@type_constraint_bodies,
        },
    );

    $self->throw_error(
        "Could not eval the constructor :\n\n$source\n\nbecause :\n\n$e",
        error => $e, data => $source
    ) if $e;

    $self->{'body'} = $code;
}

sub _inline_search_cache {
    my $self = shift;

    my $source = "\n" . 'if ( $metaclass->_object_cache_is_enabled() ) {';
    $source
        .= "\n" . '    my $cached = $metaclass->_search_cache($params);';
    $source .= "\n" . '    return $cached if $cached;';
    $source .= "\n" . '}';
}

sub _inline_write_to_cache {
    my $self = shift;

    return "\n"
        . '$metaclass->_write_to_cache($instance) if $metaclass->_object_cache_is_enabled();';
}
EOF
}
else {
    override _eval_environment => sub {
        my $self = shift;

        my $env = super();
        $env->{'$metaclass'} = \( $self->associated_metaclass() );

        return $env;
    };
}

__PACKAGE__->meta()->make_immutable( inline_constructor => 0 );

1;
