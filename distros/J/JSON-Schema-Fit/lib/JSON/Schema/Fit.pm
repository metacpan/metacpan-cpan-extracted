package JSON::Schema::Fit;
$JSON::Schema::Fit::VERSION = '0.03';
# ABSTRACT: adjust data structure according to json-schema


use 5.010;
use strict;
use warnings;
use utf8;

use Carp;

use JSON;
use Scalar::Util qw/reftype/;
use List::Util qw/first/;
use Math::Round qw/round nearest/;


sub booleans { return _attr('booleans', @_); }


sub numbers { return _attr('numbers', @_); }



sub round_numbers { return _attr('round_numbers', @_); }



sub strings { return _attr('strings', @_); }


sub hash_keys { return _attr('hash_keys', @_); }

# Store valid options as well as default values
my %valid_option = ( map { ($_ => 1) } qw!booleans numbers round_numbers strings hash_keys! );

sub new { 
    my ($class, %opts) = @_;
    my $self = bless {}, $class;
    for my $k (keys %opts) {
        next unless exists $valid_option{$k};
        _attr($k, $self, $opts{$k});
    }
    return $self
}

sub _attr {
    my $attr = shift;
    my $self = shift;

    if (@_) {
        return $self->{$attr} = shift;
    } else {
        return $self->{$attr} //= $valid_option{$attr};
    }
}


sub get_adjusted {
    my ($self, $struc, $schema, $jpath) = @_;

    return $struc  if !ref $schema || reftype $schema ne 'HASH';
    my $method = $self->_adjuster_by_type($schema->{type});
    return $struc  if !$method;
    return $self->$method($struc, $schema, $jpath);
}


sub _adjuster_by_type {
    my ($self, $type) = @_;

    return if !$type;
    my $method = "_get_adjusted_$type";
    return $method if $self->can($method);
    return;
}


sub _get_adjusted_boolean {
    my ($self, $struc, $schema, $jpath) = @_;

    return $struc if !$self->booleans();
    return JSON::true if $struc;
    return JSON::false;
}


sub _get_adjusted_integer {
    my ($self, $struc, $schema, $jpath) = @_;

    return $struc  if !$self->numbers();
    my $result = $self->_get_adjusted_number($struc, $schema, $jpath);
    return round($result);
}


sub _get_adjusted_number {
    my ($self, $struc, $schema, $jpath) = @_;

    return $struc  if !$self->numbers();
    my $result = 0+$struc;

    return $result if !$self->round_numbers();
    my $quantum = $schema->{multipleOf} || $schema->{divisibleBy};
    return $result if !$quantum;
    return nearest $quantum, $result;
}


sub _get_adjusted_string {
    my ($self, $struc, $schema, $jpath) = @_;

    return $struc  if !$self->strings();
    return "$struc";
}


sub _get_adjusted_array {
    my ($self, $struc, $schema, $jpath) = @_;

    croak "Structure is not ARRAY at $jpath"  if reftype $struc ne 'ARRAY';

    my $result = [];
    for my $i ( 0 .. $#$struc ) {
        push @$result, $self->get_adjusted($struc->[$i], $schema->{items}, $self->_jpath($jpath, $i));
    }

    return $result;
}



sub _get_adjusted_object {
    my ($self, $struc, $schema, $jpath) = @_;

    croak "Structure is not HASH at $jpath"  if reftype $struc ne 'HASH';

    my $result = {};
    my $keys_re;

    my $properties = $schema->{properties} || {};
    my $p_properties = $schema->{patternProperties} || {};

    if ($self->hash_keys() && exists $schema->{additionalProperties} && !$schema->{additionalProperties}) {
        my $keys_re_text = join q{|}, (
            keys %$p_properties,
            map {quotemeta} keys %$properties,
        );
        $keys_re = qr{^$keys_re_text$}x;
    }

    for my $key (keys %$struc) {
        next if $keys_re && $key !~ $keys_re;

        my $subschema = $properties->{$key};
        if (my $re_key = !$subschema && first {$key =~ /$_/x} keys %$p_properties) {
            $subschema = $p_properties->{$re_key};
        }

        $result->{$key} = $self->get_adjusted($struc->{$key}, $subschema, $self->_jpath($jpath, $key));
    }

    return $result;
}


sub _jpath {
    my ($self, $path, $key) = @_;
    $path //= q{$};

    return "$path.$key"  if $key =~ /^[_A-Za-z]\w*$/x;
    
    $key =~ s/(['\\])/\\$1/gx;
    return $path . "['$key']";
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

JSON::Schema::Fit - adjust data structure according to json-schema

=head1 VERSION

version 0.03

=head1 SYNOPSIS

    my $data = get_dirty_result();
    # raw data: got { num => "1.99999999997", flag => "1", junk => {...} }
    my $bad_json = encode_json $data;
    # {"num":"1.99999999997","flag":"1","junk":{...}}

    # JSON::Schema-compatible
    my $schema = { type => 'object', additionalProperties => 0, properties => {
        num => { type => 'integer' },
        flag => { type => 'boolean' },
    }};
    my $prepared_data = JSON::Schema::Fit->new()->get_adjusted($data, $schema);
    my $cool_json = encode_json $prepared_data;
    # {"num":2,"flag":true}

=head1 DESCRIPTION

The main goal of this package is preparing data to be encoded as json according to schema.

Actions implemented:
adjusting value type (number/string/boolean),
rounding numbers,
filtering hash keys.

=head1 ATTRIBUTES

=head2 booleans

Explicitly set type for boolean values to JSON::true / JSON::false

Default: 1

=head2 numbers

Explicitly set type for numeric and integer values

Default: 1

=head2 round_numbers

Round numbers according to 'multipleOf' schema value

Default: 1

=head2 strings

Explicitly set type for strings

Default: 1

=head2 hash_keys

Filter out not allowed hash keys (where additionalProperties is false).

Default: 1

=head1 METHODS

=head2 new

    my $jsf = JSON::Schema::Fit->new(booleans => 0);

Create a new C<JSON::Schema::Fit> instance. See bellow for valid options.

=head2 get_adjusted

Returns "semi-copy" of data structure with adjusted values. Original data is not affected.

=head1 CONSTRUCTOR

=head1 SEE ALSO

Related modules: L<JSON>, L<JSON::Schema>.

Json-schema home: L<http://json-schema.org/>

=head1 AUTHOR

liosha <liosha@yandex-team.ru>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by liosha.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
