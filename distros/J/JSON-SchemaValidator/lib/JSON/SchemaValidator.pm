package JSON::SchemaValidator;

use strict;
use warnings;

our $VERSION = '1.01';

use B        ();
use Storable ();
require Carp;
use Time::Piece;

use JSON::SchemaValidator::Result;
use JSON::SchemaValidator::Pointer qw(pointer);

my $DATETIME_RE = qr/
    ^
        [0-9]{4}\-[0-9]{2}\-[0-9]{2}T[0-9]{2}
        :
        [0-9]{2}:[0-9]{2}
        (?:\.[0-9]{1,6})?
        (?:
            Z
            |
            [-+][0-9]{2}:[0-9]{2}
        )
    $
/ix;

my $HOSTNAME_RE = qr/
    (?:
        (?:[a-z0-9]|[a-z0-9][a-z0-9\-]*[a-z0-9])\.
    )*
    (?:[a-z0-9]|[a-z0-9][a-z0-9\-]*[a-z0-9])
/ix;

my $EMAIL_RE = qr/
    [a-z0-9\._\%\+!\$\&\*=\^\|\~#%\{\}\/\-]+
    \@
    $HOSTNAME_RE
/ix;

sub new {
    my $class = shift;
    my (%params) = @_;

    my $self = {};
    bless $self, $class;

    $self->{formats} = {
        hostname => sub {
            my ($hostname) = @_;

            return 0 if length $hostname > 255;

            return 0 unless $hostname =~ qr/^$HOSTNAME_RE$/;

            return 0 if grep { length > 63 } split /\./, $hostname;

            return 1;
        },
        email => sub {
            my ($email) = @_;

            return 0 unless $email =~ m/^$EMAIL_RE$/;

            my ($username, $hostname) = split /@/, $email;

            return 0 if length $hostname > 255;
            return 0 if grep { length > 63 } split /\./, $hostname;

            return 1;
        },
        ipv4 => sub {
            my ($ipv4) = @_;

            my @parts = split m/\./, $ipv4;

            return unless @parts > 0 && @parts < 5;

            for my $part (@parts) {
                return unless $part =~ m/^[0-9]+$/ && $part >= 0 && $part < 256;
            }

            return unless $parts[-1] > 0;

            return 1;
        },
        ipv6 => sub {
            my ($ipv6) = @_;

            my @parts = split m/\:/, $ipv6;

            return unless @parts > 0 && @parts < 9;

            for my $part (@parts) {
                next if $part eq '';

                return unless $part =~ m/^[0-9a-f]{1,4}$/i;
            }

            return 1;
        },
        'date-time' => sub {
            my ($date_time) = @_;

            return unless $date_time =~ $DATETIME_RE;

            $date_time =~ s{\.[0-9]*}{};
            $date_time =~ s{Z$}{+00:00}i;
            $date_time =~ s{:([0-9]+)$}{$1}i;

            return unless eval { Time::Piece->strptime(uc($date_time), '%Y-%m-%dT%T%z') };

            return 1;
        }
    };
    $self->{fetcher} = $params{fetcher};

    return $self;
}

sub formats { shift->{formats} }

sub validate {
    my $self = shift;
    my ($json, $schema) = @_;

    $schema = Storable::dclone($schema);

    my $context = {
        root    => $schema,
        ids     => {},
        pointer => '#',
    };

    $self->_collect_ids($context, $schema);

    my $result = $self->_validate($context, $json, $schema);

    return $result;
}

sub _collect_ids {
    my $self = shift;
    my ($context, $schema) = @_;

    if (_is_object($schema)) {
        my $new_context = {%$context};

        if ($schema->{id} && _is_string($schema->{id})) {
            my $base_url = $context->{base_url};
            my $path     = $context->{path};

            my $id = $schema->{id};

            if ($id =~ m/^http/) {
                ($base_url) = $id =~ m/^([^#]+)/;
                $path = undef;

                if ($base_url !~ m{/$}) {
                    ($path) = $base_url =~ m{([^\/]+)$};
                    $base_url =~ s{[^\/]+$}{};
                }

                $base_url =~ s{/$}{};
            }
            else {
                if ($id !~ m/^#/) {
                    if ($id =~ m{/$}) {
                        $base_url .= "/$id";
                        $base_url =~ s{/$}{};
                        $path = undef;

                        $id = "$base_url/";
                    }
                    else {
                        $path = $id;

                        if ($base_url) {
                            $id = "$base_url/$id";
                        }
                    }
                }
                elsif ($path) {
                    $id = "$path$id";

                    if ($base_url) {
                        $id = "$base_url/$id";
                    }
                }
            }

            $context->{ids}->{$id} = $schema;

            $new_context->{base_url} = $base_url;
            $new_context->{path}     = $path;
        }

        if ($schema->{'$ref'} && _is_string($schema->{'$ref'})) {
            my $ref = $schema->{'$ref'};

            if ($ref !~ m/^http/) {
                if ($ref =~ m/^#/) {
                    if (my $path = $new_context->{path}) {
                        $ref = "$path$ref";
                    }
                }

                if (my $base_url = $new_context->{base_url}) {
                    $ref = "$base_url/$ref";
                }

                $schema->{'$ref'} = $ref;
            }
        }

        foreach my $key (keys %$schema) {
            $self->_collect_ids($new_context, $schema->{$key});
        }
    }
    elsif (_is_array($schema)) {
        foreach my $el (@$schema) {
            $self->_collect_ids($context, $el);
        }
    }
}

sub _resolve_refs {
    my $self = shift;
    my ($context, $schema) = @_;

    if (_is_object($schema)) {
        if ($schema->{'$ref'} && _is_string($schema->{'$ref'})) {
            my $ref = delete $schema->{'$ref'};

            my $subschema;
            if (exists $context->{ids}->{$ref}) {
                $subschema = $context->{ids}->{$ref};
            }
            else {
                if ($ref !~ m/^http/) {
                    if ($ref =~ m/^#/) {
                        if ($context->{path}) {
                            $ref = "$context->{path}/$ref";
                        }
                    }

                    if ($context->{base_url}) {
                        $ref = "$context->{base_url}/$ref";
                    }
                }

                if (exists $context->{ids}->{$ref}) {
                    $subschema = $context->{ids}->{$ref};
                }
                elsif ($ref =~ m/^http/) {
                    $subschema = $self->_resolve_remote_ref($context, $ref);
                }
                else {
                    $subschema = pointer($context->{root}, $ref);
                }
            }

            if ($subschema) {
                for my $key (keys %$schema) {
                    next if $key eq 'definitions';

                    delete $schema->{$key};
                }

                foreach my $key (keys %$subschema) {
                    next if $key eq 'id';

                    $schema->{$key} = $subschema->{$key};
                }

                if ($schema->{'$ref'}) {
                    $self->_resolve_refs($context, $schema);
                }
            }
        }
    }
    elsif (_is_array($schema)) {
        foreach my $el (@$schema) {
            $self->_resolve_refs($context, $el);
        }
    }
}

sub _validate {
    my $self = shift;
    my ($context, $json, $schema) = @_;

    my $pointer = $context->{pointer};

    my $result = $self->_build_result;

    $self->_resolve_refs($context, $schema);

    if (_is_object($schema)) {
        if (my $types = $schema->{type}) {
            my $subresult = $self->_validate_type($context, $json, $types);
            $result->merge($subresult);
        }

        if (my $enum = $schema->{enum}) {
            my $subresult = $self->_validate_enum($context, $json, $enum);
            $result->merge($subresult);
        }

        if (exists $schema->{const}) {
            my $subresult = $self->_validate_const($context, $json, $schema->{const});
            $result->merge($subresult);
        }
    }

    if (_is_object($json)) {
        my $subresult = $self->_validate_object($context, $json, $schema);
        $result->merge($subresult);
    }
    elsif (_is_array($json)) {
        my $subresult = $self->_validate_array($context, $json, $schema);
        $result->merge($subresult);
    }
    elsif (_is_number($json)) {
        my $subresult = $self->_validate_number($context, $json, $schema);
        $result->merge($subresult);
    }
    elsif (_is_string($json)) {
        my $subresult = $self->_validate_string($context, $json, $schema);
        $result->merge($subresult);
    }

    if (my $subschema_type = _subschema($schema)) {
        $self->_resolve_refs($context, $schema->{$subschema_type});

        my $subresult = $self->_validate_subschemas($context, $json, $subschema_type, $schema->{$subschema_type});
        $result->merge($subresult);
    }

    if (_is_string($json)) {
        if (my $format = $schema->{format}) {
            if (my $cb = $self->{formats}->{$format}) {
                if (!$cb->($json)) {
                    $result->add_error(
                        uri       => $pointer,
                        message   => 'Must be of format ' . $format,
                        attribute => 'format',
                        details   => [$format]
                    );
                }
            }
        }
    }

    return $result;
}

sub _validate_type {
    my $self = shift;
    my ($context, $json, $types) = @_;

    my $result = $self->_build_result;

    $types = [$types] unless ref $types eq 'ARRAY';

    my @results;
    foreach my $type (@$types) {
        if (_is_object($type)) {
            my $subresult = $self->_validate($context, $json, $type);
            push @results, $subresult;
        }
        elsif (!_is_type($json, $type)) {
            push @results,
              $self->_build_result->add_error(
                uri       => $context->{pointer},
                message   => 'Must be of type ' . $type,
                attribute => 'type',
                details   => [$type]
              );
        }
        else {
            push @results, $self->_build_result;
        }
    }

    if (@results && !grep { $_->is_success } @results) {
        if (@results == 1) {
            $result->merge($results[0]);
        }
        else {
            $result->add_error(
                uri       => $context->{pointer},
                message   => "Must be one of",
                attribute => 'type',
            );
        }
    }

    return $result;
}

sub _validate_subschemas {
    my $self = shift;
    my ($context, $json, $type, $subschemas) = @_;

    my $result = $self->_build_result;

    $subschemas = [$subschemas] unless ref $subschemas eq 'ARRAY';

    my @subresults;
    foreach my $subschema (@$subschemas) {
        my $subresult = $self->_validate($context, $json, $subschema);

        push @subresults, $subresult;
    }

    my @valid = grep { $_->is_success } @subresults;

    if ($type eq 'allOf') {
        if (@valid != @subresults) {
            $result->add_error(
                uri       => $context->{pointer},
                message   => "Must be all of",
                attribute => 'allOf',
            );
        }
    }
    elsif ($type eq 'anyOf') {
        if (!@valid) {
            $result->add_error(
                uri       => $context->{pointer},
                message   => "Must be any of",
                attribute => 'anyOf',
            );
        }
    }
    elsif ($type eq 'oneOf') {
        if (@valid != 1) {
            $result->add_error(
                uri       => $context->{pointer},
                message   => "Must be one of",
                attribute => 'oneOf',
            );
        }
    }
    elsif ($type eq 'not') {
        if (@valid) {
            $result->add_error(
                uri       => $context->{pointer},
                message   => "Must not be of",
                attribute => 'not',
            );
        }
    }

    return $result;
}

sub _validate_object {
    my $self = shift;
    my ($context, $json, $schema) = @_;

    $schema = Storable::dclone($schema);

    my $result = $self->_build_result(root => $context->{pointer});

    my @required = exists $schema->{required} ? @{$schema->{required}} : ();

    if (exists $schema->{properties}) {
        foreach my $key (keys %{$schema->{properties}}) {
            push @required, $key if $schema->{properties}->{$key}->{required};
        }
    }

    if (exists $schema->{dependencies}) {
        foreach my $dependency (keys %{$schema->{dependencies}}) {
            next unless exists $json->{$dependency};

            if (_is_array($schema->{dependencies}->{$dependency})) {
                push @required, @{$schema->{dependencies}->{$dependency}};
            }
            elsif (_is_object($schema->{dependencies}->{$dependency})) {
                my $dependency_schema = $schema->{dependencies}->{$dependency};

                foreach my $key (keys %$dependency_schema) {
                    if ($key eq 'required') {
                        push @required, @{$dependency_schema->{$key}};
                    }
                    else {
                        $schema->{$key} = $dependency_schema->{$key};
                    }
                }
            }
        }
    }

    if (defined(my $min_properties = $schema->{minProperties})) {
        if (keys %$json < $min_properties) {
            $result->add_error(
                uri       => $context->{pointer},
                message   => "Must have minimum " . $min_properties . ' property(ies)',
                attribute => 'minProperties',
                details   => [$min_properties]
            );
        }
    }

    if (defined(my $max_properties = $schema->{maxProperties})) {
        if (keys %$json > $max_properties) {
            $result->add_error(
                uri       => $context->{pointer},
                message   => "Must have maximum " . $max_properties . ' property(ies)',
                attribute => 'maxProperties',
                details   => [$max_properties]
            );
        }
    }

    if (@required) {
        foreach my $name (@required) {
            if (!exists $json->{$name}) {
                $result->add_error(
                    uri       => "$context->{pointer}/$name",
                    message   => 'Required',
                    attribute => 'required',
                    details   => ['(true)']
                );
            }
        }
    }

    my @additional_properties = grep { !exists $schema->{properties}->{$_} } keys %$json;

    if (exists $schema->{additionalProperties}) {
        if (_is_boolean($schema->{additionalProperties}) && !$schema->{additionalProperties}) {
          PROPERTY: foreach my $additional_property (@additional_properties) {
                if (my $pattern_properties = $schema->{patternProperties}) {
                    foreach my $pattern_property (keys %$pattern_properties) {
                        next PROPERTY if $additional_property =~ m/$pattern_property/;
                    }
                }

                $result->add_error(
                    uri     => "$context->{pointer}/$additional_property",
                    message => 'Unknown property',
                );
            }
        }
        elsif (_is_object($schema->{additionalProperties})) {
          ADDITIONAL_PROPERTY: foreach my $additional_property (@additional_properties) {

                # patternProperties overwrite additionalProperties
                if (my $pattern_properties = $schema->{patternProperties}) {
                    foreach my $pattern_property (keys %$pattern_properties) {
                        next ADDITIONAL_PROPERTY if $additional_property =~ m/$pattern_property/;
                    }
                }

                my $subresult = $self->_validate(
                    {%$context, pointer => "$context->{pointer}/$additional_property"},
                    $json->{$additional_property},
                    $schema->{additionalProperties}
                );
                $result->merge($subresult);
            }
        }
    }

    if (my $properties = $schema->{properties}) {
        foreach my $name (keys %$properties) {
            if (exists $json->{$name}) {
                my $subresult = $self->_validate({%$context, pointer => "$context->{pointer}/$name"},
                    $json->{$name}, $properties->{$name});
                $result->merge($subresult);
            }
        }
    }

    if (_is_object($schema->{patternProperties})) {
        foreach my $pattern_property (keys %{$schema->{patternProperties}}) {
            my @matched_properties = grep { m/$pattern_property/ } keys %$json;

            foreach my $property (@matched_properties) {
                my $subresult = $self->_validate({%$context, pointer => "$context->{pointer}/$property"},
                    $json->{$property}, $schema->{patternProperties}->{$pattern_property});
                $result->merge($subresult);
            }
        }
    }

    return $result;
}

sub _validate_array {
    my $self = shift;
    my ($context, $json, $schema) = @_;

    my $result = $self->_build_result(root => $context->{pointer});

    if (defined(my $min_items = $schema->{minItems})) {
        if (@$json < $min_items) {
            $result->add_error(
                uri       => $context->{pointer},
                message   => "Must have minimum " . $min_items . ' item(s)',
                attribute => 'minItems',
                details   => [$min_items],
            );
        }
    }

    if (defined(my $max_items = $schema->{maxItems})) {
        if (@$json > $max_items) {
            $result->add_error(
                uri       => $context->{pointer},
                message   => "Must have maximum " . $max_items . ' item(s)',
                attribute => 'maxItems',
                details   => [$max_items],
            );
        }
    }

    if (_is_array($schema->{items})) {
        my $exp_length = @{$schema->{items}};
        my $got_length = @$json;

        for (my $i = 0; $i < @{$schema->{items}}; $i++) {
            last if @$json < $i + 1;

            my $subresult =
              $self->_validate({%$context, pointer => "$context->{pointer}\[$i]"}, $json->[$i], $schema->{items}->[$i]);
            $result->merge($subresult);
        }

        if ($got_length > $exp_length) {
            if (_is_boolean($schema->{additionalItems})) {
                if (!$schema->{additionalItems}) {
                    $result->add_error(
                        uri       => $context->{pointer},
                        message   => "Must have exactly " . @{$schema->{items}} . ' item(s)',
                        attribute => 'additionalItems',
                        details   => [scalar @{$schema->{items}}]

                    );
                }
            }
            elsif (_is_object($schema->{additionalItems})) {
                for ($exp_length .. $got_length - 1) {
                    my $subresult = $self->_validate({%$context, pointer => "$context->{pointer}\[$_]"},
                        $json->[$_], $schema->{additionalItems});
                    $result->merge($subresult);
                }
            }
        }
    }

    if (_is_object($schema->{items})) {
        for (my $i = 0; $i < @$json; $i++) {
            my $subresult =
              $self->_validate({%$context, pointer => "$context->{pointer}/$i"}, $json->[$i], $schema->{items});
            $result->merge($subresult);
        }
    }

    if ($schema->{uniqueItems}) {
        my $seen = {};
        foreach my $el (@$json) {
            my $hash = ref $el ? JSON::encode_json($el) : defined $el ? $el : 'null';

            if (exists $seen->{$hash}) {
                $result->add_error(
                    uri       => $context->{pointer},
                    message   => "Must have unique items",
                    attribute => 'uniqueItems',
                    details   => ['(true)']
                );
                last;
            }
            $seen->{$hash}++;
        }
    }

    if ($schema->{contains}) {
        if (!@$json) {
            $result->add_error(
                uri       => $context->{pointer},
                message   => "Must not be empty",
                attribute => 'contains'
            );
        }
    }

    return $result;
}

sub _validate_string {
    my $self = shift;
    my ($context, $json, $schema) = @_;

    my $result = $self->_build_result(pointer => $context->{pointer});

    if (defined(my $max_length = $schema->{maxLength})) {
        if (length($json) > $max_length) {
            $result->add_error(
                uri       => $context->{pointer},
                message   => "Must have the maximum length of $max_length",
                attribute => 'maxLength',
                details   => [$max_length]
            );
        }
    }

    if (defined(my $min_length = $schema->{minLength})) {
        if (length($json) < $min_length) {
            $result->add_error(
                uri       => $context->{pointer},
                message   => "Must have the minimum length of $min_length",
                attribute => 'minLength',
                details   => [$min_length]
            );
        }
    }

    if (my $pattern = $schema->{pattern}) {
        if ($json !~ m/$pattern/) {
            $result->add_error(
                uri       => $context->{pointer},
                message   => "Must match pattern $pattern",
                attribute => 'pattern',
                details   => ["$pattern"]
            );
        }
    }

    return $result;
}

sub _validate_number {
    my $self = shift;
    my ($context, $json, $schema) = @_;

    my $result = $self->_build_result(pointer => $context->{pointer});

    if (defined(my $minimum = $schema->{minimum})) {
        if ($schema->{exclusiveMinimum}) {
            if ($json <= $minimum) {
                $result->add_error(
                    uri       => $context->{pointer},
                    message   => "Must be greater than or equals to $minimum",
                    attribute => 'minimum',
                    details   => [$minimum]
                );
            }
        }
        else {
            if ($json < $minimum) {
                $result->add_error(
                    uri       => $context->{pointer},
                    message   => "Must be greater than $minimum",
                    attribute => 'minimum',
                    details   => [$minimum]
                );
            }
        }
    }

    if (_is_number($schema->{exclusiveMaximum})) {
        my $maximum = $schema->{exclusiveMaximum};

        if ($json >= $maximum) {
            $result->add_error(
                uri       => $context->{pointer},
                message   => "Must be less than or equals to $maximum",
                attribute => 'maximum',
                details   => [$maximum]
            );
        }
    }

    if (defined(my $maximum = $schema->{maximum})) {
        if ($schema->{exclusiveMaximum}) {
            if ($json >= $maximum) {
                $result->add_error(
                    uri       => $context->{pointer},
                    message   => "Must be less than or equals to $maximum",
                    attribute => 'maximum',
                    details   => [$maximum]
                );
            }
        }
        else {
            if ($json > $maximum) {
                $result->add_error(
                    uri       => $context->{pointer},
                    message   => "Must be less than $maximum",
                    attribute => 'maximum',
                    details   => [$maximum]
                );
            }
        }
    }

    if (defined(my $divisibleBy = $schema->{divisibleBy})) {
        if (sprintf('%0.6f', $json) ne sprintf('%0.6f', int($json / $divisibleBy) * $divisibleBy)) {
            $result->add_error(
                uri       => $context->{pointer},
                message   => "Must be divisible by $divisibleBy",
                attribute => 'divisibleBy',
                details   => [$divisibleBy]
            );
        }
    }

    if (defined(my $multipleOf = $schema->{multipleOf})) {
        if (sprintf('%0.6f', $json) ne sprintf('%0.6f', int($json / $multipleOf) * $multipleOf)) {
            $result->add_error(
                uri       => $context->{pointer},
                message   => "Must be multiple of by $multipleOf",
                attribute => 'multipleOf',
                details   => [$multipleOf]
            );
        }
    }

    return $result;
}

sub _validate_enum {
    my $self = shift;
    my ($context, $json, $enum) = @_;

    my $result = $self->_build_result(pointer => $context->{pointer});

    my $set = {};
    foreach my $el (@$enum) {
        my $hash = ref $el ? JSON::encode_json($el) : $el;
        $set->{$hash} = 1;
    }

    my $hash = ref $json ? JSON::encode_json($json) : defined $json ? $json : 'null';

    if (!exists $set->{$hash}) {
        $result->add_error(
            uri       => $context->{pointer},
            message   => "Must be one of",
            attribute => 'enum',
            details   => [@$enum]
        );
    }

    return $result;
}

sub _validate_const {
    my $self = shift;
    my ($context, $json, $const) = @_;

    my $result = $self->_build_result();

    my $exp_type = _type($const);

    if (_is_type($json, $exp_type) || ($exp_type eq 'integer' && _type($json) eq 'number')) {
        if (_is_object($json) || _is_array($json)) {
            if (JSON->new->utf8->canonical->encode($json) ne JSON->new->utf8->canonical->encode($const)) {
                $result->add_error(
                    uri       => $context->{pointer},
                    message   => "Must be equal to const",
                    attribute => 'const',
                );
            }
        }
        elsif (_is_number($json)) {
            if (sprintf('%0.6f', $const) ne sprintf('%0.6f', $json)) {
                $result->add_error(
                    uri       => $context->{pointer},
                    message   => "Must be of equal to $const",
                    attribute => 'const',
                    details   => [$const]
                );
            }
        }
        elsif (_is_string($json)) {
            if ($json ne $const) {
                $result->add_error(
                    uri       => $context->{pointer},
                    message   => "Must be of equal to $const",
                    attribute => 'const',
                    details   => [$const]
                );
            }
        }
        elsif (_is_boolean($json)) {
            if ($const != $json) {
                $result->add_error(
                    uri       => $context->{pointer},
                    message   => "Must be of equal to $const",
                    attribute => 'const',
                    details   => [$const]
                );
            }
        }
    }
    else {
        $result->add_error(
            uri       => $context->{pointer},
            message   => "Must be of type $exp_type",
            attribute => 'const',
            details   => [$exp_type]
        );
    }

    return $result;
}

sub _is_object {
    my ($value) = @_;

    return defined $value && ref $value eq 'HASH';
}

sub _is_array {
    my ($value) = @_;

    return defined $value && ref $value eq 'ARRAY';
}

sub _is_boolean {
    my ($value) = @_;

    return defined $value && JSON::is_bool($value);
}

sub _is_number {
    my ($value) = @_;

    return 0 unless defined $value;
    return 0 if ref $value;
    return 0 if JSON::is_bool($value);

    my $b_obj = B::svref_2object(\$value);
    my $flags = $b_obj->FLAGS;
    return 1
      if $flags & (B::SVp_IOK() | B::SVp_NOK())
      && !($flags & B::SVp_POK());

    return 0;
}

sub _is_integer {
    my ($value) = @_;

    return 0 unless defined $value;
    return 0 if ref $value;
    return 0 if JSON::is_bool($value);

    my $b_obj = B::svref_2object(\$value);
    my $flags = $b_obj->FLAGS;
    return 1 if ($flags & B::SVp_IOK()) && !($flags & B::SVp_POK());

    return 0;
}

sub _is_string {
    my ($value) = @_;

    return 0 unless defined $value;
    return 0 if ref $value;
    return 0 if _is_boolean($value);
    return 0 if _is_number($value);

    return 1;
}

sub _is_null {
    my ($value) = @_;

    return defined $value ? 0 : 1;
}

sub _is_type {
    my ($value, $type) = @_;

    my $real_type = _type($value);

    if ($type eq 'number') {
        return 1 if $real_type eq 'integer';
    }

    return $real_type eq $type;

    return _type($value) eq $type ? 1 : 0;
}

sub _type {
    my ($value) = @_;

    return 'null'    if _is_null($value);
    return 'object'  if _is_object($value);
    return 'array'   if _is_array($value);
    return 'boolean' if _is_boolean($value);
    return 'integer' if _is_integer($value);
    return 'number'  if _is_number($value);
    return 'string'  if _is_string($value);

    Carp::croak("Unknown type");
}

sub _subschema {
    my ($schema) = @_;

    for (qw/allOf anyOf oneOf not/) {
        return $_ if $schema->{$_};
    }

    return;
}

sub _resolve_remote_ref {
    my $self = shift;
    my ($context, $ref) = @_;

    my ($url, $pointer) = $ref =~ m/^([^#]+)(#.*)?$/;

    my $schema;

    if (exists $context->{ids}->{$url}) {
        $schema = $context->{ids}->{$url};
    }
    elsif ($context->{remote_cache}->{$url}) {
        $schema = $context->{remote_cache}->{$url};
    }
    else {
        $schema = eval { $self->{fetcher}->($url) };
        $context->{remote_cache}->{$url} = $schema;

        if ($schema) {
            $schema->{id} //= $url;

            $self->_collect_ids($context, $schema);
        }
    }

    if ($schema && $pointer) {
        $schema = pointer($schema, $pointer);
    }

    return $schema;
}

sub _build_result {
    my $self = shift;

    return JSON::SchemaValidator::Result->new;
}

1;
__END__

=head1 NAME

JSON::SchemaValidator - JSON Schema Validator

=head1 SYNOPSIS

    my $validator = JSON::SchemaValidator->new;

    my $result = $validator->validate([1], {type => 'object'});

    if (!$result->is_success) {
        #  [
        #    {
        #        uri       => '#',
        #        message   => "Must be of type object",
        #        attribute => 'type',
        #        details   => ['object']
        #    }
        #  ]

        return $result->errors;
    }

=head1 DESCRIPTION

L<JSON::SchemaValidator> is a JSON schema validator.

=head1 DEVELOPMENT

=head2 Repository

    http://github.com/vti/json-schemavalidator

=head1 CREDITS

=head1 AUTHOR

Viacheslav Tykhanovskyi, C<vti@cpan.org>.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2020, Viacheslav Tykhanovskyi

This program is free software, you can redistribute it and/or modify it under
the terms of the Artistic License version 2.0.

=cut
