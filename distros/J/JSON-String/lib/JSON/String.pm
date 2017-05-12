use strict;
use warnings;

package JSON::String;

use Carp qw(croak);
our @CARP_NOT = qw(JSON::String::BaseHandler JSON::String::HASH JSON::String::ARRAY);
use JSON;

use JSON::String::ARRAY;
use JSON::String::HASH;

our $VERSION = '0.2.0'; # VERSION

sub tie {
    my($class, $string) = @_;
    my $ref = \$_[1];

    my $data = _validate_string_ref($ref);
    return _construct_object($data, $ref);
}

sub _construct_object {
    my($data, $str_ref, $encoder) = @_;

    croak('Either string ref or encoder sub expected, not both') if ($str_ref and $encoder);

    return $data unless ref $data;

    $encoder = _create_encoder($data, $str_ref) unless $encoder;

    my $self;
    if (ref($data) eq 'ARRAY') {
        foreach my $elt ( @$data ) {
            $elt = _construct_object($elt, undef, $encoder);
        }
        $self = [];
        CORE::tie @$self, 'JSON::String::ARRAY', data => $data, encoder => $encoder;
    } elsif (ref($data) eq 'HASH') {
        foreach my $key ( keys %$data ) {
            $data->{$key} = _construct_object($data->{$key}, undef, $encoder);
        }
        $self = {};
        CORE::tie %$self, 'JSON::String::HASH', data => $data, encoder => $encoder;
    }

    return $self;
}

{
    my $codec = JSON->new->canonical;
    sub codec {
        shift;
        if (@_) {
            $codec = shift;
        }
        return $codec;
    }
}

sub _create_encoder {
    my($data, $str_ref) = @_;

    my $codec = codec;
    return sub {
        my $val;
        my $error = do {
            local $@;
            $val = eval { $$str_ref = $codec->encode($data) };
            $@;
        };
        croak("Error encoding data structure: $error") if $error;
        return $val;
    };
}

sub _validate_string_ref {
    my $ref = shift;

    unless (ref $ref eq 'SCALAR') {
        croak q(Expected plain string, but got reference);
    }
    unless (defined $$ref) {
        croak('Expected string, but got <undef>');
    }
    unless (length $$ref) {
        croak('Expected non-empty string');
    }

    my $data = codec()->decode($$ref);

    unless (ref($data) eq 'ARRAY' or ref($data) eq 'HASH') {
        croak('Cannot handle '.ref($data).' reference');
    }
    return $data;
}

1;

=pod

=head1 NAME

JSON::String - Automatically change a JSON string when a data structure changes

=head1 SYNOPSIS

  # Basic use
  my $json_string = q({ a: 1, b: 2, c: [ 4, 5, 6 ] });
  my $data = JSON::String->tie($json_string);
  @{$data->{c}} = qw(this data changed);
  # $json_string now contains '{ a: 1, b: 2, c: ["this", "data", "changed"] }'

  # Useful when the JSON gets saved somewhere more permanent
  my $object = load_object_from_database();
  my $decoded_struct = JSON::String->tie($object->{json_attribute});
  possibly_change_data($decoded_struct);  # json_attribute will change if the struct changes
  save_object_to_database($object) if ($object->has_changes);

=head1 DESCRIPTION

This module constructs a data structure from a JSON string that, when changed,
automatically changes the original string's contents to match the new data.
Hashrefs and arrayrefs are supported, and their values can be scalars,
hashrefs or arrayrefs.  This is useful in cases where the JSON string is
persisted in a database, and needs to be updated if the underlying data
ever changes.

The JSON format does not handle recursive data, and an exception will be
thrown if the data structure is changed such that it has a loop.

=head1 CONSTRUCTOR

  my $data = JSON::String->tie($json_string);

Returns either a hashref or arrayref, depending on the input JSON string.
The string passed in must by valid JSON encoding either an arrayref or
hashref, otherwise it will throw an exception.

The returned data structure is tied to the string such that when the data
changes, the JSON string stored in the variable will be changed to reflect
the new data.  If the string changes, the data structure will _not_ change.

=head2 Methods

=over 4

=item JSON::String->codec();  # returns a JSON instance

=item JSON::String->codec($obj);

Get or change the JSON codec object.  The initial codec is created with
    JSON->new->canonical()

Any object can be used as the codec as long as it has C<encode()> and
C<decode()> methods.  A data structure's codec does not change after it
is created.  If the class's codec changes after creation, the data structure
will continue to use whatever codec was active when it was created.

=back

=head2 Mechanism

This module uses Perl's C<tie()> mechanism to perform its magic.  The hash-
and arrayrefs that make up the returned data structure are references to tied
hashes and arrays.  When their data changes, the top-level data structure is
re-encoded and stored back in the original variable.

=head2 Diagnostics

Error conditions are signalled with exceptions.

=over 4

=item Error encoding data structure: %s

The codec's encode() method threw an exception when encoding the data structure.

=item Cannot handle %s reference

JSON::String->tie() was passed a string that did not decode to either a
hashref or arrayref.

=item Expected plain string, but got reference

JSON::String->tie() was passed a reference to something instead of a string.

=item Expected string, but got <undef>

JSON::String->tie() was passed undef instead of a string.

=item Expected non-empty string

JSON::String->tie() was passed an empty string.

=back

=head1 SEE ALSO

L<JSON::String::ARRAY>, L<JSON::String::HASH>, L<JSON>

=head1 AUTHOR

Anthony Brummett <brummett@cpan.org>

=head1 COPYRIGHT

Copyright 2015, Anthony Brummett.  This module is free software. It may
be used, redistributed and/or modified under the same terms as Perl itself.

=cut
