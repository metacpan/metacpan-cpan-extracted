package JSON::Schema::Fast::Compiled;

use strict;
use warnings;

our $VERSION = '0.09';

1;

__END__

=head1 NAME

JSON::Schema::Fast::Compiled - a compiled JSON Schema validator object

=head1 DESCRIPTION

Returned by C<< JSON::Schema::Fast->compile >>. Holds the arena IR for one
schema and validates Perl data against it. All behaviour lives in XS; see
L<JSON::Schema::Fast> for compiling and the option list.

=head1 METHODS

=head2 is_valid

    my $bool = $v->is_valid($data);

A fast boolean: true if C<$data> is valid. Short-circuits on the first failure
and allocates nothing on the valid path.

=head2 validate

    my $bool           = $v->validate($data);   # scalar context
    my ($ok, $errors)  = $v->validate($data);   # list context: (1) or (0, \@errors)

In list context returns C<(1)> when valid, or C<(0, \@errors)> when not. In
scalar context returns the boolean.

=head2 errors

    my $errors = $v->errors($data);   # arrayref, empty when valid

Each error is a hashref with C<instanceLocation> and C<schemaLocation> (RFC 6901
JSON Pointers), the failing C<keyword>, and a C<message>. See
L<JSON::Schema::Fast/ERRORS>.

=head2 engine

Returns C<'interp'> (the interpreter engine).

=head2 schema

Returns the (normalised) schema this object was compiled from.

=head1 AUTHOR

LNATION <email@lnation.org>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION. This is free software, licensed
under the Artistic License 2.0 (GPL Compatible).

=cut
