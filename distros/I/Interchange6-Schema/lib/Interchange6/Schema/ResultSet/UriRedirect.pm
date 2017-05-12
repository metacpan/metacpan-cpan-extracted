use utf8;

package Interchange6::Schema::ResultSet::UriRedirect;

=head1 NAME

Interchange6::Schema::ResultSet::UriRedirect

=cut

=head1 SYNOPSIS

Provides extra accessor methods for L<Interchange6::Schema::Result::UriRedirect>

=cut

use strict;
use warnings;
use mro 'c3';

use parent 'Interchange6::Schema::ResultSet';

=head1 METHODS

=head2 redirect( $source_uri )

Find L<Interchange6::Schema::Result::UriRedirect/uri_source> and check
for circular redirects. In the event that a non-circular chain of redirects
is found the last item found is returned.

Returns depend on what is found:

=over 4

=item C<$source_uri> is not found

Returns undef.

=item Circular redirect found

Returns undef.

=item Normal redirect found

Returns the corresponding
L<Interchange6::Schema::Result::UriRedirect/uri_target> and
L<Interchange6::Schema::Result::UriRedirect/status_code> as an array
in list context or as an array reference in scalar context.

=back

=cut

sub redirect {
    my $self       = shift;
    my $uri_source = shift;

    my $result = $self->find( { uri_source => $uri_source } );

    return undef unless defined $result;

    while ( my $next = $self->find( { uri_source => $result->uri_target } ) )
    {
        # return on circular redirect
        return undef if $uri_source eq $next->uri_target;
        $result = $next;
    }

    my @ret = ( $result->uri_target, $result->status_code );

    return wantarray ? @ret : \@ret;
}

1;
