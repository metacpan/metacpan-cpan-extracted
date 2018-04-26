use strict;
use warnings;

package HTTP::Tiny::UA::Response;
# ABSTRACT: Wrap HTTP::Tiny response as objects with accessors

our $VERSION = '0.006';

# Declare custom accessor before Class::Tiny loads
use subs 'headers';

use Class::Tiny 1.000 qw( success url status reason content protocol headers );

#pod =attr success
#pod
#pod =attr url
#pod
#pod =attr protocol
#pod
#pod =attr status
#pod
#pod =attr reason
#pod
#pod =attr content
#pod
#pod =attr headers
#pod
#pod =method header
#pod
#pod     $response->header( "Content-Length" );
#pod
#pod Return a header out of the headers hash.  The field is case-insensitive.  If
#pod the header was repeated, the value returned will be an array reference.
#pod Otherwise it will be a scalar value.
#pod
#pod =cut

# Don't return the original hash reference because the caller could
# alter that referred-to hash, which in turn would alter this object's
# internals, which we almost certainly do not want!
sub headers {
    my ($self) = @_;

    my $headers = $self->{headers};
    my %copy;

    while ( my ( $k, $v ) = each %$headers ) {
        $copy{$k} = ref($v) eq 'ARRAY' ? [@$v] : $v;
    }

    return \%copy;
}

sub header {
    my ( $self, $field ) = @_;

    # NB: lc() can potentially use non-English (e.g., Turkish)
    # lowercasing logic, which we very likely do not want here.
    $field =~ tr/A-Z/a-z/;

    # We don't return the original array reference for the same reason
    # why headers() doesn't return the original hash reference.
    my $hdr = $self->{headers}{$field};

    return ref($hdr) eq 'ARRAY' ? [@$hdr] : $hdr;
}

1;


# vim: ts=4 sts=4 sw=4 et:

__END__

=pod

=encoding UTF-8

=head1 NAME

HTTP::Tiny::UA::Response - Wrap HTTP::Tiny response as objects with accessors

=head1 VERSION

version 0.006

=head1 SYNOPSIS

    my $res = HTTP::Tiny::UA->new->get( $url );

    if ( $res->success ) {
        say "Got " . $res->header("Content-Length") . " bytes";
    }

=head1 DESCRIPTION

This module wraps an L<HTTP::Tiny> response as an object to provide some
accessors and convenience methods.

=head1 ATTRIBUTES

=head2 success

=head2 url

=head2 protocol

=head2 status

=head2 reason

=head2 content

=head2 headers

=head1 METHODS

=head2 header

    $response->header( "Content-Length" );

Return a header out of the headers hash.  The field is case-insensitive.  If
the header was repeated, the value returned will be an array reference.
Otherwise it will be a scalar value.

=for Pod::Coverage BUILD

=head1 AUTHOR

David Golden <dagolden@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2013 by David Golden.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
