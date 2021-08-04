package JSONSchema::Validator::Constraints::Draft4;

# ABSTRACT: JSON Schema Draft4 specification constraints

use strict;
use warnings;
use Scalar::Util 'weaken';
use URI;
use Carp 'croak';

use JSONSchema::Validator::Error 'error';
use JSONSchema::Validator::JSONPointer 'json_pointer';
use JSONSchema::Validator::Util qw(serialize unbool round is_type detect_type);
use JSONSchema::Validator::Format qw(
    validate_date_time validate_date validate_time
    validate_email validate_hostname
    validate_idn_email
    validate_ipv4 validate_ipv6
    validate_uuid
    validate_byte
    validate_int32 validate_int64
    validate_float validate_double
    validate_regex
    validate_json_pointer validate_relative_json_pointer
    validate_uri validate_uri_reference
    validate_iri validate_iri_reference
    validate_uri_template
);

use constant FORMAT_VALIDATIONS => {
    'date-time' => ['string', \&validate_date_time],
    'date' => ['string', \&validate_date],
    'time' => ['string', \&validate_time],
    'email' => ['string', \&validate_email],
    'idn-email' => ['string', \&validate_idn_email],
    'hostname' => ['string', \&validate_hostname],
    'ipv4' => ['string', \&validate_ipv4],
    'ipv6' => ['string', \&validate_ipv6],
    'uuid' => ['string', \&validate_uuid],
    'byte' => ['string', \&validate_byte],
    'int32' => ['integer', \&validate_int32],
    'int64' => ['integer', \&validate_int64],
    'float' => ['number', \&validate_float],
    'double' => ['number', \&validate_double],
    'regex' => ['string', \&validate_regex],
    'json-pointer' => ['string', \&validate_json_pointer],
    'relative-json-pointer' => ['string', \&validate_relative_json_pointer],
    'uri' => ['string', \&validate_uri],
    'uri-reference' => ['string', \&validate_uri_reference],
    'iri' => ['string', \&validate_iri],
    'iri-reference' => ['string', \&validate_iri_reference],
    'uri-template' => ['string', \&validate_uri_template]
};
use constant EPSILON => 1e-7;

sub new {
    my ($class, %params) = @_;

    my $validator = $params{validator} or croak 'validator is required';
    my $strict = $params{strict} // 1;

    weaken($validator);

    my $self = {
        validator => $validator,
        errors => [],
        strict => $strict
    };

    bless $self, $class;

    return $self;
}

sub validator { shift->{validator} }
sub strict { shift->{strict} }

# params: $self, $value, $type
sub check_type {
    return is_type($_[1], $_[2], $_[0]->strict);
}

sub type {
    my ($self, $instance, $types, $schema, $instance_path, $schema_path, $data) = @_;
    my @types = ref $types ? @$types : ($types);

    return 1 if grep { $self->check_type($instance, $_) } @types;

    push @{$data->{errors}}, error(
        message => "type mismatch",
        instance_path => $instance_path,
        schema_path => $schema_path
    );
    return 0;
}

sub minimum {
    my ($self, $instance, $minimum, $schema, $instance_path, $schema_path, $data) = @_;
    return 1 unless $self->check_type($instance, 'number');
    return 1 if $instance >= $minimum;
    push @{$data->{errors}}, error(
        message => "${instance} is less than ${minimum}",
        instance_path => $instance_path,
        schema_path => $schema_path
    );
    return 0;
}

sub maximum {
    my ($self, $instance, $maximum, $schema, $instance_path, $schema_path, $data) = @_;
    return 1 unless $self->check_type($instance, 'number');
    return 1 if $instance <= $maximum;
    push @{$data->{errors}}, error(
        message => "${instance} is greater than ${maximum}",
        instance_path => $instance_path,
        schema_path => $schema_path
    );
    return 0;
}

sub exclusiveMaximum {
    my ($self, $instance, $exclusiveMaximum, $schema, $instance_path, $schema_path, $data) = @_;
    return 1 unless $self->check_type($instance, 'number');
    return 1 unless exists $schema->{maximum};

    my $maximum = $schema->{maximum};

    my $res = $self->maximum($instance, $maximum, $schema, $instance_path, $schema_path, $data);
    return 0 unless $res;

    return 1 unless $exclusiveMaximum;
    return 1 if $instance != $maximum;

    push @{$data->{errors}}, error(
        message => "${instance} is equal to ${maximum}",
        instance_path => $instance_path,
        schema_path => $schema_path
    );
    return 0;
}

sub exclusiveMinimum {
    my ($self, $instance, $exclusiveMinimum, $schema, $instance_path, $schema_path, $data) = @_;
    return 1 unless $self->check_type($instance, 'number');
    return 1 unless exists $schema->{minimum};

    my $minimum = $schema->{minimum};

    my $res = $self->minimum($instance, $minimum, $schema, $instance_path, $schema_path, $data);
    return 0 unless $res;

    return 1 unless $exclusiveMinimum;
    return 1 if $instance != $minimum;

    push @{$data->{errors}}, error(
        message => "${instance} is equal to ${minimum}",
        instance_path => $instance_path,
        schema_path => $schema_path
    );
    return 0;
}

sub minItems {
    my ($self, $instance, $min, $schema, $instance_path, $schema_path, $data) = @_;
    return 1 unless $self->check_type($instance, 'array');
    return 1 if scalar(@$instance) >= $min;
    push @{$data->{errors}}, error(
        message => "minItems (>= ${min}) constraint violated",
        instance_path => $instance_path,
        schema_path => $schema_path
    );
    return 0;
}

sub maxItems {
    my ($self, $instance, $max, $schema, $instance_path, $schema_path, $data) = @_;
    return 1 unless $self->check_type($instance, 'array');
    return 1 if scalar(@$instance) <= $max;
    push @{$data->{errors}}, error(
        message => "maxItems (<= ${max}) constraint violated",
        instance_path => $instance_path,
        schema_path => $schema_path
    );
    return 0;
}

sub minLength {
    my ($self, $instance, $min, $schema, $instance_path, $schema_path, $data) = @_;
    return 1 unless $self->check_type($instance, 'string');
    return 1 if length $instance >= $min;
    push @{$data->{errors}}, error(
        message => "minLength (>= ${min}) constraint violated",
        instance_path => $instance_path,
        schema_path => $schema_path
    );
    return 0;
}

sub maxLength {
    my ($self, $instance, $max, $schema, $instance_path, $schema_path, $data) = @_;
    return 1 unless $self->check_type($instance, 'string');
    return 1 if length $instance <= $max;
    push @{$data->{errors}}, error(
        message => "maxLength (<= ${max}) constraint violated",
        instance_path => $instance_path,
        schema_path => $schema_path
    );
    return 0;
}

sub dependencies {
    my ($self, $instance, $dependencies, $schema, $instance_path, $schema_path, $data) = @_;

    # ignore non-object
    return 1 unless $self->check_type($instance, 'object');

    my $result = 1;

    for my $prop (keys %$dependencies) {
        next unless exists $instance->{$prop};
        my $dep = $dependencies->{$prop};
        my $spath = json_pointer->append($schema_path, $prop);

        if ($self->check_type($dep, 'array')) {
            for my $idx (0 .. $#{$dep}) {
                my $p = $dep->[$idx];
                next if exists $instance->{$p};

                push @{$data->{errors}}, error(
                    message => "dependencies constraint violated: property $p is ommited",
                    instance_path => $instance_path,
                    schema_path => json_pointer->append($spath, $idx)
                );
                $result = 0;
            }
        } else {
            # $dep is object or boolean (starting draft 6 boolean is valid schema)
            my $r = $self->validator->_validate_schema($instance, $dep, $instance_path, $spath, $data);
            $result = 0 unless $r;
        }
    }

    return $result;
}

sub additionalItems {
    my ($self, $instance, $additionalItems, $schema, $instance_path, $schema_path, $data) = @_;
    return 1 unless $self->check_type($instance, 'array');
    return 1 if $self->check_type($schema->{items} // {}, 'object');

    my $len_items = scalar @{$schema->{items}};

    if ($self->check_type($additionalItems, 'boolean')) {
        return 1 if $additionalItems;
        if  (scalar @$instance > $len_items) {
            push @{$data->{errors}}, error(
                message => 'additionalItems constraint violated',
                instance_path => $instance_path,
                schema_path => $schema_path
            );
            return 0;
        }

        return 1;
    }

    # additionalItems is object

    my $result = 1;
    my @items_last_part = @$instance[$len_items .. $#{$instance}];

    for my $index (0 .. $#items_last_part) {
        my $item = $items_last_part[$index];

        my $ipath = json_pointer->append($instance_path, $len_items + $index);
        my $r = $self->validator->_validate_schema($item, $additionalItems, $ipath, $schema_path, $data);
        $result = 0 unless $r;
    }

    return $result;
}

sub additionalProperties {
    my ($self, $instance, $addProps, $schema, $instance_path, $schema_path, $data) = @_;
    return 1 unless $self->check_type($instance, 'object');

    my $patterns = join '|', keys %{$schema->{patternProperties} // {}};

    my @extra_props;
    for my $p (keys %$instance) {
        next if $schema->{properties} && exists $schema->{properties}{$p};
        next if $patterns && $p =~ m/$patterns/u;
        push @extra_props, $p;
    }

    return 1 unless @extra_props;

    if ($self->check_type($addProps, 'object')) {
        my $result = 1;
        for my $p (@extra_props) {
            my $ipath = json_pointer->append($instance_path, $p);
            my $r = $self->validator->_validate_schema($instance->{$p}, $addProps, $ipath, $schema_path, $data);
            $result = 0 unless $r;
        }
        return $result;
    }

    # addProps is boolean

    return 1 if $addProps;

    push @{$data->{errors}}, error(
        message => 'additionalProperties constraint violated; properties: ' . join(', ', @extra_props),
        instance_path => $instance_path,
        schema_path => $schema_path
    );
    return 0;
}

sub allOf {
    my ($self, $instance, $allOf, $schema, $instance_path, $schema_path, $data) = @_;

    my $result = 1;
    for my $idx (0 .. $#{$allOf}) {
        my $subschema = $allOf->[$idx];
        my $spath = json_pointer->append($schema_path, $idx);
        my $r = $self->validator->_validate_schema($instance, $subschema, $instance_path, $spath, $data);
        $result = 0 unless $r;
    }

    return $result;
}

sub anyOf {
    my ($self, $instance, $anyOf, $schema, $instance_path, $schema_path, $data) = @_;

    my $errors = $data->{errors};
    my $local_errors = [];

    my $result = 0;
    for my $idx (0 .. $#$anyOf) {
        $data->{errors} = [];
        my $spath = json_pointer->append($schema_path, $idx);
        $result = $self->validator->_validate_schema($instance, $anyOf->[$idx], $instance_path, $spath, $data);
        unless ($result) {
            push @{$local_errors}, error(
                message => qq'${idx} part of "anyOf" has errors',
                context => $data->{errors},
                instance_path => $instance_path,
                schema_path => $spath
            );
        }
        last if $result;
    }
    $data->{errors} = $errors;
    return 1 if $result;

    push @{$data->{errors}}, error(
        message => 'instance does not satisfy any schema of "anyOf"',
        context => $local_errors,
        instance_path => $instance_path,
        schema_path => $schema_path
    );
    return 0;
}

sub oneOf {
    my ($self, $instance, $oneOf, $schema, $instance_path, $schema_path, $data) = @_;

    my $errors = $data->{errors};
    my ($local_errors, $valid_schemas) = ([], []);

    my $num = 0;
    for my $idx (0 .. $#$oneOf) {
        $data->{errors} = [];
        my $spath = json_pointer->append($schema_path, $idx);
        my $r = $self->validator->_validate_schema($instance, $oneOf->[$idx], $instance_path, $spath, $data);
        if ($r) {
            push @{$valid_schemas}, $spath;
        } else {
            push @{$local_errors}, error(
                message => qq'${idx} part of "oneOf" has errors',
                context => $data->{errors},
                instance_path => $instance_path,
                schema_path => $spath
            );
        }
        ++$num if $r;
    }
    $data->{errors} = $errors;
    return 1 if $num == 1;

    if ($num > 1) {
        push @{$data->{errors}}, error(
            message => 'instance is valid under more than one schema of "oneOf": ' . join(' ', @$valid_schemas),
            instance_path => $instance_path,
            schema_path => $schema_path
        );
    } else {
        push @{$data->{errors}}, error(
            message => 'instance is not valid under any of given schemas of "oneOf"',
            context => $local_errors,
            instance_path => $instance_path,
            schema_path => $schema_path
        );
    }

    return 0;
}

sub enum {
    my ($self, $instance, $enum, $schema, $instance_path, $schema_path, $data) = @_;

    my $result = 0;
    for my $e (@$enum) {
        if ($self->check_type($e, 'boolean')) {
            $result = $self->check_type($instance, 'boolean')
                        ? unbool($instance) eq unbool($e)
                        : 0
        } elsif ($self->check_type($e, 'object') || $self->check_type($e, 'array')) {
            $result =   $self->check_type($instance, 'object') ||
                        $self->check_type($instance, 'array')
                        ? serialize($instance) eq serialize($e)
                        : 0;
        } elsif ($self->check_type($e, 'number')) {
            $result =   $self->check_type($instance, 'number')
                        ? $e == $instance
                        : 0;
        } elsif (defined $e && defined $instance) {
            $result = $e eq $instance;
        } elsif (!defined $e && !defined $instance) {
            $result = 1;
        } else {
            $result = 0;
        }
        last if $result;
    }

    return 1 if $result;

    push @{$data->{errors}}, error(
        message => "instance is not of enums",
        instance_path => $instance_path,
        schema_path => $schema_path
    );
    return 0;
}

sub items {
    my ($self, $instance, $items, $schema, $instance_path, $schema_path, $data) = @_;
    return 1 unless $self->check_type($instance, 'array');

    my $result = 1;
    if ($self->check_type($items, 'array')) {
        my $min = $#{$items} > $#{$instance} ? $#{$instance} : $#{$items};
        for my $i (0 .. $min) {
            my $item = $instance->[$i];
            my $subschema = $items->[$i];
            my $spath = json_pointer->append($schema_path, $i);
            my $ipath = json_pointer->append($instance_path, $i);
            my $r = $self->validator->_validate_schema($item, $subschema, $ipath, $spath, $data);
            $result = 0 unless $r;
        }
    } else {
        # items is object
        for my $i (0 .. $#{$instance}) {
            my $item = $instance->[$i];
            my $ipath = json_pointer->append($instance_path, $i);
            my $r = $self->validator->_validate_schema($item, $items, $ipath, $schema_path, $data);
            $result = 0 unless $r;
        }
    }
    return $result;
}

sub format {
    my ($self, $instance, $format, $schema, $instance_path, $schema_path, $data) = @_;
    return 1 unless exists FORMAT_VALIDATIONS->{$format};

    my ($type, $checker) = @{FORMAT_VALIDATIONS->{$format}};
    return 1 unless $self->check_type($instance, $type);

    my $result = $checker->($instance);
    return 1 if $result;

    push @{$data->{errors}}, error(
        message => "instance is not $format",
        instance_path => $instance_path,
        schema_path => $schema_path
    );
    return 0;
}

sub maxProperties {
    my ($self, $instance, $maxProperties, $schema, $instance_path, $schema_path, $data) = @_;
    return 1 unless $self->check_type($instance, 'object');
    return 1 if scalar(keys %$instance) <= $maxProperties;

    push @{$data->{errors}}, error(
        message => "instance has more than $maxProperties properties",
        instance_path => $instance_path,
        schema_path => $schema_path
    );
    return 0;
}

sub minProperties {
    my ($self, $instance, $minProperties, $schema, $instance_path, $schema_path, $data) = @_;
    return 1 unless $self->check_type($instance, 'object');
    return 1 if scalar(keys %$instance) >= $minProperties;

    push @{$data->{errors}}, error(
        message => "instance has less than $minProperties properties",
        instance_path => $instance_path,
        schema_path => $schema_path
    );
    return 0;
}

sub multipleOf {
    my ($self, $instance, $multipleOf, $schema, $instance_path, $schema_path, $data) = @_;
    return 1 unless $self->check_type($instance, 'number');

    my $result = 1;
    my $div = $instance / $multipleOf;
    $result = 0 if $div == 'Inf' || abs($div - round($div)) > EPSILON;

    return 1 if $result;

    push @{$data->{errors}}, error(
        message => "instance is not multiple of $multipleOf",
        instance_path => $instance_path,
        schema_path => $schema_path
    );
    return 0;
}

sub not {
    my ($self, $instance, $not, $schema, $instance_path, $schema_path, $data) = @_;

    my $errors = $data->{errors};
    $data->{errors} = [];

    # not is schema
    my $result = $self->validator->_validate_schema($instance, $not, $instance_path, $schema_path, $data);
    $data->{errors} = $errors;
    return 1 unless $result;

    push @{$data->{errors}}, error(
        message => 'instance satisfies the schema defined in \"not\" keyword',
        instance_path => $instance_path,
        schema_path => $schema_path
    );
    return 0;
}

sub pattern {
    my ($self, $instance, $pattern, $schema, $instance_path, $schema_path, $data) = @_;
    return 1 unless $self->check_type($instance, 'string');
    return 1 if $instance =~ m/$pattern/u;

    push @{$data->{errors}}, error(
        message => "instance does not match $pattern",
        instance_path => $instance_path,
        schema_path => $schema_path
    );
    return 0;
}

sub patternProperties {
    my ($self, $instance, $patternProperties, $schema, $instance_path, $schema_path, $data) = @_;
    return 1 unless $self->check_type($instance, 'object');

    my $result = 1;
    for my $pattern (keys %$patternProperties) {
        my $subschema = $patternProperties->{$pattern};
        my $spath = json_pointer->append($schema_path, $pattern);
        for my $k (keys %$instance) {
            my $v = $instance->{$k};
            if ($k =~ m/$pattern/u) {
                my $ipath = json_pointer->append($instance_path, $k);
                my $r = $self->validator->_validate_schema($v, $subschema, $ipath, $spath, $data);
                $result = 0 unless $r;
            }
        }
    }
    return $result;
}

sub properties {
    my ($self, $instance, $properties, $schema, $instance_path, $schema_path, $data) = @_;
    return 1 unless $self->check_type($instance, 'object');

    my $result = 1;
    for my $prop (keys %$properties) {
        next unless exists $instance->{$prop};

        my $subschema = $properties->{$prop};
        my $spath = json_pointer->append($schema_path, $prop);
        my $ipath = json_pointer->append($instance_path, $prop);
        my $r = $self->validator->_validate_schema($instance->{$prop}, $subschema, $ipath, $spath, $data);
        $result = 0 unless $r;
    }
    return $result;
}

sub required {
    my ($self, $instance, $required, $schema, $instance_path, $schema_path, $data) = @_;
    return 1 unless $self->check_type($instance, 'object');

    my $result = 1;
    for my $idx (0 .. $#{$required}) {
        my $prop = $required->[$idx];
        next if exists $instance->{$prop};
        push @{$data->{errors}}, error(
            message => qq{instance does not have required property "$prop"},
            instance_path => $instance_path,
            schema_path => json_pointer->append($schema_path, $idx)
        );
        $result = 0;
    }
    return $result;
}

# doesn't work for string that looks like number with the same number in array
sub uniqueItems {
    my ($self, $instance, $uniqueItems, $schema, $instance_path, $schema_path, $data) = @_;
    return 1 unless $self->check_type($instance, 'array');
    # uniqueItems is boolean
    return 1 unless $uniqueItems;

    my %hash = map {
        my $type = detect_type($_, $self->strict);

        my $value;
        if ($type eq 'null') {
            $value = ''
        } elsif ($type eq 'object' || $type eq 'array') {
            $value = serialize($_);
        } elsif ($type eq 'boolean') {
            $value = "$_";
        } else {
            # integer/number/string
            $value = $_;
        }

        my $key = "${type}#${value}";
        $key => 1;
    } @$instance;
    return 1 if scalar(keys %hash) == scalar @$instance;
    push @{$data->{errors}}, error(
        message => "instance has non-unique elements",
        instance_path => $instance_path,
        schema_path => $schema_path
    );
    return 0;
}

sub ref {
    my ($self, $instance, $ref, $origin_schema, $instance_path, $schema_path, $data) = @_;

    my $scope = $self->validator->scope;
    $ref = URI->new($ref);
    $ref = $ref->abs($scope) if $scope;

    my ($current_scope, $schema) = $self->validator->resolver->resolve($ref);

    croak "schema not resolved by ref $ref" unless $schema;

    push @{$self->validator->scopes}, $current_scope;

    my $result = eval {
        $self->validator->_validate_schema($instance, $schema, $instance_path, $schema_path, $data, apply_scope => 0);
    };

    if ($@) {
        $result = 0;
        push @{$data->{errors}}, error(
            message => "exception: $@",
            instance_path => $instance_path,
            schema_path => $schema_path
        );
    }

    pop @{$self->validator->scopes};

    return $result;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

JSONSchema::Validator::Constraints::Draft4 - JSON Schema Draft4 specification constraints

=head1 VERSION

version 0.005

=head1 AUTHORS

=over 4

=item *

Alexey Stavrov <logioniz@ya.ru>

=item *

Ivan Putintsev <uid@rydlab.ru>

=item *

Anton Fedotov <tosha.fedotov.2000@gmail.com>

=item *

Denis Ibaev <dionys@gmail.com>

=item *

Andrey Khozov <andrey@rydlab.ru>

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2021 by Alexey Stavrov.

This is free software, licensed under:

  The MIT (X11) License

=cut
