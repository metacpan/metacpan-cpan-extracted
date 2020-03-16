package MockTransport;
# ABSTRACT: A backend for testing HTTP::AnyUA

use warnings;
use strict;

sub new { bless {}, shift }

=method response

    $response = $backend->response;
    $response = $backend->response($response);

Get and set the response hashref or L<Future> that this backend will always respond with.

=cut

sub response { @_ == 2 ? $_[0]->{response} = pop : $_[0]->{response} }

=method requests

    @requests = $backend->requests;

Get the requests the backend has handled so far.

=cut

sub requests { @{$_[0]->{requests} || []} }

sub execute {
    my $self = shift;

    push @{$self->{requests} ||= []}, [@_];

    return $self->response;
}

1;
