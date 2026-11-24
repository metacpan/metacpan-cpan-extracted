package Google::Cloud::Monitoring::V3;

use strict;
use warnings;
use Moo;
use Google::gRPC::Client;
use Google::Cloud::REST::Client;
use Google::Auth;
use Carp qw(croak);

use Protobuf;
use Google::Api::Common;
use Google::Monitoring::V3::DroppedLabels;
use Google::Monitoring::V3::SpanContext;
use Google::Monitoring::V3::MutationRecord;
use Google::Monitoring::V3::Common;
use Google::Monitoring::V3::Uptime;
use Google::Monitoring::V3::Group;
use Google::Monitoring::V3::Service;
use Google::Monitoring::V3::Metric;
use Google::Monitoring::V3::Alert;
use Google::Monitoring::V3::Notification;
use Google::Monitoring::V3::Snooze;
use Google::Monitoring::V3::UptimeService;
use Google::Monitoring::V3::GroupService;
use Google::Monitoring::V3::ServiceService;
use Google::Monitoring::V3::MetricService;
use Google::Monitoring::V3::AlertService;
use Google::Monitoring::V3::NotificationService;
use Google::Monitoring::V3::SnoozeService;
use Google::Monitoring::V3::QueryService;

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

    my $target = 'monitoring.googleapis.com:443';
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

sub list_alert_policies {
    my ($self, %params) = @_;

    my $request_class = 'Google::Monitoring::V3::AlertService::ListAlertPoliciesRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Monitoring::V3::AlertService::ListAlertPoliciesResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.monitoring.v3.AlertPolicyService/ListAlertPolicies',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.monitoring.v3.AlertPolicyService',
        method         => 'ListAlertPolicies',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub list_groups {
    my ($self, %params) = @_;

    my $request_class = 'Google::Monitoring::V3::GroupService::ListGroupsRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Monitoring::V3::GroupService::ListGroupsResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.monitoring.v3.GroupService/ListGroups',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.monitoring.v3.GroupService',
        method         => 'ListGroups',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub list_monitored_resource_descriptors {
    my ($self, %params) = @_;

    my $request_class = 'Google::Monitoring::V3::MetricService::ListMonitoredResourceDescriptorsRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Monitoring::V3::MetricService::ListMonitoredResourceDescriptorsResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.monitoring.v3.MetricService/ListMonitoredResourceDescriptors',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.monitoring.v3.MetricService',
        method         => 'ListMonitoredResourceDescriptors',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub list_time_series {
    my ($self, %params) = @_;

    my $request_class = 'Google::Monitoring::V3::MetricService::ListTimeSeriesRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Monitoring::V3::MetricService::ListTimeSeriesResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.monitoring.v3.MetricService/ListTimeSeries',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.monitoring.v3.MetricService',
        method         => 'ListTimeSeries',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub create_time_series {
    my ($self, %params) = @_;

    my $request_class = 'Google::Monitoring::V3::MetricService::CreateTimeSeriesRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Protobuf::Empty::Empty';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.monitoring.v3.MetricService/CreateTimeSeries',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.monitoring.v3.MetricService',
        method         => 'CreateTimeSeries',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub create_service_time_series {
    my ($self, %params) = @_;

    my $request_class = 'Google::Monitoring::V3::MetricService::CreateTimeSeriesRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Protobuf::Empty::Empty';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.monitoring.v3.MetricService/CreateServiceTimeSeries',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.monitoring.v3.MetricService',
        method         => 'CreateServiceTimeSeries',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub list_notification_channel_descriptors {
    my ($self, %params) = @_;

    my $request_class = 'Google::Monitoring::V3::NotificationService::ListNotificationChannelDescriptorsRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Monitoring::V3::NotificationService::ListNotificationChannelDescriptorsResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.monitoring.v3.NotificationChannelService/ListNotificationChannelDescriptors',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.monitoring.v3.NotificationChannelService',
        method         => 'ListNotificationChannelDescriptors',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub query_time_series {
    my ($self, %params) = @_;

    my $request_class = 'Google::Monitoring::V3::MetricService::QueryTimeSeriesRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Monitoring::V3::MetricService::QueryTimeSeriesResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.monitoring.v3.QueryService/QueryTimeSeries',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.monitoring.v3.QueryService',
        method         => 'QueryTimeSeries',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub create_service {
    my ($self, %params) = @_;

    my $request_class = 'Google::Monitoring::V3::ServiceService::CreateServiceRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Monitoring::V3::Service::Service';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.monitoring.v3.ServiceMonitoringService/CreateService',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.monitoring.v3.ServiceMonitoringService',
        method         => 'CreateService',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub update_service {
    my ($self, %params) = @_;

    my $request_class = 'Google::Monitoring::V3::ServiceService::UpdateServiceRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Monitoring::V3::Service::Service';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.monitoring.v3.ServiceMonitoringService/UpdateService',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.monitoring.v3.ServiceMonitoringService',
        method         => 'UpdateService',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub create_snooze {
    my ($self, %params) = @_;

    my $request_class = 'Google::Monitoring::V3::SnoozeService::CreateSnoozeRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Monitoring::V3::Snooze::Snooze';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.monitoring.v3.SnoozeService/CreateSnooze',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.monitoring.v3.SnoozeService',
        method         => 'CreateSnooze',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub list_uptime_check_configs {
    my ($self, %params) = @_;

    my $request_class = 'Google::Monitoring::V3::UptimeService::ListUptimeCheckConfigsRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Monitoring::V3::UptimeService::ListUptimeCheckConfigsResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.monitoring.v3.UptimeCheckService/ListUptimeCheckConfigs',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.monitoring.v3.UptimeCheckService',
        method         => 'ListUptimeCheckConfigs',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub list_uptime_check_ips {
    my ($self, %params) = @_;

    my $request_class = 'Google::Monitoring::V3::UptimeService::ListUptimeCheckIpsRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Monitoring::V3::UptimeService::ListUptimeCheckIpsResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.monitoring.v3.UptimeCheckService/ListUptimeCheckIps',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.monitoring.v3.UptimeCheckService',
        method         => 'ListUptimeCheckIps',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}
1; # End of Google::Cloud::Monitoring::V3

__END__

=head1 NAME

Google::Cloud::Monitoring::V3 - Client library for Google Cloud Services

=head1 SYNOPSIS

    use Google::Cloud::Monitoring::V3;
    use Google::Auth;

    my $auth = Google::Auth->default();

    # 1. High-performance gRPC Transport (Default)
    my $grpc_client = Google::Cloud::Monitoring::V3->new(
        credentials => $auth,
        transport   => 'grpc', # Optional: 'grpc' is default
    );

    # 2. HTTP/REST Transport
    my $rest_client = Google::Cloud::Monitoring::V3->new(
        credentials => $auth,
        transport   => 'rest',
    );

    # Execute service methods
    my $res = $grpc_client->some_method( %params );

=head1 DESCRIPTION

C<Google::Cloud::Monitoring::V3> is an auto-generated client library for Google Cloud Services.

It provides a unified client interface supporting both high-performance HTTP/2 gRPC and HTTP/REST transports, with automatic Google Cloud Application Default Credentials (ADC) resolution and typed Protocol Buffers message handling.

=head1 SOURCE

Generated from the following Protocol Buffers schemas:

=over 4

=item * C<googleapis/google/monitoring/v3/alert.proto>

=item * C<googleapis/google/monitoring/v3/alert_service.proto>

=item * C<googleapis/google/monitoring/v3/common.proto>

=item * C<googleapis/google/monitoring/v3/dropped_labels.proto>

=item * C<googleapis/google/monitoring/v3/group.proto>

=item * C<googleapis/google/monitoring/v3/group_service.proto>

=item * C<googleapis/google/monitoring/v3/metric.proto>

=item * C<googleapis/google/monitoring/v3/metric_service.proto>

=item * C<googleapis/google/monitoring/v3/mutation_record.proto>

=item * C<googleapis/google/monitoring/v3/notification.proto>

=item * C<googleapis/google/monitoring/v3/notification_service.proto>

=item * C<googleapis/google/monitoring/v3/query_service.proto>

=item * C<googleapis/google/monitoring/v3/service.proto>

=item * C<googleapis/google/monitoring/v3/service_service.proto>

=item * C<googleapis/google/monitoring/v3/snooze.proto>

=item * C<googleapis/google/monitoring/v3/snooze_service.proto>

=item * C<googleapis/google/monitoring/v3/span_context.proto>

=item * C<googleapis/google/monitoring/v3/uptime.proto>

=item * C<googleapis/google/monitoring/v3/uptime_service.proto>



=back

=head1 CONSTRUCTOR

=head2 new

    my $client = Google::Cloud::Monitoring::V3->new(
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

=item * B<list_alert_policies>

    my $response = $client->list_alert_policies(
        name                     => $name,
        filter                   => $filter,
        order_by                 => $order_by,
        page_size                => $page_size,
        page_token               => $page_token,
    );

Calls the RPC method C<ListAlertPolicies> on C<google.monitoring.v3.AlertPolicyService>.

Request: L<Google::Monitoring::V3::AlertService::ListAlertPoliciesRequest>

Returns: L<Google::Monitoring::V3::AlertService::ListAlertPoliciesResponse>

Parameters:

=over 4

=item * C<name> - C<string>

=item * C<filter> - C<string>

=item * C<order_by> - C<string>

=item * C<page_size> - C<int32>

=item * C<page_token> - C<string>

=back

=item * B<list_groups>

    my $response = $client->list_groups(
        name                     => $name,
        page_size                => $page_size,
        page_token               => $page_token,
    );

Calls the RPC method C<ListGroups> on C<google.monitoring.v3.GroupService>.

Request: L<Google::Monitoring::V3::GroupService::ListGroupsRequest>

Returns: L<Google::Monitoring::V3::GroupService::ListGroupsResponse>

Parameters:

=over 4

=item * C<name> - C<string>

=item * C<page_size> - C<int32>

=item * C<page_token> - C<string>

=back

=item * B<list_monitored_resource_descriptors>

    my $response = $client->list_monitored_resource_descriptors(
        name                     => $name,
        filter                   => $filter,
        page_size                => $page_size,
        page_token               => $page_token,
    );

Calls the RPC method C<ListMonitoredResourceDescriptors> on C<google.monitoring.v3.MetricService>.

Request: L<Google::Monitoring::V3::MetricService::ListMonitoredResourceDescriptorsRequest>

Returns: L<Google::Monitoring::V3::MetricService::ListMonitoredResourceDescriptorsResponse>

Parameters:

=over 4

=item * C<name> - C<string>

=item * C<filter> - C<string>

=item * C<page_size> - C<int32>

=item * C<page_token> - C<string>

=back

=item * B<list_time_series>

    my $response = $client->list_time_series(
        name                     => $name,
        filter                   => $filter,
        interval                 => $interval,
        aggregation              => $aggregation,
        secondary_aggregation    => $secondary_aggregation,
        order_by                 => $order_by,
        view                     => $view,
        page_size                => $page_size,
        page_token               => $page_token,
    );

Calls the RPC method C<ListTimeSeries> on C<google.monitoring.v3.MetricService>.

Request: L<Google::Monitoring::V3::MetricService::ListTimeSeriesRequest>

Returns: L<Google::Monitoring::V3::MetricService::ListTimeSeriesResponse>

Parameters:

=over 4

=item * C<name> - C<string>

=item * C<filter> - C<string>

=item * C<interval> - L<Google::Monitoring::V3::Common::TimeInterval>

=item * C<aggregation> - L<Google::Monitoring::V3::Common::Aggregation>

=item * C<secondary_aggregation> - L<Google::Monitoring::V3::Common::Aggregation>

=item * C<order_by> - C<string>

=item * C<view> - L<Google::Monitoring::V3::MetricService::TimeSeriesView>

=item * C<page_size> - C<int32>

=item * C<page_token> - C<string>

=back

=item * B<create_time_series>

    my $response = $client->create_time_series(
        name                     => $name,
        time_series              => [ ... ],
    );

Calls the RPC method C<CreateTimeSeries> on C<google.monitoring.v3.MetricService>.

Request: L<Google::Monitoring::V3::MetricService::CreateTimeSeriesRequest>

Returns: L<Google::Protobuf::Empty::Empty>

Parameters:

=over 4

=item * C<name> - C<string>

=item * C<time_series> - ArrayRef of L<Google::Monitoring::V3::Metric::TimeSeries>

=back

=item * B<create_service_time_series>

    my $response = $client->create_service_time_series(
        name                     => $name,
        time_series              => [ ... ],
    );

Calls the RPC method C<CreateServiceTimeSeries> on C<google.monitoring.v3.MetricService>.

Request: L<Google::Monitoring::V3::MetricService::CreateTimeSeriesRequest>

Returns: L<Google::Protobuf::Empty::Empty>

Parameters:

=over 4

=item * C<name> - C<string>

=item * C<time_series> - ArrayRef of L<Google::Monitoring::V3::Metric::TimeSeries>

=back

=item * B<list_notification_channel_descriptors>

    my $response = $client->list_notification_channel_descriptors(
        name                     => $name,
        page_size                => $page_size,
        page_token               => $page_token,
    );

Calls the RPC method C<ListNotificationChannelDescriptors> on C<google.monitoring.v3.NotificationChannelService>.

Request: L<Google::Monitoring::V3::NotificationService::ListNotificationChannelDescriptorsRequest>

Returns: L<Google::Monitoring::V3::NotificationService::ListNotificationChannelDescriptorsResponse>

Parameters:

=over 4

=item * C<name> - C<string>

=item * C<page_size> - C<int32>

=item * C<page_token> - C<string>

=back

=item * B<query_time_series>

    my $response = $client->query_time_series(
        name                     => $name,
        query                    => $query,
        page_size                => $page_size,
        page_token               => $page_token,
    );

Calls the RPC method C<QueryTimeSeries> on C<google.monitoring.v3.QueryService>.

Request: L<Google::Monitoring::V3::MetricService::QueryTimeSeriesRequest>

Returns: L<Google::Monitoring::V3::MetricService::QueryTimeSeriesResponse>

Parameters:

=over 4

=item * C<name> - C<string>

=item * C<query> - C<string>

=item * C<page_size> - C<int32>

=item * C<page_token> - C<string>

=back

=item * B<create_service>

    my $response = $client->create_service(
        parent                   => $parent,
        service_id               => $service_id,
        service                  => $service,
    );

Calls the RPC method C<CreateService> on C<google.monitoring.v3.ServiceMonitoringService>.

Request: L<Google::Monitoring::V3::ServiceService::CreateServiceRequest>

Returns: L<Google::Monitoring::V3::Service::Service>

Parameters:

=over 4

=item * C<parent> - C<string>

=item * C<service_id> - C<string>

=item * C<service> - L<Google::Monitoring::V3::Service::Service>

=back

=item * B<update_service>

    my $response = $client->update_service(
        service                  => $service,
        update_mask              => $update_mask,
    );

Calls the RPC method C<UpdateService> on C<google.monitoring.v3.ServiceMonitoringService>.

Request: L<Google::Monitoring::V3::ServiceService::UpdateServiceRequest>

Returns: L<Google::Monitoring::V3::Service::Service>

Parameters:

=over 4

=item * C<service> - L<Google::Monitoring::V3::Service::Service>

=item * C<update_mask> - L<Google::Protobuf::FieldMask::FieldMask>

=back

=item * B<create_snooze>

    my $response = $client->create_snooze(
        parent                   => $parent,
        snooze                   => $snooze,
    );

Calls the RPC method C<CreateSnooze> on C<google.monitoring.v3.SnoozeService>.

Request: L<Google::Monitoring::V3::SnoozeService::CreateSnoozeRequest>

Returns: L<Google::Monitoring::V3::Snooze::Snooze>

Parameters:

=over 4

=item * C<parent> - C<string>

=item * C<snooze> - L<Google::Monitoring::V3::Snooze::Snooze>

=back

=item * B<list_uptime_check_configs>

    my $response = $client->list_uptime_check_configs(
        parent                   => $parent,
        filter                   => $filter,
        page_size                => $page_size,
        page_token               => $page_token,
    );

Calls the RPC method C<ListUptimeCheckConfigs> on C<google.monitoring.v3.UptimeCheckService>.

Request: L<Google::Monitoring::V3::UptimeService::ListUptimeCheckConfigsRequest>

Returns: L<Google::Monitoring::V3::UptimeService::ListUptimeCheckConfigsResponse>

Parameters:

=over 4

=item * C<parent> - C<string>

=item * C<filter> - C<string>

=item * C<page_size> - C<int32>

=item * C<page_token> - C<string>

=back

=item * B<list_uptime_check_ips>

    my $response = $client->list_uptime_check_ips(
        page_size                => $page_size,
        page_token               => $page_token,
    );

Calls the RPC method C<ListUptimeCheckIps> on C<google.monitoring.v3.UptimeCheckService>.

Request: L<Google::Monitoring::V3::UptimeService::ListUptimeCheckIpsRequest>

Returns: L<Google::Monitoring::V3::UptimeService::ListUptimeCheckIpsResponse>

Parameters:

=over 4

=item * C<page_size> - C<int32>

=item * C<page_token> - C<string>

=back

=back



=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
