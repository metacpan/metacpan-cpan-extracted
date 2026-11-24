package Google::Cloud::Billing::Budgets::V1beta1::BudgetServiceClient;

use strict;
use warnings;
use Moo;
use Google::gRPC::Client;
use Google::Cloud::REST::Client;
use Google::Auth;
use Carp qw(croak);

use Protobuf;
use Google::Api::Common;
use Google::Cloud::Billing::Budgets::V1beta1::BudgetModel;
use Google::Cloud::Billing::Budgets::V1beta1::BudgetService;

our $VERSION = '0.06';

has credentials => ( is => 'ro', required => 0 );
has transport   => ( is => 'rw' );

sub BUILD {
    my ($self) = @_;

    my $auth = $self->credentials;
    if (!defined $auth) {
        $auth = Google::Auth->default();
    } elsif (!eval { $auth->can('get_token') }) {
        croak 'Invalid credentials object: must implement get_token()';
    }
    my $token = $auth->get_token();

    my $target = 'billingbudgets.googleapis.com:443';
    my $t = $self->transport || 'grpc';

    if (ref($t) && eval { $t->can('call') }) {
        # Already a transport object
    } elsif (lc($t) eq 'rest') {
        my $client = Google::Cloud::REST::Client->new(
            target     => $target,
            auth_token => $token,
        );
        $self->transport($client);
    } else {
        my $client = Google::gRPC::Client->new(
            target     => $target,
            auth_token => $token,
        );
        $self->transport($client);
    }
}

sub create_budget {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Billing::Budgets::V1beta1::BudgetService::CreateBudgetRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Billing::Budgets::V1beta1::BudgetModel::Budget';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.billing.budgets.v1beta1.BudgetService/CreateBudget',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.billing.budgets.v1beta1.BudgetService',
        method         => 'CreateBudget',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}
1; # End of Google::Cloud::Billing::Budgets::V1beta1::BudgetServiceClient

__END__

=head1 NAME

Google::Cloud::Billing::Budgets::V1beta1::BudgetServiceClient - Client library for Google Cloud Services

=head1 SYNOPSIS

    use Google::Cloud::Billing::Budgets::V1beta1::BudgetServiceClient;
    use Google::Auth;

    my $auth = Google::Auth->default();

    # 1. High-performance gRPC Transport (Default)
    my $grpc_client = Google::Cloud::Billing::Budgets::V1beta1::BudgetServiceClient->new(
        credentials => $auth,
        transport   => 'grpc', # Optional: 'grpc' is default
    );

    # 2. HTTP/REST Transport
    my $rest_client = Google::Cloud::Billing::Budgets::V1beta1::BudgetServiceClient->new(
        credentials => $auth,
        transport   => 'rest',
    );

    # Execute service methods
    my $res = $grpc_client->some_method( %params );

=head1 DESCRIPTION

C<Google::Cloud::Billing::Budgets::V1beta1::BudgetServiceClient> is an auto-generated client library for Google Cloud Services.

It provides a unified client interface supporting both high-performance HTTP/2 gRPC and HTTP/REST transports, with automatic Google Cloud Application Default Credentials (ADC) resolution and typed Protocol Buffers message handling.

=head1 SOURCE

Generated from the following Protocol Buffers schemas:

=over 4

=item * C<googleapis/google/cloud/billing/budgets/v1beta1/budget_model.proto>

=item * C<googleapis/google/cloud/billing/budgets/v1beta1/budget_service.proto>



=back

=head1 CONSTRUCTOR

=head2 new

    my $client = Google::Cloud::Billing::Budgets::V1beta1::BudgetServiceClient->new(
        credentials => $auth,   # Optional: Google::Auth object (defaults to ADC)
        transport   => 'grpc', # Optional: 'grpc' (default) or 'rest'
    );

=head1 ATTRIBUTES

=head2 credentials

Returns or accepts the L<Google::Auth> credentials object.

=head2 transport

Returns or accepts the active transport object (L<Google::gRPC::Client> or L<Google::Cloud::REST::Client>).

=head1 METHODS

=head2 METHODS

The following RPC methods are available in this client:

=over 4

=item * B<create_budget>

    my $response = $client->create_budget(
        parent                   => $parent,
        budget                   => $budget,
    );

Calls the RPC method C<CreateBudget> on C<google.cloud.billing.budgets.v1beta1.BudgetService>.

Request: L<Google::Cloud::Billing::Budgets::V1beta1::BudgetService::CreateBudgetRequest>

Returns: L<Google::Cloud::Billing::Budgets::V1beta1::BudgetModel::Budget>

Parameters:

=over 4

=item * C<parent> - C<string>

=item * C<budget> - L<Google::Cloud::Billing::Budgets::V1beta1::BudgetModel::Budget>

=back

=back



=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
