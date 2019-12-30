package Interchange::Search::Solr::Response;

use strict;
use warnings;
use Moo;
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

=head3 success

Returns 1 if the operation is successful, 0 otherwise.

=cut

sub success {
    my $self = shift;
    my $status = $self->solr_status;

    unless ( defined $status ) {
        my $http_response = $self->raw_response;

        if ( $http_response->code != 200 ) {
            $status = 1;
        }
    }

    return ! $status;
}

=head3 exception_message

Checks the response for a Solr exception (e.g undefined field foobar).
If found, it returns the exception message. Otherwise it returns
the generic HTTP response message.

=cut

sub exception_message {
    my $self = shift;
    my $http_response = $self->raw_response;

    if ($http_response->code == 400) {
        # look at deserialized JSON
        my $content = $self->content;

        if (exists $content->{error}->{msg}) {
            return $content->{error}->{msg};
        }
    }
    elsif ( $self->error ) {
        return $self->error;
    }

    return $http_response->message;
}

=head3 as_string

Returns the string representation of Solr's HTTP response.

=cut

sub as_string {
    my $self = shift;
    my $http_response = $self->raw_response;

    return $http_response->as_string;
}

=head1 AUTHORS


Marco Pessotto, C<< <melmothx at gmail.com> >>

Stefan Hornburg (Racke), C<< <racke at linuxia.de> >>


=head1 LICENSE AND COPYRIGHT

Copyright 2015-2019 Marco Pessotto, Stefan Hornburg (Racke).

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1;
