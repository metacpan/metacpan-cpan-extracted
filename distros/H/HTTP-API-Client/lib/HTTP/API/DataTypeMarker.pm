package HTTP::API::DataTypeMarker;
$HTTP::API::DataTypeMarker::VERSION = '1.10';
=head1 NAME

HTTP::API::DataTypeMarker - mark request data so it serializes as a specific
type, since Perl scalars have no native boolean and no native "comma list"

=head1 SYNOPSIS

 use HTTP::API::Client;    # re-exports everything below

 $api->post( $url, {
     enabled => xTRUE,          # JSON: true            / form: 1
     legacy  => xTrue,          # JSON/form string: "True"
     tags    => xCSV(1, 2, 3),  # form: "tags=1,2,3"
 } );

=head1 DESCRIPTION

Every value here is a blessed arrayref - either C<BOOL> (from L</"xBOOLEAN($value)">)
or C<CSV> (from L</"xCSV(@values)">) - that HTTP::API::Client's C<kvp2json_each> and
C<kvp2str_each> recognize and serialize specially instead of treating as a
plain array. Marking a value is the only way to control how it is written,
since a bare Perl scalar (C<1>, C<0>, C<"true">, ...) is always ambiguous
about whether it means a JSON boolean, a string, or a number.

=cut

use strict;
use warnings;
use base 'Exporter';

our @EXPORT = qw( xCSV xBOOLEAN
    xTRUE xFALSE
    xTrue xFalse
    xtrue xfalse
    xt__e xf___e
);

=head2 xCSV(@values)

Mark a list so it serializes as one comma-joined value instead of one
repeated key per element. C<xCSV(1, 2, 3)> becomes C<a=1,2,3> in a
form-urlencoded request instead of the default C<a=1&a=2&a=3>.

=cut

sub xCSV {
    return bless \@_, 'CSV';
}

=head2 xBOOLEAN($value)

The building block every C<x*> boolean marker below is made of. Wraps
C<$value> (a plain scalar or a scalar ref) so C<kvp2json_each>/
C<kvp2str_each> unwrap and emit it verbatim instead of treating it as an
array. Use one of the named markers below rather than this directly unless
none of them fit.

=head2 xTRUE / xFALSE

A real JSON boolean: C<true> / C<false> with no quotes in JSON output, and
C<1> / C<0> in a form-urlencoded request.

=head2 xTrue / xFalse

The literal string C<"True"> / C<"False">, quoted like any other string in
JSON, unescaped in a form-urlencoded request.

=head2 xtrue / xfalse

The literal string C<"true"> / C<"false"> (lowercase).

=head2 xt__e / xf___e

The single-character string C<"t"> / C<"f">.

=cut

sub xBOOLEAN {
    return bless \@_, 'BOOL';
}

sub xTRUE {
    return xBOOLEAN(\1);
}

sub xFALSE {
    return xBOOLEAN(\0);
}

sub xTrue {
    return xBOOLEAN('True');
}

sub xFalse {
    return xBOOLEAN('False');
}

sub xtrue {
    return xBOOLEAN('true');
}

sub xfalse {
    return xBOOLEAN('false');
}

sub xt__e {
    return xBOOLEAN('t');
}

sub xf___e {
    return xBOOLEAN('f');
}

1;
