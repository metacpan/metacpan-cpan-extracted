package JSONSchema::Validator::Constraints::Draft6;

# ABSTRACT: JSON Schema Draft6 specification constraints

use strict;
use warnings;

use JSONSchema::Validator::JSONPointer 'json_pointer';
use JSONSchema::Validator::Error 'error';
use JSONSchema::Validator::Util qw(is_type serialize unbool);

use parent 'JSONSchema::Validator::Constraints::Draft4';

# params: $self, $value, $type, $strict
sub check_type {
    if ($_[2] eq 'integer') {
        return is_type($_[1], 'number', $_[3] // $_[0]->strict) && int($_[1]) == $_[1];
    }
    return is_type($_[1], $_[2], $_[3] // $_[0]->strict);
}

sub exclusiveMaximum {
    my ($self, $instance, $exclusiveMaximum, $schema, $instance_path, $schema_path, $data) = @_;
    return 1 unless $self->check_type($instance, 'number');

    return 1 if $instance < $exclusiveMaximum;

    push @{$data->{errors}}, error(
        message => "${instance} is equal or greater than ${exclusiveMaximum}",
        instance_path => $instance_path,
        schema_path => $schema_path
    );
    return 0;
}

sub exclusiveMinimum {
    my ($self, $instance, $exclusiveMinimum, $schema, $instance_path, $schema_path, $data) = @_;
    return 1 unless $self->check_type($instance, 'number');

    return 1 if $instance > $exclusiveMinimum;

    push @{$data->{errors}}, error(
        message => "${instance} is equal or less than ${exclusiveMinimum}",
        instance_path => $instance_path,
        schema_path => $schema_path
    );
    return 0;
}

sub propertyNames {
    my ($self, $instance, $propertyNames, $schema, $instance_path, $schema_path, $data) = @_;
    return 1 unless $self->check_type($instance, 'object');

    my $result = 1;
    for my $p (keys %$instance) {
        my $ipath = json_pointer->append($instance_path, $p);
        my $r = $self->validator->_validate_schema($p, $propertyNames, $ipath, $schema_path, $data);
        $result = 0 unless $r;
    }
    return $result;
}

sub contains {
    my ($self, $instance, $contains, $schema, $instance_path, $schema_path, $data) = @_;
    return 1 unless $self->check_type($instance, 'array');

    my $errors = $data->{errors};
    my $local_errors = [];

    my $result = 0;
    for my $idx (0 .. $#{$instance}) {
        $data->{errors} = [];
        my $ipath = json_pointer->append($instance_path, $idx);
        $result = $self->validator->_validate_schema($instance->[$idx], $contains, $ipath, $schema_path, $data);
        unless ($result) {
            push @{$local_errors}, error(
                message => qq'${idx} part of "contains" has errors',
                context => $data->{errors},
                instance_path => $ipath,
                schema_path => $schema_path
            );
        }
        last if $result;
    }
    $data->{errors} = $errors;
    return 1 if $result;

    push @{$data->{errors}}, error(
        message => 'No elems of instance satisfy schema of "contains"',
        context => $local_errors,
        instance_path => $instance_path,
        schema_path => $schema_path
    );
    return 0;
}

sub const {
    my ($self, $instance, $const, $schema, $instance_path, $schema_path, $data) = @_;

    my $result = 0;

    # schema must have strict check
    if ($self->check_type($const, 'boolean', 1)) {
        $result = $self->check_type($instance, 'boolean')
                    ? unbool($instance) eq unbool($const)
                    : 0
    } elsif ($self->check_type($const, 'object', 1) || $self->check_type($const, 'array', 1)) {
        $result =   $self->check_type($instance, 'object') ||
                    $self->check_type($instance, 'array')
                    ? serialize($instance) eq serialize($const)
                    : 0;
    } elsif ($self->check_type($const, 'number', 1)) {
        $result =   $self->check_type($instance, 'number')
                    ? $const == $instance
                    : 0;
    } elsif (defined $const && defined $instance) {
        $result = $const eq $instance;
    } elsif (!defined $const && !defined $instance) {
        $result = 1;
    }

    return 1 if $result;

    push @{$data->{errors}}, error(
        message => "instance is not equal const",
        instance_path => $instance_path,
        schema_path => $schema_path
    );
    return 0;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

JSONSchema::Validator::Constraints::Draft6 - JSON Schema Draft6 specification constraints

=head1 VERSION

version 0.010

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
