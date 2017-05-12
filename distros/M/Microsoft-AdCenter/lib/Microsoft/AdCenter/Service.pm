package Microsoft::AdCenter::Service;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

=head1 NAME

Microsoft::AdCenter::Service - Base class for service client modules.

=cut

=head1 SYNOPSIS

This module is not intended to be used directly.  Documentation for each of the service client is in the appropriate module.

=cut

use base qw/Class::Accessor::Chained Microsoft::AdCenter/;

use Data::Dumper;
use Encode qw/is_utf8 _utf8_on/;
use Scalar::Util qw/blessed/;
use SOAP::Lite;

use Microsoft::AdCenter::Retry;
use Microsoft::AdCenter::SOAPFault;

__PACKAGE__->mk_accessors(qw/
    EndPoint
    RetrySettings
/);

sub new {
    my ($class, %args) = @_;

    my $self = bless {}, $class;

    $self->EndPoint((defined $args{EndPoint}) ? $args{EndPoint} : $self->_default_location);
    $self->RetrySettings($args{RetrySettings});

    my $request_headers = $self->_request_headers_expanded;
    foreach my $header_name (keys %$request_headers) {
        if (defined $args{$header_name}) {
            $self->$header_name($args{$header_name});
        }
    }

    my $namespace_uri = $self->_namespace_uri;
    my $namespace = $namespace_uri;
    $namespace =~ s/\/$//;
    $namespace =~ s/^.*\///;

    $self->{_soap} = SOAP::Lite
        ->proxy($self->EndPoint)
        ->ns($namespace_uri, $namespace);

    $self->{_namespaces} = {
        $namespace_uri => $namespace
    };

    $self->{_type_category} = {};
    $self->{_type_namespace} = {};
    $self->{_type_full_names} = {};

    return $self;
}

sub _invoke {
    my ($self, %args) = @_;

    my $soap_action = $args{soap_action};
    my $request_name = $args{request}->{name};
    my $request_headers = $self->_request_headers;
    my $request_parameters = $args{request}->{parameters};
    my $response_name = $args{response}->{name};
    my $response_headers = $self->_request_headers;
    my $response_headers_expanded = $self->_response_headers_expanded;
    my $parameter_values = $args{parameters};

    # Reset the response headers
    foreach my $header_name (keys %$response_headers_expanded) {
        $self->$header_name(undef);
    }

    # Setup the SOAP client
    my $soap = $self->{_soap};
    $soap->proxy($self->EndPoint);
    $soap->on_action(sub { $soap_action });

    # Create request headers
    my @soap_header;
    foreach my $header (@$request_headers) {
        my $header_ns = $header->{namespace};
        my $header_name = $header->{name};
        my $header_type = $header->{type};
        my $type_category = $self->_type_category($header_type);
        my $header_value = ($type_category eq 'COMPLEX') ? $self->_populate_complex_type($header_type) : $self->$header_name;
        push @soap_header, $self->_serialize_argument("SOAP::Header", $header_ns, $header_name, $header_value, $header_type, 0);
    }

    # Create request body
    my @soap_body;
    foreach my $request_parameter (@$request_parameters) {
        my $request_parameter_ns = $request_parameter->{namespace};
        my $request_parameter_name = $request_parameter->{name};
        my $request_parameter_type = $request_parameter->{type};
        my $parameter_value = $parameter_values->{$request_parameter_name};
        push @soap_body, $self->_serialize_argument("SOAP::Data", $request_parameter_ns, $request_parameter_name, $parameter_value, $request_parameter_type, 1);
    }

    my $retries = 0;
    while (1) {
        my $result;
        eval {
            # Call the actual web service
            my $som = $soap->call($request_name, @soap_header, @soap_body);

            # Check for HTTP 400's errors (which we can't recover from)
            if ($soap->transport->proxy->code =~ /^4[0-9]{2}$/) {
                die $soap->transport->proxy->status . " for " . $soap->transport->proxy->endpoint;
            }

            # Store the response header values in the service client
            $self->_store_response_headers($som, $response_headers, $response_headers_expanded);

            # If it fails, die with a SOAPFault object
            if ($som->fault) {
                my $fault = Microsoft::AdCenter::SOAPFault->new
                    ->faultcode($som->faultcode)
                    ->faultstring($som->faultstring);

                my $faultdetail = $som->faultdetail;
                if (defined $faultdetail) {
                    if (ref $faultdetail eq 'HASH') {
                        $faultdetail = $self->_deserialize_array($faultdetail);
                        if (scalar(@$faultdetail) == 1) {
                            $fault->detail($faultdetail->[0]);
                        }
                        elsif (scalar(@$faultdetail) > 1) {
                            $fault->detail($faultdetail);
                        }
                    }
                    else {
                        $fault->detail($faultdetail);
                    }
                }
                die $fault;
            }

            # Parse the response body
            my $response_body = $som->body;
            if (defined $response_body) {
                die "Type mismatch" unless (exists $response_body->{$response_name});
                $result = $self->_deserialize_complex_type($response_name, $response_body->{$response_name});
            }
        };
        if (my $e = $@) {
            die $e unless ((defined $self->RetrySettings) && ref($self->RetrySettings) eq 'ARRAY');

            my $retry_times = undef;
            my $wait_time = undef;
            my $scaling_wait_time = undef;
            my $should_retry = 0;

            foreach my $retry_settings ( @{$self->RetrySettings} ) {
                die "Invalid Retry setting" if (ref($retry_settings) ne 'Microsoft::AdCenter::Retry');
                next unless ($retry_settings->match($e));

                $should_retry = 1;

                if ((not defined $retry_times) && (defined $retry_settings->RetryTimes)) {
                    $retry_times = $retry_settings->RetryTimes;
                }

                if ((not defined $wait_time) && (defined $retry_settings->WaitTime)) {
                    $wait_time = $retry_settings->WaitTime;
                }

                if ((not defined $scaling_wait_time) && (defined $retry_settings->ScalingWaitTime)) {
                    $scaling_wait_time = $retry_settings->ScalingWaitTime;
                }

                $retry_settings->Callback->($e) if (defined $retry_settings->Callback);
            }

            die $e unless $should_retry;

            $retry_times = 0 unless (defined $retry_times);
            $wait_time = 1 unless (defined $wait_time);
            $scaling_wait_time = 1 unless (defined $scaling_wait_time);

            if ($retries < $retry_times) {
                sleep($wait_time + ($wait_time * $retries * ($scaling_wait_time - 1)));
                $retries++;
            }
            else {
                die $e;
            }
        }
        else {
            return $result;
        }
    }
}

# Store the response header values in the service client
sub _store_response_headers {
    my ($self, $som, $response_headers, $response_headers_expanded) = @_;

    my $response_header_values = $som->header;
    my $expanded_response_headers = {};
    foreach my $header (@$response_headers) {
        my $header_name = $header->{name};
        my $header_value = $response_header_values->{$header_name};
        next unless defined $header_value;
        my $header_type = $header->{type};
        my $header_type_category = $self->_type_category($header_type);
        if ($header_type_category eq 'COMPLEX') {
            $self->_expand_complex_type(
                $self->_deserialize_complex_type($header_type, $header_value),
                $expanded_response_headers
            );
        }
        elsif ($header_type_category eq 'ARRAY') {
            $expanded_response_headers->{$header_name} = $self->_deserialize_array($header_value);
        }
        else {
            $expanded_response_headers->{$header_name} = $header_value;
        }
    }
    foreach my $header_name (keys %$response_headers_expanded) {
        $self->$header_name($expanded_response_headers->{$header_name});
    }
}

sub _serialize_argument {
    my ($self, $type, $namespace, $name, $value, $value_type, $min_occurs) = @_;

    my $prefix = $self->_get_namespace_prefix($namespace);
    my $type_namespace = $self->_type_namespace($value_type);
    my $type_full_name = $self->_type_full_name($value_type);
    my $object = eval($type . '->type($type_full_name)');
    $object->prefix($prefix);

    if (not defined $value) {
        if ($min_occurs > 0) {
            $object = $object->attr({'xsi:nil' => "true"});
        }
        else {
            $object = undef;
        }
    }
    elsif (ref($value) eq 'ARRAY') {
        my %array_types = $self->_array_types;
        die "Type mismatch" unless (exists $array_types{$value_type});
        if (scalar(@$value) > 0) {
            my $element_name = $array_types{$value_type}->{element_name};
            my $element_type = $array_types{$value_type}->{element_type};
            my @elements = map { $self->_serialize_argument($type, $type_namespace, $element_name, $_, $element_type, 1) } @$value;
            $object = $object->value(\eval($type . '->value(@elements)'));
        }
    }
    elsif (blessed($value) and $value->UNIVERSAL::isa('Microsoft::AdCenter::ComplexType')) {
        die "Type mismatch" unless $value->UNIVERSAL::isa(ref($self) . '::' . $value_type);
        if ($value_type ne $value->_type_name) {
            $value_type = $value->_type_name;
            $type_namespace = $self->_type_namespace($value_type);
            $type_full_name = $self->_type_full_name($value_type);
            $object->type($type_full_name);
        }

        my @attributes =
            grep { defined $_ }
                map { $self->_serialize_argument($type, $type_namespace, $_, $value->$_, $value->_attribute_type($_), $value->_attribute_min_occurs($_)) }
                    $value->_attributes;

        $object = $object->value(\eval($type . '->value(@attributes)')) if (scalar(@attributes) > 0);
    }
    else {
        $object = $object->value($value);
    }

    return undef unless (defined $object);
    return $object->name($name);
}

sub _get_namespace_prefix {
    my ($self, $uri) = @_;
    my $namespaces = $self->{_namespaces};
    unless (exists $namespaces->{$uri}) {
        $namespaces->{$uri} = 'ns' . (scalar(keys %$namespaces));
        $self->{_soap}->serializer->register_ns($uri, $namespaces->{$uri});
    }
    return $namespaces->{$uri};
}

sub _type_category {
    my ($self, $type_name) = @_;
    my $type_category = $self->{_type_category};
    unless (exists $type_category->{$type_name}) {
        my %simple_types = $self->_simple_types;
        my %complex_types = map { $_ => 1 } $self->_complex_types;
        my %array_types = $self->_array_types;
        if (exists $simple_types{$type_name}) {
            $type_category->{$type_name} = 'SIMPLE';
        }
        elsif (exists $complex_types{$type_name}) {
            $type_category->{$type_name} = 'COMPLEX';
        }
        elsif (exists $array_types{$type_name}) {
            $type_category->{$type_name} = 'ARRAY';
        }
        else {
            $type_category->{$type_name} = 'PRIMITIVE';
        }
    }
    return $type_category->{$type_name};
}

sub _type_namespace {
    my ($self, $type_name) = @_;
    my $type_namespace = $self->{_type_namespace};
    unless (exists $type_namespace->{$type_name}) {
        my $type_category = $self->_type_category($type_name);
        if ($type_category eq 'SIMPLE') {
            my %simple_types = $self->_simple_types;
            $type_namespace->{$type_name} = $simple_types{$type_name};
        }
        elsif ($type_category eq 'COMPLEX') {
            my $class_name = ref($self) . '::' . $type_name;
            my $namespace_uri = eval(qq/use ${class_name}; ${class_name}::_namespace_uri()/);
            $type_namespace->{$type_name} = $namespace_uri;
        }
        elsif ($type_category eq 'ARRAY') {
            my %array_types = $self->_array_types;
            $type_namespace->{$type_name} = $array_types{$type_name}->{namespace_uri};
        }
        else {
            $type_namespace->{$type_name} = undef;
        }
    }
    return $type_namespace->{$type_name};
}

sub _type_full_name {
    my ($self, $type_name) = @_;
    my $type_full_names = $self->{_type_full_names};
    unless (exists $type_full_names->{$type_name}) {
        my $type_namespace = $self->_type_namespace($type_name);
        if (defined $type_namespace) {
            my $prefix = $self->_get_namespace_prefix($type_namespace);
            $type_full_names->{$type_name} = $prefix . ':' . $type_name;
        }
        else {
            $type_full_names->{$type_name} = $type_name;
        }
    }
    return $type_full_names->{$type_name};
}

sub _create_complex_type {
    my ($self, $type) = @_;
    my $class_name = ref($self) . '::' . $type;
    my $object = eval("use $class_name; $class_name->new");
    die $@ if $@;
    return $object;
}

sub _deserialize_array {
    my ($self, $value) = @_;
    return [] unless ((defined $value) && ref($value) eq 'HASH');
    my @arr;
    foreach my $element_type (keys %$value) {
        my $element_type_category = $self->_type_category($element_type);
        my $element_values = (ref $value->{$element_type} eq 'ARRAY') ? $value->{$element_type} : [$value->{$element_type}];
        foreach my $element_value (@$element_values) {
            if ($element_type_category eq 'COMPLEX') {
                push @arr, $self->_deserialize_complex_type($element_type, $element_value);
            }
            elsif ($element_type_category eq 'ARRAY') {
                push @arr, $self->_deserialize_array($element_value);
            }
            else {
                push @arr, $element_value;
            }
        }
    }
    return \@arr;
}

sub _deserialize_complex_type {
    my ($self, $type, $value) = @_;
    return unless defined $value;
    $type = ref($value) if (length(ref($value)) > 0 && ref($value) ne 'HASH');
    my $object = $self->_create_complex_type($type);
    foreach my $attribute_name ($object->_attributes) {
        my $attribute_value = $value->{$attribute_name};
        next unless defined $attribute_value;
        my $attribute_type = $object->_attribute_type($attribute_name);
        my $type_category = $self->_type_category($attribute_type);
        if ($type_category eq 'COMPLEX') {
            $attribute_value = $self->_deserialize_complex_type($attribute_type, $attribute_value);
        }
        elsif ($type_category eq 'ARRAY') {
            $attribute_value = $self->_deserialize_array($attribute_value);
        }
        $object->$attribute_name($attribute_value);
    }
    return $object;
}

sub _populate_complex_type {
    my ($self, $type) = @_;
    my $object = $self->_create_complex_type($type);
    foreach my $attribute_name ($object->_attributes) {
        my $attribute_type = $object->_attribute_type($attribute_name);
        my $type_category = $self->_type_category($attribute_type);
        my $value = undef;
        if ($type_category eq 'COMPLEX') {
            $value = $self->_populate_complex_type($attribute_type);
        }
        else {
            $value = $self->$attribute_name;
        }
        $object->$attribute_name($value);
    }
    return $object;
}

sub _expand_complex_type {
    my ($self, $value, $result) = @_;
    foreach my $attribute_name ($value->_attributes) {
        my $attribute_type = $value->_attribute_type($attribute_name);
        my $type_category = $self->_type_category($attribute_type);
        if ($type_category eq 'COMPLEX') {
            $self->_expand_complex_type($value->$attribute_name, $result);
        }
        else {
            $result->{$attribute_name} = $value->$attribute_name;
        }
    }
}

1;
