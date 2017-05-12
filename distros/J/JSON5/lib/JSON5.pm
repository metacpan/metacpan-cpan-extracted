package JSON5;
use 5.008001;
use strict;
use warnings;

our $VERSION = "0.01";

use Exporter 'import';
our @EXPORT = qw/decode_json5/;

use JSON::PP;
use JSON5::Parser;

my $JSON5; # cache

sub decode_json5 { ($JSON5 ||= JSON5->new->utf8)->decode(@_) }

sub new {
    my $class = shift;
    return bless {
        parser => JSON5::Parser->new,
    } => $class;
}

sub true;
sub false;
*true  = \&JSON::PP::true;
*false = \&JSON::PP::false;

# define accessors
BEGIN {
    for my $attr (qw/utf8 allow_nonref max_size inflate_boolean inflate_nan inflate_null inflate_infinity/) {
        my $attr_accessor = sub {
            my $self = shift;
            $self->{parser}->$attr(@_);
            return $self;
        };
        my $attr_getter = sub {
            my $self = shift;
            my $get_attr = "get_$attr";
            return $self->{parser}->$get_attr;
        };

        no strict qw/refs/;
        *{"$attr"}     = $attr_accessor;
        *{"get_$attr"} = $attr_getter;
    }
}

sub decode {
    my $self = shift;
    return $self->{parser}->parse(@_);
}

1;
__END__

=encoding utf-8

=for stopwords utf8 mutators arrayrefs hashrefs

=head1 NAME

JSON5 - The JSON5 implementation for Perl 5

=head1 SYNOPSIS

    use JSON5;

    my $object = decode_json5('{$ref:"#"}');
    # { '$ref' => "#" }

=head1 DESCRIPTION

JSON5 is the JSON5 implementation for Perl 5

=head1 FUNCTIONAL INTERFACE

Some documents are copied and modified from L<JSON::PP/FUNCTIONAL INTERFACE>.

=head2 decode_json5

    $perl_scalar = decode_json5 $json_text

expects an UTF-8 (binary) string and tries to parse that as
an UTF-8 encoded JSON5 text, returning the resulting reference.

This function call is functionally identical to:

    $perl_scalar = JSON5->new->utf8->decode($json_text)

=head1 METHODS

Some documents are copied and modified from L<JSON5::PP/METHODS>.

=head2 new

    $json5 = JSON5->new

Returns a new JSON5 object that can be used to decode JSON5
strings.

All boolean flags described below are by default I<disabled>.

The mutators for flags all return the JSON5 object again and thus calls can
be chained:

   my $object = JSON5->new->utf8->allow_nonref->decode("true")
   => JSON::PP::true

=head2 utf8

    $json5 = $json5->utf8([$enable])
    
    $enabled = $json5->get_utf8

If $enable is true (or missing), then the decode method expects to be handled
an UTF-8-encoded string. Please note that UTF-8-encoded strings do not contain any
characters outside the range 0..255, they are thus useful for bytewise/binary I/O.

(In Perl 5.005, any character outside the range 0..255 does not exist.
See to L<UNICODE HANDLING ON PERLS>.)

In future versions, enabling this option might enable auto-detection of the UTF-16 and UTF-32
encoding families, as described in RFC4627.

If $enable is false, then the decode expects thus a Unicode string. Any decoding
(e.g. to UTF-8 or UTF-16) needs to be done yourself, e.g. using the Encode module.

Example, decode UTF-32LE-encoded JSON5:

  use Encode;
  $object = JSON5->new->decode (decode "UTF-32LE", $json5text);

=head2 allow_nonref

    $json5 = $json5->allow_nonref([$enable])
    
    $enabled = $json5->get_allow_nonref

If C<$enable> is true (or missing), then the C<decode> method will accept a
non-reference into its corresponding string, number or null JSON5 value,
which is an extension to RFC4627.

If C<$enable> is false, then the C<decode> method will croak if
given something that is not a JSON5 object or array.

=head2 max_size

    $json5 = $json5->max_size([$maximum_string_size])
    
    $max_size = $json5->get_max_size

Set the maximum length a JSON5 text may have (in bytes) where decoding is
being attempted. The default is C<0>, meaning no limit. When C<decode>
is called on a string that is longer then this many bytes, it will not
attempt to decode the string but throw an exception.

If no argument is given, the limit check will be deactivated (same as when
C<0> is specified).

=head2 decode

    $perl_scalar = $json5->decode($json5_text)

JSON5 numbers and strings become simple Perl scalars. JSON5 arrays become
Perl arrayrefs and JSON5 objects become Perl hashrefs. C<true> becomes
C<1> (C<JSON::PP::true>), C<false> becomes C<0> (C<JSON::PP::false>),
C<NaN> becomes C<'NaN'>, C<Infinity> becomes C<'Inf'>, and
C<null> becomes C<undef>.

=head1 SEE ALSO

L<JSON::PP>

=head1 LICENSE

Copyright (C) karupanerura.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

karupanerura E<lt>karupa@cpan.orgE<gt>

=cut

