package HTTP::API::DataTypeMarker;
$HTTP::API::DataTypeMarker::VERSION = '1.24';
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

Every value here is a blessed arrayref - either C<HTTP::API::DataTypeMarker::BOOL>
(from L</"xBOOLEAN($value)">) or C<HTTP::API::DataTypeMarker::CSV> (from
L</"xCSV(@values)">), referred to below by their unqualified names, C<BOOL>
and C<CSV>, for brevity - namespaced deliberately (not bare C<'BOOL'>/
C<'CSV'>) so an unrelated class of the same short name elsewhere in a
calling application can't collide with what C<kvp2json_each>/
C<kvp2str_each>'s C<ref($v) eq ...> checks are actually looking for.
C<BOOL> is recognized and unwrapped
specially by both C<kvp2json_each> and C<kvp2str_each>, since a bare Perl
scalar (C<1>, C<0>, C<"true">, ...) is always ambiguous about whether it
means a JSON boolean, a string, or a number. C<CSV> is only special-cased
by C<kvp2str_each>, which joins it into one comma-separated
C<key=value,value> instead of a key repeated per element - a
form-urlencoded-specific problem JSON doesn't have. C<kvp2json_each> has
no C<CSV> handling at all; a blessed C<CSV> arrayref satisfies Perl's
reftype-based C<ARRAY> check regardless of blessing, so it falls through
to the plain-array branch and JSON-encodes as an ordinary array
(C<xCSV(1,2,3)> becomes C<[1,2,3]>) - which is the natural JSON
representation of a list anyway.

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
form-urlencoded request instead of the default C<a=1&a=2&a=3>. Each
value is copied at call time - C<xCSV($x, $y)> then reassigning C<$x>
does not change what was already captured.

=cut

sub xCSV {
    return bless [ @_ ], 'HTTP::API::DataTypeMarker::CSV';
}

=head2 xBOOLEAN($value)

The building block every C<x*> boolean marker below is made of. Wraps
C<$value> (a plain scalar or a scalar ref) so C<kvp2json_each>/
C<kvp2str_each> unwrap and emit it verbatim instead of treating it as an
array. Use one of the named markers below rather than this directly unless
none of them fit.

A plain scalar is copied at call time, the same as C<xCSV>'s values -
C<xBOOLEAN($flag)> then reassigning C<$flag> does not change what was
already captured. Pass a scalar ref instead (C<xBOOLEAN(\$flag)>) to opt
into tracking C<$flag> live - the marker then always reflects whatever
C<$flag> currently holds when it's later read. Only a plain scalar or a
scalar ref is accepted - wrapping anything else (an arrayref, a
hashref) dies with a clear message when the marker is later encoded,
rather than silently stringifying it.

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
    return bless [ @_ ], 'HTTP::API::DataTypeMarker::BOOL';
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
