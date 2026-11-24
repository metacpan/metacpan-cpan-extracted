package Google::Cloud::Chronicle::V1;

use strict;
use warnings;
use Moo;
use Google::gRPC::Client;
use Google::Cloud::REST::Client;
use Google::Auth;
use Carp qw(croak);

use Protobuf;
use Google::Api::Common;
use Google::Cloud::Chronicle::V1::SimulatedData;
use Google::Cloud::Chronicle::V1::FeaturedContentMetadata;
use Google::Cloud::Chronicle::V1::Event;
use Google::Cloud::Chronicle::V1::Instance;
use Google::Cloud::Chronicle::V1::DataAccessControl;
use Google::Cloud::Chronicle::V1::Entity;
use Google::Cloud::Chronicle::V1::BigQueryExport;
use Google::Cloud::Chronicle::V1::Rule;
use Google::Cloud::Chronicle::V1::FindingsRefinement;
use Google::Cloud::Chronicle::V1::DashboardQuery;
use Google::Cloud::Chronicle::V1::DataTable;
use Google::Cloud::Chronicle::V1::RuleExecutionError;
use Google::Cloud::Chronicle::V1::Feed;
use Google::Cloud::Chronicle::V1::ReferenceList;
use Google::Cloud::Chronicle::V1::Search;
use Google::Cloud::Chronicle::V1::DashboardChart;
use Google::Cloud::Chronicle::V1::NativeDashboard;
use Google::Cloud::Chronicle::V1::FeaturedContentNativeDashboard;

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

    my $target = 'chronicle.googleapis.com:443';
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

sub get_big_query_export {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Chronicle::V1::BigQueryExport::GetBigQueryExportRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Chronicle::V1::BigQueryExport::BigQueryExport';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.chronicle.v1.BigQueryExportService/GetBigQueryExport',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.chronicle.v1.BigQueryExportService',
        method         => 'GetBigQueryExport',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub provision_big_query_export {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Chronicle::V1::BigQueryExport::ProvisionBigQueryExportRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Chronicle::V1::BigQueryExport::BigQueryExport';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.chronicle.v1.BigQueryExportService/ProvisionBigQueryExport',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.chronicle.v1.BigQueryExportService',
        method         => 'ProvisionBigQueryExport',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub get_dashboard_chart {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Chronicle::V1::DashboardChart::GetDashboardChartRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Chronicle::V1::DashboardChart::DashboardChart';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.chronicle.v1.DashboardChartService/GetDashboardChart',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.chronicle.v1.DashboardChartService',
        method         => 'GetDashboardChart',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub get_dashboard_query {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Chronicle::V1::DashboardQuery::GetDashboardQueryRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Chronicle::V1::DashboardQuery::DashboardQuery';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.chronicle.v1.DashboardQueryService/GetDashboardQuery',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.chronicle.v1.DashboardQueryService',
        method         => 'GetDashboardQuery',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub create_data_access_label {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Chronicle::V1::DataAccessControl::CreateDataAccessLabelRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Chronicle::V1::DataAccessControl::DataAccessLabel';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.chronicle.v1.DataAccessControlService/CreateDataAccessLabel',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.chronicle.v1.DataAccessControlService',
        method         => 'CreateDataAccessLabel',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub create_data_table {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Chronicle::V1::DataTable::CreateDataTableRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Chronicle::V1::DataTable::DataTable';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.chronicle.v1.DataTableService/CreateDataTable',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.chronicle.v1.DataTableService',
        method         => 'CreateDataTable',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub get_watchlist {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Chronicle::V1::Entity::GetWatchlistRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Chronicle::V1::Entity::Watchlist';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.chronicle.v1.EntityService/GetWatchlist',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.chronicle.v1.EntityService',
        method         => 'GetWatchlist',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub get_featured_content_native_dashboard {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Chronicle::V1::FeaturedContentNativeDashboard::GetFeaturedContentNativeDashboardRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Chronicle::V1::FeaturedContentNativeDashboard::FeaturedContentNativeDashboard';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.chronicle.v1.FeaturedContentNativeDashboardService/GetFeaturedContentNativeDashboard',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.chronicle.v1.FeaturedContentNativeDashboardService',
        method         => 'GetFeaturedContentNativeDashboard',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub install_featured_content_native_dashboard {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Chronicle::V1::FeaturedContentNativeDashboard::InstallFeaturedContentNativeDashboardRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Chronicle::V1::FeaturedContentNativeDashboard::InstallFeaturedContentNativeDashboardResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.chronicle.v1.FeaturedContentNativeDashboardService/InstallFeaturedContentNativeDashboard',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.chronicle.v1.FeaturedContentNativeDashboardService',
        method         => 'InstallFeaturedContentNativeDashboard',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub fetch_service_account_for_customer {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Chronicle::V1::Feed::FetchServiceAccountForCustomerRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Chronicle::V1::Feed::FeedServiceAccount';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.chronicle.v1.FeedsService/FetchServiceAccountForCustomer',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.chronicle.v1.FeedsService',
        method         => 'FetchServiceAccountForCustomer',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub get_findings_refinement {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Chronicle::V1::FindingsRefinement::GetFindingsRefinementRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Chronicle::V1::FindingsRefinement::FindingsRefinement';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.chronicle.v1.FindingsRefinementService/GetFindingsRefinement',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.chronicle.v1.FindingsRefinementService',
        method         => 'GetFindingsRefinement',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub get_instance {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Chronicle::V1::Instance::GetInstanceRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Chronicle::V1::Instance::Instance';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.chronicle.v1.InstanceService/GetInstance',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.chronicle.v1.InstanceService',
        method         => 'GetInstance',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub create_native_dashboard {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Chronicle::V1::NativeDashboard::CreateNativeDashboardRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Chronicle::V1::NativeDashboard::NativeDashboard';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.chronicle.v1.NativeDashboardService/CreateNativeDashboard',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.chronicle.v1.NativeDashboardService',
        method         => 'CreateNativeDashboard',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub get_reference_list {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Chronicle::V1::ReferenceList::GetReferenceListRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Chronicle::V1::ReferenceList::ReferenceList';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.chronicle.v1.ReferenceListService/GetReferenceList',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.chronicle.v1.ReferenceListService',
        method         => 'GetReferenceList',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub create_rule {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Chronicle::V1::Rule::CreateRuleRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Chronicle::V1::Rule::Rule';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.chronicle.v1.RuleService/CreateRule',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.chronicle.v1.RuleService',
        method         => 'CreateRule',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub list_rule_execution_errors {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Chronicle::V1::RuleExecutionError::ListRuleExecutionErrorsRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Chronicle::V1::RuleExecutionError::ListRuleExecutionErrorsResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.chronicle.v1.RuleExecutionErrorService/ListRuleExecutionErrors',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.chronicle.v1.RuleExecutionErrorService',
        method         => 'ListRuleExecutionErrors',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub search {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Chronicle::V1::Search::SearchRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Longrunning::Operations::Operation';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.chronicle.v1.SearchService/Search',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.chronicle.v1.SearchService',
        method         => 'Search',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}
1; # End of Google::Cloud::Chronicle::V1

__END__

=head1 NAME

Google::Cloud::Chronicle::V1 - Client library for Google Cloud Services

=head1 SYNOPSIS

    use Google::Cloud::Chronicle::V1;
    use Google::Auth;

    my $auth = Google::Auth->default();

    # 1. High-performance gRPC Transport (Default)
    my $grpc_client = Google::Cloud::Chronicle::V1->new(
        credentials => $auth,
        transport   => 'grpc', # Optional: 'grpc' is default
    );

    # 2. HTTP/REST Transport
    my $rest_client = Google::Cloud::Chronicle::V1->new(
        credentials => $auth,
        transport   => 'rest',
    );

    # Execute service methods
    my $res = $grpc_client->some_method( %params );

=head1 DESCRIPTION

C<Google::Cloud::Chronicle::V1> is an auto-generated client library for Google Cloud Services.

It provides a unified client interface supporting both high-performance HTTP/2 gRPC and HTTP/REST transports, with automatic Google Cloud Application Default Credentials (ADC) resolution and typed Protocol Buffers message handling.

=head1 SOURCE

Generated from the following Protocol Buffers schemas:

=over 4

=item * C<googleapis/google/cloud/chronicle/v1/big_query_export.proto>

=item * C<googleapis/google/cloud/chronicle/v1/dashboard_chart.proto>

=item * C<googleapis/google/cloud/chronicle/v1/dashboard_query.proto>

=item * C<googleapis/google/cloud/chronicle/v1/data_access_control.proto>

=item * C<googleapis/google/cloud/chronicle/v1/data_table.proto>

=item * C<googleapis/google/cloud/chronicle/v1/entity.proto>

=item * C<googleapis/google/cloud/chronicle/v1/event.proto>

=item * C<googleapis/google/cloud/chronicle/v1/featured_content_metadata.proto>

=item * C<googleapis/google/cloud/chronicle/v1/featured_content_native_dashboard.proto>

=item * C<googleapis/google/cloud/chronicle/v1/feed.proto>

=item * C<googleapis/google/cloud/chronicle/v1/findings_refinement.proto>

=item * C<googleapis/google/cloud/chronicle/v1/instance.proto>

=item * C<googleapis/google/cloud/chronicle/v1/native_dashboard.proto>

=item * C<googleapis/google/cloud/chronicle/v1/reference_list.proto>

=item * C<googleapis/google/cloud/chronicle/v1/rule.proto>

=item * C<googleapis/google/cloud/chronicle/v1/rule_execution_error.proto>

=item * C<googleapis/google/cloud/chronicle/v1/search.proto>

=item * C<googleapis/google/cloud/chronicle/v1/simulated_data.proto>



=back

=head1 CONSTRUCTOR

=head2 new

    my $client = Google::Cloud::Chronicle::V1->new(
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

=item * B<get_big_query_export>

    my $response = $client->get_big_query_export(
        name                     => $name,
    );

Calls the RPC method C<GetBigQueryExport> on C<google.cloud.chronicle.v1.BigQueryExportService>.

Request: L<Google::Cloud::Chronicle::V1::BigQueryExport::GetBigQueryExportRequest>

Returns: L<Google::Cloud::Chronicle::V1::BigQueryExport::BigQueryExport>

Parameters:

=over 4

=item * C<name> - C<string>

=back

=item * B<provision_big_query_export>

    my $response = $client->provision_big_query_export(
        parent                   => $parent,
    );

Calls the RPC method C<ProvisionBigQueryExport> on C<google.cloud.chronicle.v1.BigQueryExportService>.

Request: L<Google::Cloud::Chronicle::V1::BigQueryExport::ProvisionBigQueryExportRequest>

Returns: L<Google::Cloud::Chronicle::V1::BigQueryExport::BigQueryExport>

Parameters:

=over 4

=item * C<parent> - C<string>

=back

=item * B<get_dashboard_chart>

    my $response = $client->get_dashboard_chart(
        name                     => $name,
    );

Calls the RPC method C<GetDashboardChart> on C<google.cloud.chronicle.v1.DashboardChartService>.

Request: L<Google::Cloud::Chronicle::V1::DashboardChart::GetDashboardChartRequest>

Returns: L<Google::Cloud::Chronicle::V1::DashboardChart::DashboardChart>

Parameters:

=over 4

=item * C<name> - C<string>

=back

=item * B<get_dashboard_query>

    my $response = $client->get_dashboard_query(
        name                     => $name,
    );

Calls the RPC method C<GetDashboardQuery> on C<google.cloud.chronicle.v1.DashboardQueryService>.

Request: L<Google::Cloud::Chronicle::V1::DashboardQuery::GetDashboardQueryRequest>

Returns: L<Google::Cloud::Chronicle::V1::DashboardQuery::DashboardQuery>

Parameters:

=over 4

=item * C<name> - C<string>

=back

=item * B<create_data_access_label>

    my $response = $client->create_data_access_label(
        parent                   => $parent,
        data_access_label        => $data_access_label,
        data_access_label_id     => $data_access_label_id,
    );

Calls the RPC method C<CreateDataAccessLabel> on C<google.cloud.chronicle.v1.DataAccessControlService>.

Request: L<Google::Cloud::Chronicle::V1::DataAccessControl::CreateDataAccessLabelRequest>

Returns: L<Google::Cloud::Chronicle::V1::DataAccessControl::DataAccessLabel>

Parameters:

=over 4

=item * C<parent> - C<string>

=item * C<data_access_label> - L<Google::Cloud::Chronicle::V1::DataAccessControl::DataAccessLabel>

=item * C<data_access_label_id> - C<string>

=back

=item * B<create_data_table>

    my $response = $client->create_data_table(
        parent                   => $parent,
        data_table               => $data_table,
        data_table_id            => $data_table_id,
    );

Calls the RPC method C<CreateDataTable> on C<google.cloud.chronicle.v1.DataTableService>.

Request: L<Google::Cloud::Chronicle::V1::DataTable::CreateDataTableRequest>

Returns: L<Google::Cloud::Chronicle::V1::DataTable::DataTable>

Parameters:

=over 4

=item * C<parent> - C<string>

=item * C<data_table> - L<Google::Cloud::Chronicle::V1::DataTable::DataTable>

=item * C<data_table_id> - C<string>

=back

=item * B<get_watchlist>

    my $response = $client->get_watchlist(
        name                     => $name,
    );

Calls the RPC method C<GetWatchlist> on C<google.cloud.chronicle.v1.EntityService>.

Request: L<Google::Cloud::Chronicle::V1::Entity::GetWatchlistRequest>

Returns: L<Google::Cloud::Chronicle::V1::Entity::Watchlist>

Parameters:

=over 4

=item * C<name> - C<string>

=back

=item * B<get_featured_content_native_dashboard>

    my $response = $client->get_featured_content_native_dashboard(
        name                     => $name,
    );

Calls the RPC method C<GetFeaturedContentNativeDashboard> on C<google.cloud.chronicle.v1.FeaturedContentNativeDashboardService>.

Request: L<Google::Cloud::Chronicle::V1::FeaturedContentNativeDashboard::GetFeaturedContentNativeDashboardRequest>

Returns: L<Google::Cloud::Chronicle::V1::FeaturedContentNativeDashboard::FeaturedContentNativeDashboard>

Parameters:

=over 4

=item * C<name> - C<string>

=back

=item * B<install_featured_content_native_dashboard>

    my $response = $client->install_featured_content_native_dashboard(
        name                     => $name,
        featured_content_native_dashboard => $featured_content_native_dashboard,
    );

Calls the RPC method C<InstallFeaturedContentNativeDashboard> on C<google.cloud.chronicle.v1.FeaturedContentNativeDashboardService>.

Request: L<Google::Cloud::Chronicle::V1::FeaturedContentNativeDashboard::InstallFeaturedContentNativeDashboardRequest>

Returns: L<Google::Cloud::Chronicle::V1::FeaturedContentNativeDashboard::InstallFeaturedContentNativeDashboardResponse>

Parameters:

=over 4

=item * C<name> - C<string>

=item * C<featured_content_native_dashboard> - L<Google::Cloud::Chronicle::V1::FeaturedContentNativeDashboard::FeaturedContentNativeDashboard>

=back

=item * B<fetch_service_account_for_customer>

    my $response = $client->fetch_service_account_for_customer(
        parent                   => $parent,
    );

Calls the RPC method C<FetchServiceAccountForCustomer> on C<google.cloud.chronicle.v1.FeedsService>.

Request: L<Google::Cloud::Chronicle::V1::Feed::FetchServiceAccountForCustomerRequest>

Returns: L<Google::Cloud::Chronicle::V1::Feed::FeedServiceAccount>

Parameters:

=over 4

=item * C<parent> - C<string>

=back

=item * B<get_findings_refinement>

    my $response = $client->get_findings_refinement(
        name                     => $name,
    );

Calls the RPC method C<GetFindingsRefinement> on C<google.cloud.chronicle.v1.FindingsRefinementService>.

Request: L<Google::Cloud::Chronicle::V1::FindingsRefinement::GetFindingsRefinementRequest>

Returns: L<Google::Cloud::Chronicle::V1::FindingsRefinement::FindingsRefinement>

Parameters:

=over 4

=item * C<name> - C<string>

=back

=item * B<get_instance>

    my $response = $client->get_instance(
        name                     => $name,
    );

Calls the RPC method C<GetInstance> on C<google.cloud.chronicle.v1.InstanceService>.

Request: L<Google::Cloud::Chronicle::V1::Instance::GetInstanceRequest>

Returns: L<Google::Cloud::Chronicle::V1::Instance::Instance>

Parameters:

=over 4

=item * C<name> - C<string>

=back

=item * B<create_native_dashboard>

    my $response = $client->create_native_dashboard(
        parent                   => $parent,
        native_dashboard         => $native_dashboard,
    );

Calls the RPC method C<CreateNativeDashboard> on C<google.cloud.chronicle.v1.NativeDashboardService>.

Request: L<Google::Cloud::Chronicle::V1::NativeDashboard::CreateNativeDashboardRequest>

Returns: L<Google::Cloud::Chronicle::V1::NativeDashboard::NativeDashboard>

Parameters:

=over 4

=item * C<parent> - C<string>

=item * C<native_dashboard> - L<Google::Cloud::Chronicle::V1::NativeDashboard::NativeDashboard>

=back

=item * B<get_reference_list>

    my $response = $client->get_reference_list(
        name                     => $name,
        view                     => $view,
    );

Calls the RPC method C<GetReferenceList> on C<google.cloud.chronicle.v1.ReferenceListService>.

Request: L<Google::Cloud::Chronicle::V1::ReferenceList::GetReferenceListRequest>

Returns: L<Google::Cloud::Chronicle::V1::ReferenceList::ReferenceList>

Parameters:

=over 4

=item * C<name> - C<string>

=item * C<view> - L<Google::Cloud::Chronicle::V1::ReferenceList::ReferenceListView>

=back

=item * B<create_rule>

    my $response = $client->create_rule(
        parent                   => $parent,
        rule                     => $rule,
    );

Calls the RPC method C<CreateRule> on C<google.cloud.chronicle.v1.RuleService>.

Request: L<Google::Cloud::Chronicle::V1::Rule::CreateRuleRequest>

Returns: L<Google::Cloud::Chronicle::V1::Rule::Rule>

Parameters:

=over 4

=item * C<parent> - C<string>

=item * C<rule> - L<Google::Cloud::Chronicle::V1::Rule::Rule>

=back

=item * B<list_rule_execution_errors>

    my $response = $client->list_rule_execution_errors(
        parent                   => $parent,
        page_size                => $page_size,
        page_token               => $page_token,
        filter                   => $filter,
    );

Calls the RPC method C<ListRuleExecutionErrors> on C<google.cloud.chronicle.v1.RuleExecutionErrorService>.

Request: L<Google::Cloud::Chronicle::V1::RuleExecutionError::ListRuleExecutionErrorsRequest>

Returns: L<Google::Cloud::Chronicle::V1::RuleExecutionError::ListRuleExecutionErrorsResponse>

Parameters:

=over 4

=item * C<parent> - C<string>

=item * C<page_size> - C<int32>

=item * C<page_token> - C<string>

=item * C<filter> - C<string>

=back

=item * B<search>

    my $response = $client->search(
        parent                   => $parent,
        query                    => $query,
        time_range               => $time_range,
        dialect                  => $dialect,
        draft_data_access_scope  => $draft_data_access_scope,
        result_limit             => $result_limit,
        simulated_data_visibility => $simulated_data_visibility,
    );

Calls the RPC method C<Search> on C<google.cloud.chronicle.v1.SearchService>.

Request: L<Google::Cloud::Chronicle::V1::Search::SearchRequest>

Returns: L<Google::Longrunning::Operations::Operation>

Parameters:

=over 4

=item * C<parent> - C<string>

=item * C<query> - C<string>

=item * C<time_range> - L<Google::Type::Interval::Interval>

=item * C<dialect> - L<Google::Cloud::Chronicle::V1::Search::QueryDialect>

=item * C<draft_data_access_scope> - L<Google::Cloud::Chronicle::V1::DataAccessControl::DataAccessScope>

=item * C<result_limit> - C<int32>

=item * C<simulated_data_visibility> - L<Google::Cloud::Chronicle::V1::Search::SimulatedDataVisibility>

=back

=back



=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
