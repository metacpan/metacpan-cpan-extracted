package Interchange::Search::Solr::Response;

use strict;
use warnings;
use Any::Moose;
extends 'WebService::Solr::Response';

=head1 NAME

Interchange::Search::Solr::Response

=head2 DESCRIPTION

L<WebService::Solr::Response> subclass for error handling.

=head2 METHODS/ACCESSORS

In addition to all the L<WebService::Solr::Response> methods this
class have the following methods:

=head3 error

An error string.

=head3 is_empty_search

Error code is C<empty_search>.

=cut

has error => (is => 'rw');

sub is_empty_search {
    my $self = shift;
    if (my $error = $self->error) {
        return $error eq 'empty_search';
    }
    return 0;
}


1;

