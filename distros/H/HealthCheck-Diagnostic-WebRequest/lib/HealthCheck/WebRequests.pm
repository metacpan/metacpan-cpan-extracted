package HealthCheck::WebRequests;
use parent 'HealthCheck';

# ABSTRACT: Make HTTP/HTTPS requests to web servers to check connectivity
use version;
our $VERSION = 'v1.4.3'; # VERSION

use strict;
use warnings;

use Carp;
use HealthCheck::Diagnostic::WebRequest;
use Scalar::Util 'blessed';

sub new {
    my ($class, @params) = @_;

    my %params = @params == 1 && ( ref $params[0] || '' ) eq 'HASH'
        ? %{ $params[0] } : @params;

    my @bad_params = grep {
        !/^(  checks
            | content_regex
            | id
            | label
            | no_follow_redirects
            | options
            | response_time_threshold
            | status_code
            | status_code_eval
            | runbook
            | tags
            | timeout
            | ua
        )$/x
    } keys %params;

    carp("Invalid parameter: " . join(", ", @bad_params)) if @bad_params;

    croak "No checks specified!" unless $params{checks};

    my %default_params = %params;
    delete $default_params{checks};
    $params{default_params} = \%default_params;

    return $class->SUPER::new(
        label => 'web_requests',
        %params,
    );
}

sub register {
    my ( $self, @checks ) = @_;
    @checks = @{ $checks[0] } if @checks == 1 && ( ref $checks[0] || '' ) eq 'ARRAY';

    for my $check (@checks) {
        if ( ( ref $check || '' ) eq 'HASH' ) {
            $check = HealthCheck::Diagnostic::WebRequest->new( %{ $self->{default_params} }, %$check );
        }

        croak "Invalid check. Checks must either be a hashref or HealthCheck::Diagnostic::WebRequest"
            unless blessed $check
            and $check->isa("HealthCheck::Diagnostic::WebRequest");
    }

    return $self->SUPER::register(@checks);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

HealthCheck::WebRequests - Make HTTP/HTTPS requests to web servers to check connectivity

=head1 VERSION

version v1.4.3

=head1 SYNOPSIS

    use HealthCheck::WebRequests;

    my $healthcheck = HealthCheck::WebRequests->new(
        checks => [
            {
                id    => 'foo',
                tags  => ['foo'],
                label => 'foo',
                url   => 'https://foo.example',
                # Any other valid args for HealthCheck::Diagnostic::WebRequest
            },
            HealthCheck::Diagnostic::WebRequest->new(...), # the top-level shared args do not apply to HealthCheck::Diagnostic::WebRequest instances
        ],
        # These args apply to all hashrefs in checks
        tags      => ['default_tag'],
        label     => 'default_label',
    );

    my $healthcheck2 = HealthCheck::WebRequests->new(
        checks => [
            {
                url   => 'https://foo.example',
                # tags        = ['default_tag']
                # label       = 'default_label'
                # status_code = '200'
            },
            {
                url   => 'https://bar.example',
                # tags        = ['default_tag']
                # label       = 'default_label'
                # status_code = '200'
            },
            HealthCheck::Diagnostic::WebRequest->new(...), # the top-level shared args do not apply to HealthCheck::Diagnostic::WebRequest instances
        ],
        # These args apply to all hashrefs in checks
        tags        => ['default_tag'],
        label       => 'default_label',
        status_code => '200',
    );

=head1 DESCRIPTION

A L<HealthCheck> that groups multiple L<HealthCheck::Diagnostic::WebRequest>.

=head1 ATTRIBUTES

=head2 checks

An arrayref of hashrefs, where each hashref should contain valid arguments to instantiate a
L<HealthCheck::Diagnostic::WebRequest> object. Alternatively,
L<HealthCheck::Diagnostic::WebRequest> objects or subclasses can be directly provided instead of hashrefs.

=head1 SHARED ATTRIBUTES

These attributes, if supplied, are used to override the defaults for each hashref in the L<checks>. These will
not apply to any L<HealthCheck::Diagnostic::WebRequest> objects in L<checks>.

See the documentation in L<HealthCheck::Diagnostic::WebRequest> for more details on them.

=over

=item status_code

=item response_time_threshold

=item content_regex

=item no_follow_redirects

=item ua

=item options

=back

=head1 DEPENDENCIES

L<HealthCheck>
L<HealthCheck::Diagnostic::WebRequest>
L<LWP::UserAgent>

=head1 CONFIGURATION AND ENVIRONMENT

None

=head1 AUTHOR

Grant Street Group <developers@grantstreet.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 - 2024 by Grant Street Group.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
