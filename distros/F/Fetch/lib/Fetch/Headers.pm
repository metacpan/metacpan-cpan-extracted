package Fetch::Headers;

use strict;
use warnings;

our $VERSION = '0.15';

require Fetch;

1;

__END__

=head1 NAME

Fetch::Headers - ordered, case-insensitive, multi-valued HTTP headers

=head1 SYNOPSIS

    my $h = $res->headers;              # a Fetch::Headers
    my $ct = $h->get('content-type');   # first value, case-insensitive
    my @sc = $h->get_all('set-cookie'); # every value, in order

    my $req = Fetch::Headers->new(Accept => 'application/json');
    $req->add('X-Trace' => 'a');
    $req->add('X-Trace' => 'b');        # repeatable header kept twice

    # still behaves as the old [k, v, k, v, ...] arrayref
    my @flat = @$h;

=head1 DESCRIPTION

A small container for HTTP header fields. Field names compare
case-insensitively; insertion order and duplicate names are preserved (so
C<Set-Cookie> and other repeatable fields survive intact). The object is a
blessed arrayref of a flat C<name =E<gt> value> list, so code that treated
C<< $res->headers >> as a C<[k, v, ...]> arrayref keeps working.

=head1 METHODS

=head2 new(%pairs | \@pairs | \%hash | $headers)

Build from a flat name/value list, an arrayref of pairs, a hashref, or another
Fetch::Headers.

=head2 get($name) / get_all($name)

The first value for C<$name>, or every value in order.

=head2 set($name, @values) / add($name, $value) / remove($name)

Replace, append, or delete a field.

=head2 exists($name) / names / pairs / clone

Membership test; the distinct field names in order; the flat name/value list;
a shallow copy.

=head2 merge($other)

Overlay another header set: each name it carries replaces this object's values
for that name.

=head1 AUTHOR

LNATION C<< <email@lnation.org> >>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION. This is free software, licensed
under the Artistic License 2.0.

=cut
