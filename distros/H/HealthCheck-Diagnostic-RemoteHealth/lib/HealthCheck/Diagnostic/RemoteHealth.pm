package HealthCheck::Diagnostic::RemoteHealth;
use parent 'HealthCheck::Diagnostic::WebRequest';
use strict;
use warnings;

use JSON;

# ABSTRACT: Get results from an HTTP HealthCheck
use version;
our $VERSION = 'v0.1.2'; # VERSION

sub new {
    my ($class, @params) = @_;

    my %params = @params == 1 && ( ref $params[0] || '' ) eq 'HASH'
        ? %{ $params[0] } : @params;

    # Allows 200 and 503 codes by default.
    $params{status_code} //= '200, 503';

    return $class->SUPER::new(
        id    => 'remotehealth',
        label => 'RemoteHealth',
        %params,
    );
}

sub run {
    my ($self, %params) = @_;
    my $result = $self->next::method(%params);

    # Throws away the HTTP status check if OK,
    # since it's implied to be successful
    # if it retrieves the encoded JSON object.
    if (($result->{results}->[0]->{status} || '') eq 'OK' ) {
        shift @{ $result->{results} };
        # info key is removed since it is redundant with the result-level info keys
        return { results => $result->{results} };
    }
    return $result;
}

# Checking for content regex from JSON seems unnecessary, so this has been
# repurposed to return the decoded JSON object.
sub check_content {
    my ($self, $response) = @_;

    local $@;
    my $remote_result = eval { decode_json($response->content) };
    return {
        status => 'CRITICAL',
        info   => 'Could not decode JSON.',
        data   => $response->content,
    } if $@ or ref($remote_result) ne 'HASH';

    return $remote_result;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

HealthCheck::Diagnostic::RemoteHealth - Get results from an HTTP HealthCheck

=head1 VERSION

version v0.1.2

=head1 SYNOPSIS

Returns the decoded JSON object from a HTTP HealthCheck endpoint.

    $health_check->register(
        HealthCheck::Diagnostic::RemoteHealth->new(
            url => "https://example.com/healthz",
        )
    );

=head1 DESCRIPTION

Takes in a C<url> to a HealthCheck JSON endpoint
and checks to see if a connection can be made.
If the connection fails or the JSON object cannot be decoded,
the C<status> is set to "CRITICAL".
If both the connection succeeds and the JSON object is successfully decoded,
it returns the decoded JSON object from the remote endpoint.

=head1 ATTRIBUTES

This diagnostic inherits all attributes from
L<HealthCheck::Diagnostic::WebRequest> in addition to its own.
C<status_code> is by default set to "200, 503".

=head2 url

The URL to the remote HealthCheck JSON endpoint. This typically ends in
"I</healthz>".

=head1 DEPENDENCIES

=over 4

=item *

L<HealthCheck::Diagnostic::WebRequest>

=item *

L<JSON>

=back

=head1 AUTHOR

Grant Street Group <developers@grantstreet.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2021 - 2024 by Grant Street Group.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
