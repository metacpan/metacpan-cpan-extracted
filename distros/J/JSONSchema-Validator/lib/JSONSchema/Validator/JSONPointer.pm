package JSONSchema::Validator::JSONPointer;

# ABSTRACT: JSON Pointer with URI resolving

use strict;
use warnings;
use URI;
use Carp 'croak';

use Scalar::Util 'weaken';

use overload
    'bool' => sub { $_[0]->value },
    fallback => 1;

our @ISA = 'Exporter';
our @EXPORT_OK = qw(json_pointer);

sub json_pointer {
    return __PACKAGE__;
}

sub append {
    my ($class, $path, @values) = @_;
    my $suffix = join('/', map { $class->escape($_) } @values);
    return $path =~ m!/$!
        ? $path . $suffix
        : $path . '/' . $suffix;
}

sub join {
    my ($class, @parts) = @_;
    return '/' . join('/', map { $class->escape($_) } @parts);
}

sub escape {
    my ($class, $value) = @_;
    $value =~ s!~!~0!g;
    $value =~ s!/!~1!g;
    return $value;
}

sub unescape {
    my ($class, $value) = @_;
    $value =~ s!~1!/!g;
    $value =~ s!~0!~!g;
    return $value;
}

sub new {
    my ($class, %params) = @_;

    my ($scope, $value, $validator) = @params{qw/scope value validator/};

    croak 'JSONPointer: scope is required' unless defined $scope;
    croak 'JSONPointer: validator is required' unless $validator;

    weaken($validator);

    my $self = {
        scope => $scope,
        value => $value,
        validator => $validator
    };

    bless $self, $class;

    return $self;
}

sub validator { shift->{validator} }
sub scope { shift->{scope} }
sub value { shift->{value} }

sub xget {
    my ($self, @parts) = @_;

    my $current_scope = $self->scope;
    my $current_value = $self->value;

    while (ref $current_value eq 'HASH' && $current_value->{'$ref'}) {
        my $ref = URI->new($current_value->{'$ref'});
        $ref = $ref->abs($current_scope) if $current_scope;
        ($current_scope, $current_value) = $self->validator->resolver->resolve($ref);
    }

    if (ref $current_value eq 'HASH' && $self->validator->using_id_with_ref) {
        my $id = $current_value->{$self->validator->ID_FIELD};
        if ($id && !ref $id) {
            $current_scope = $current_scope
                ? URI->new($id)->abs($current_scope)->as_string
                : $id;
        }
    }

    for my $part (@parts) {
        if (ref $current_value eq 'HASH' && exists $current_value->{$part}) {
            $current_value = $current_value->{$part};
        } elsif (ref $current_value eq 'ARRAY' && $part =~ m/^\d+$/ && scalar(@$current_value) > $part) {
            $current_value = $current_value->[$part];
        } else {
            $current_value = undef;
            last;
        }

        while (ref $current_value eq 'HASH' && $current_value->{'$ref'}) {
            my $ref = URI->new($current_value->{'$ref'});
            $ref = $ref->abs($current_scope) if $current_scope;
            ($current_scope, $current_value) = $self->validator->resolver->resolve($ref);
        }

        if (ref $current_value eq 'HASH' && $self->validator->using_id_with_ref) {
            my $id = $current_value->{$self->validator->ID_FIELD};
            if ($id && !ref $id) {
                $current_scope = $current_scope
                    ? URI->new($id)->abs($current_scope)->as_string
                    : $id;
            }
        }
    }

    return __PACKAGE__->new(
        value => $current_value,
        scope => $current_scope,
        validator => $self->validator
    )
}

sub get {
    # pointer is string which is already urldecoded and utf8-decoded
    my ($self, $pointer) = @_;
    return $self unless $pointer;

    croak "Invalid JSON Pointer $pointer" unless $pointer =~ s!^/!!;

    my @parts = length $pointer
                    ? map { $self->unescape($_) } split(/\//, $pointer, -1)
                    : ('');

    return $self->xget(@parts);
}

sub keys {
    my ($self, %params) = @_;
    my $raw = $params{raw} // 0;

    if (ref $self->value eq 'HASH') {
        return map { $raw ? $_ : $self->join($_) } keys %{$self->value};
    }

    if (ref $self->value eq 'ARRAY') {
        return map { $raw ? $_ : $self->join($_) } 0 .. $#{$self->value};
    }

    return;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

JSONSchema::Validator::JSONPointer - JSON Pointer with URI resolving

=head1 VERSION

version 0.008

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
