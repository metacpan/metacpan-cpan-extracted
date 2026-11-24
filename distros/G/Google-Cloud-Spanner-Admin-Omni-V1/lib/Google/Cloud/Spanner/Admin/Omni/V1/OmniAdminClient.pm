package Google::Cloud::Spanner::Admin::Omni::V1::OmniAdminClient;

use strict;
use warnings;
use Moo;
use Google::gRPC::Client;
use Google::Cloud::REST::Client;
use Google::Auth;
use Carp qw(croak);

use Protobuf;
use Google::Api::Common;
use Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin;

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

    my $target = 'spanner.googleapis.com:443';
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

sub create_location {
    my ($self, %params) = @_;

    my $request_class = 'Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::CreateLocationRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::Location';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.spanner.admin.omni.v1.OmniAdmin/CreateLocation',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.spanner.admin.omni.v1.OmniAdmin',
        method         => 'CreateLocation',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub get_location {
    my ($self, %params) = @_;

    my $request_class = 'Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::GetLocationRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::Location';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.spanner.admin.omni.v1.OmniAdmin/GetLocation',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.spanner.admin.omni.v1.OmniAdmin',
        method         => 'GetLocation',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub list_locations {
    my ($self, %params) = @_;

    my $request_class = 'Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::ListLocationsRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::ListLocationsResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.spanner.admin.omni.v1.OmniAdmin/ListLocations',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.spanner.admin.omni.v1.OmniAdmin',
        method         => 'ListLocations',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub delete_location {
    my ($self, %params) = @_;

    my $request_class = 'Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::DeleteLocationRequest';
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
            path           => '/google.spanner.admin.omni.v1.OmniAdmin/DeleteLocation',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.spanner.admin.omni.v1.OmniAdmin',
        method         => 'DeleteLocation',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub create_location_distance {
    my ($self, %params) = @_;

    my $request_class = 'Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::CreateLocationDistanceRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::LocationDistance';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.spanner.admin.omni.v1.OmniAdmin/CreateLocationDistance',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.spanner.admin.omni.v1.OmniAdmin',
        method         => 'CreateLocationDistance',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub get_location_distance {
    my ($self, %params) = @_;

    my $request_class = 'Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::GetLocationDistanceRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::LocationDistance';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.spanner.admin.omni.v1.OmniAdmin/GetLocationDistance',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.spanner.admin.omni.v1.OmniAdmin',
        method         => 'GetLocationDistance',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub list_location_distances {
    my ($self, %params) = @_;

    my $request_class = 'Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::ListLocationDistancesRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::ListLocationDistancesResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.spanner.admin.omni.v1.OmniAdmin/ListLocationDistances',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.spanner.admin.omni.v1.OmniAdmin',
        method         => 'ListLocationDistances',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub update_location_distance {
    my ($self, %params) = @_;

    my $request_class = 'Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::UpdateLocationDistanceRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::LocationDistance';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.spanner.admin.omni.v1.OmniAdmin/UpdateLocationDistance',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.spanner.admin.omni.v1.OmniAdmin',
        method         => 'UpdateLocationDistance',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub delete_location_distance {
    my ($self, %params) = @_;

    my $request_class = 'Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::DeleteLocationDistanceRequest';
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
            path           => '/google.spanner.admin.omni.v1.OmniAdmin/DeleteLocationDistance',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.spanner.admin.omni.v1.OmniAdmin',
        method         => 'DeleteLocationDistance',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub get_zone {
    my ($self, %params) = @_;

    my $request_class = 'Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::GetZoneRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::Zone';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.spanner.admin.omni.v1.OmniAdmin/GetZone',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.spanner.admin.omni.v1.OmniAdmin',
        method         => 'GetZone',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub list_zones {
    my ($self, %params) = @_;

    my $request_class = 'Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::ListZonesRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::ListZonesResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.spanner.admin.omni.v1.OmniAdmin/ListZones',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.spanner.admin.omni.v1.OmniAdmin',
        method         => 'ListZones',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub list_zone_operations {
    my ($self, %params) = @_;

    my $request_class = 'Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::ListZoneOperationsRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::ListZoneOperationsResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.spanner.admin.omni.v1.OmniAdmin/ListZoneOperations',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.spanner.admin.omni.v1.OmniAdmin',
        method         => 'ListZoneOperations',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub create_zone {
    my ($self, %params) = @_;

    my $request_class = 'Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::CreateZoneRequest';
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
            path           => '/google.spanner.admin.omni.v1.OmniAdmin/CreateZone',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.spanner.admin.omni.v1.OmniAdmin',
        method         => 'CreateZone',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub delete_zone {
    my ($self, %params) = @_;

    my $request_class = 'Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::DeleteZoneRequest';
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
            path           => '/google.spanner.admin.omni.v1.OmniAdmin/DeleteZone',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.spanner.admin.omni.v1.OmniAdmin',
        method         => 'DeleteZone',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub create_server {
    my ($self, %params) = @_;

    my $request_class = 'Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::CreateServerRequest';
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
            path           => '/google.spanner.admin.omni.v1.OmniAdmin/CreateServer',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.spanner.admin.omni.v1.OmniAdmin',
        method         => 'CreateServer',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub get_server {
    my ($self, %params) = @_;

    my $request_class = 'Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::GetServerRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::Server';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.spanner.admin.omni.v1.OmniAdmin/GetServer',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.spanner.admin.omni.v1.OmniAdmin',
        method         => 'GetServer',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub list_servers {
    my ($self, %params) = @_;

    my $request_class = 'Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::ListServersRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::ListServersResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.spanner.admin.omni.v1.OmniAdmin/ListServers',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.spanner.admin.omni.v1.OmniAdmin',
        method         => 'ListServers',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub delete_server {
    my ($self, %params) = @_;

    my $request_class = 'Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::DeleteServerRequest';
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
            path           => '/google.spanner.admin.omni.v1.OmniAdmin/DeleteServer',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.spanner.admin.omni.v1.OmniAdmin',
        method         => 'DeleteServer',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub list_server_operations {
    my ($self, %params) = @_;

    my $request_class = 'Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::ListServerOperationsRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::ListServerOperationsResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.spanner.admin.omni.v1.OmniAdmin/ListServerOperations',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.spanner.admin.omni.v1.OmniAdmin',
        method         => 'ListServerOperations',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub create_external_storage {
    my ($self, %params) = @_;

    my $request_class = 'Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::CreateExternalStorageRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::ExternalStorage';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.spanner.admin.omni.v1.OmniAdmin/CreateExternalStorage',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.spanner.admin.omni.v1.OmniAdmin',
        method         => 'CreateExternalStorage',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub list_backup_descriptors {
    my ($self, %params) = @_;

    my $request_class = 'Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::ListBackupDescriptorsRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::ListBackupDescriptorsResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.spanner.admin.omni.v1.OmniAdmin/ListBackupDescriptors',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.spanner.admin.omni.v1.OmniAdmin',
        method         => 'ListBackupDescriptors',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub get_external_storage {
    my ($self, %params) = @_;

    my $request_class = 'Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::GetExternalStorageRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::ExternalStorage';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.spanner.admin.omni.v1.OmniAdmin/GetExternalStorage',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.spanner.admin.omni.v1.OmniAdmin',
        method         => 'GetExternalStorage',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub delete_external_storage {
    my ($self, %params) = @_;

    my $request_class = 'Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::DeleteExternalStorageRequest';
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
            path           => '/google.spanner.admin.omni.v1.OmniAdmin/DeleteExternalStorage',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.spanner.admin.omni.v1.OmniAdmin',
        method         => 'DeleteExternalStorage',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub list_external_storages {
    my ($self, %params) = @_;

    my $request_class = 'Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::ListExternalStoragesRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::ListExternalStoragesResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.spanner.admin.omni.v1.OmniAdmin/ListExternalStorages',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.spanner.admin.omni.v1.OmniAdmin',
        method         => 'ListExternalStorages',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub get_iam_policy {
    my ($self, %params) = @_;

    my $request_class = 'Google::Iam::V1::IamPolicy::GetIamPolicyRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Iam::V1::Policy::Policy';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.spanner.admin.omni.v1.OmniAdmin/GetIamPolicy',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.spanner.admin.omni.v1.OmniAdmin',
        method         => 'GetIamPolicy',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub set_iam_policy {
    my ($self, %params) = @_;

    my $request_class = 'Google::Iam::V1::IamPolicy::SetIamPolicyRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Iam::V1::Policy::Policy';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.spanner.admin.omni.v1.OmniAdmin/SetIamPolicy',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.spanner.admin.omni.v1.OmniAdmin',
        method         => 'SetIamPolicy',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub import_backup {
    my ($self, %params) = @_;

    my $request_class = 'Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::ImportBackupRequest';
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
            path           => '/google.spanner.admin.omni.v1.OmniAdmin/ImportBackup',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.spanner.admin.omni.v1.OmniAdmin',
        method         => 'ImportBackup',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub list_rollouts {
    my ($self, %params) = @_;

    my $request_class = 'Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::ListRolloutsRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::ListRolloutsResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.spanner.admin.omni.v1.OmniAdmin/ListRollouts',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.spanner.admin.omni.v1.OmniAdmin',
        method         => 'ListRollouts',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub get_rollout {
    my ($self, %params) = @_;

    my $request_class = 'Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::GetRolloutRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::Rollout';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.spanner.admin.omni.v1.OmniAdmin/GetRollout',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.spanner.admin.omni.v1.OmniAdmin',
        method         => 'GetRollout',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub schedule_rollout_phase {
    my ($self, %params) = @_;

    my $request_class = 'Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::ScheduleRolloutPhaseRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::Rollout';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.spanner.admin.omni.v1.OmniAdmin/ScheduleRolloutPhase',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.spanner.admin.omni.v1.OmniAdmin',
        method         => 'ScheduleRolloutPhase',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub abort_rollout {
    my ($self, %params) = @_;

    my $request_class = 'Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::AbortRolloutRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::Rollout';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.spanner.admin.omni.v1.OmniAdmin/AbortRollout',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.spanner.admin.omni.v1.OmniAdmin',
        method         => 'AbortRollout',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub rollback_rollout {
    my ($self, %params) = @_;

    my $request_class = 'Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::RollbackRolloutRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::Rollout';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.spanner.admin.omni.v1.OmniAdmin/RollbackRollout',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.spanner.admin.omni.v1.OmniAdmin',
        method         => 'RollbackRollout',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub rotate_internal_keys {
    my ($self, %params) = @_;

    my $request_class = 'Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::RotateInternalKeysRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::RotateInternalKeysResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.spanner.admin.omni.v1.OmniAdmin/RotateInternalKeys',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.spanner.admin.omni.v1.OmniAdmin',
        method         => 'RotateInternalKeys',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}
1; # End of Google::Cloud::Spanner::Admin::Omni::V1::OmniAdminClient

__END__

=head1 NAME

Google::Cloud::Spanner::Admin::Omni::V1::OmniAdminClient - Client library for Google Cloud Services

=head1 SYNOPSIS

    use Google::Cloud::Spanner::Admin::Omni::V1::OmniAdminClient;
    use Google::Auth;

    my $auth = Google::Auth->default();

    # 1. High-performance gRPC Transport (Default)
    my $grpc_client = Google::Cloud::Spanner::Admin::Omni::V1::OmniAdminClient->new(
        credentials => $auth,
        transport   => 'grpc', # Optional: 'grpc' is default
    );

    # 2. HTTP/REST Transport
    my $rest_client = Google::Cloud::Spanner::Admin::Omni::V1::OmniAdminClient->new(
        credentials => $auth,
        transport   => 'rest',
    );

    # Execute service methods
    my $res = $grpc_client->some_method( %params );

=head1 DESCRIPTION

C<Google::Cloud::Spanner::Admin::Omni::V1::OmniAdminClient> is an auto-generated client library for Google Cloud Services.

It provides a unified client interface supporting both high-performance HTTP/2 gRPC and HTTP/REST transports, with automatic Google Cloud Application Default Credentials (ADC) resolution and typed Protocol Buffers message handling.

=head1 SOURCE

Generated from the following Protocol Buffers schemas:

=over 4

=item * C<googleapis/google/spanner/admin/omni/v1/spanner_omni_admin.proto>



=back

=head1 CONSTRUCTOR

=head2 new

    my $client = Google::Cloud::Spanner::Admin::Omni::V1::OmniAdminClient->new(
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

=item * B<create_location>

    my $response = $client->create_location(
        location_id              => $location_id,
        location                 => $location,
    );

Calls the RPC method C<CreateLocation> on C<google.spanner.admin.omni.v1.OmniAdmin>.

Request: L<Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::CreateLocationRequest>

Returns: L<Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::Location>

Parameters:

=over 4

=item * C<location_id> - C<string>

=item * C<location> - L<Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::Location>

=back

=item * B<get_location>

    my $response = $client->get_location(
        name                     => $name,
    );

Calls the RPC method C<GetLocation> on C<google.spanner.admin.omni.v1.OmniAdmin>.

Request: L<Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::GetLocationRequest>

Returns: L<Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::Location>

Parameters:

=over 4

=item * C<name> - C<string>

=back

=item * B<list_locations>

    my $response = $client->list_locations(
        page_size                => $page_size,
        page_token               => $page_token,
    );

Calls the RPC method C<ListLocations> on C<google.spanner.admin.omni.v1.OmniAdmin>.

Request: L<Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::ListLocationsRequest>

Returns: L<Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::ListLocationsResponse>

Parameters:

=over 4

=item * C<page_size> - C<int32>

=item * C<page_token> - C<string>

=back

=item * B<delete_location>

    my $response = $client->delete_location(
        name                     => $name,
    );

Calls the RPC method C<DeleteLocation> on C<google.spanner.admin.omni.v1.OmniAdmin>.

Request: L<Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::DeleteLocationRequest>

Returns: L<Google::Protobuf::Empty::Empty>

Parameters:

=over 4

=item * C<name> - C<string>

=back

=item * B<create_location_distance>

    my $response = $client->create_location_distance(
        parent                   => $parent,
        other_location_id        => $other_location_id,
        location_distance        => $location_distance,
    );

Calls the RPC method C<CreateLocationDistance> on C<google.spanner.admin.omni.v1.OmniAdmin>.

Request: L<Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::CreateLocationDistanceRequest>

Returns: L<Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::LocationDistance>

Parameters:

=over 4

=item * C<parent> - C<string>

=item * C<other_location_id> - C<string>

=item * C<location_distance> - L<Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::LocationDistance>

=back

=item * B<get_location_distance>

    my $response = $client->get_location_distance(
        name                     => $name,
    );

Calls the RPC method C<GetLocationDistance> on C<google.spanner.admin.omni.v1.OmniAdmin>.

Request: L<Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::GetLocationDistanceRequest>

Returns: L<Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::LocationDistance>

Parameters:

=over 4

=item * C<name> - C<string>

=back

=item * B<list_location_distances>

    my $response = $client->list_location_distances(
        parent                   => $parent,
        page_size                => $page_size,
        page_token               => $page_token,
    );

Calls the RPC method C<ListLocationDistances> on C<google.spanner.admin.omni.v1.OmniAdmin>.

Request: L<Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::ListLocationDistancesRequest>

Returns: L<Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::ListLocationDistancesResponse>

Parameters:

=over 4

=item * C<parent> - C<string>

=item * C<page_size> - C<int32>

=item * C<page_token> - C<string>

=back

=item * B<update_location_distance>

    my $response = $client->update_location_distance(
        location_distance        => $location_distance,
        update_mask              => $update_mask,
    );

Calls the RPC method C<UpdateLocationDistance> on C<google.spanner.admin.omni.v1.OmniAdmin>.

Request: L<Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::UpdateLocationDistanceRequest>

Returns: L<Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::LocationDistance>

Parameters:

=over 4

=item * C<location_distance> - L<Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::LocationDistance>

=item * C<update_mask> - L<Google::Protobuf::FieldMask::FieldMask>

=back

=item * B<delete_location_distance>

    my $response = $client->delete_location_distance(
        name                     => $name,
    );

Calls the RPC method C<DeleteLocationDistance> on C<google.spanner.admin.omni.v1.OmniAdmin>.

Request: L<Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::DeleteLocationDistanceRequest>

Returns: L<Google::Protobuf::Empty::Empty>

Parameters:

=over 4

=item * C<name> - C<string>

=back

=item * B<get_zone>

    my $response = $client->get_zone(
        name                     => $name,
    );

Calls the RPC method C<GetZone> on C<google.spanner.admin.omni.v1.OmniAdmin>.

Request: L<Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::GetZoneRequest>

Returns: L<Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::Zone>

Parameters:

=over 4

=item * C<name> - C<string>

=back

=item * B<list_zones>

    my $response = $client->list_zones(
        page_size                => $page_size,
        page_token               => $page_token,
    );

Calls the RPC method C<ListZones> on C<google.spanner.admin.omni.v1.OmniAdmin>.

Request: L<Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::ListZonesRequest>

Returns: L<Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::ListZonesResponse>

Parameters:

=over 4

=item * C<page_size> - C<int32>

=item * C<page_token> - C<string>

=back

=item * B<list_zone_operations>

    my $response = $client->list_zone_operations(
        parent                   => $parent,
        page_size                => $page_size,
        page_token               => $page_token,
    );

Calls the RPC method C<ListZoneOperations> on C<google.spanner.admin.omni.v1.OmniAdmin>.

Request: L<Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::ListZoneOperationsRequest>

Returns: L<Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::ListZoneOperationsResponse>

Parameters:

=over 4

=item * C<parent> - C<string>

=item * C<page_size> - C<int32>

=item * C<page_token> - C<string>

=back

=item * B<create_zone>

    my $response = $client->create_zone(
        zone_id                  => $zone_id,
        zone                     => $zone,
    );

Calls the RPC method C<CreateZone> on C<google.spanner.admin.omni.v1.OmniAdmin>.

Request: L<Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::CreateZoneRequest>

Returns: L<Google::Longrunning::Operations::Operation>

Parameters:

=over 4

=item * C<zone_id> - C<string>

=item * C<zone> - L<Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::Zone>

=back

=item * B<delete_zone>

    my $response = $client->delete_zone(
        name                     => $name,
    );

Calls the RPC method C<DeleteZone> on C<google.spanner.admin.omni.v1.OmniAdmin>.

Request: L<Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::DeleteZoneRequest>

Returns: L<Google::Longrunning::Operations::Operation>

Parameters:

=over 4

=item * C<name> - C<string>

=back

=item * B<create_server>

    my $response = $client->create_server(
        parent                   => $parent,
        server_id                => $server_id,
        server                   => $server,
    );

Calls the RPC method C<CreateServer> on C<google.spanner.admin.omni.v1.OmniAdmin>.

Request: L<Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::CreateServerRequest>

Returns: L<Google::Longrunning::Operations::Operation>

Parameters:

=over 4

=item * C<parent> - C<string>

=item * C<server_id> - C<string>

=item * C<server> - L<Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::Server>

=back

=item * B<get_server>

    my $response = $client->get_server(
        name                     => $name,
    );

Calls the RPC method C<GetServer> on C<google.spanner.admin.omni.v1.OmniAdmin>.

Request: L<Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::GetServerRequest>

Returns: L<Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::Server>

Parameters:

=over 4

=item * C<name> - C<string>

=back

=item * B<list_servers>

    my $response = $client->list_servers(
        parent                   => $parent,
        page_size                => $page_size,
        page_token               => $page_token,
    );

Calls the RPC method C<ListServers> on C<google.spanner.admin.omni.v1.OmniAdmin>.

Request: L<Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::ListServersRequest>

Returns: L<Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::ListServersResponse>

Parameters:

=over 4

=item * C<parent> - C<string>

=item * C<page_size> - C<int32>

=item * C<page_token> - C<string>

=back

=item * B<delete_server>

    my $response = $client->delete_server(
        name                     => $name,
    );

Calls the RPC method C<DeleteServer> on C<google.spanner.admin.omni.v1.OmniAdmin>.

Request: L<Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::DeleteServerRequest>

Returns: L<Google::Longrunning::Operations::Operation>

Parameters:

=over 4

=item * C<name> - C<string>

=back

=item * B<list_server_operations>

    my $response = $client->list_server_operations(
        parent                   => $parent,
        page_size                => $page_size,
        page_token               => $page_token,
    );

Calls the RPC method C<ListServerOperations> on C<google.spanner.admin.omni.v1.OmniAdmin>.

Request: L<Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::ListServerOperationsRequest>

Returns: L<Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::ListServerOperationsResponse>

Parameters:

=over 4

=item * C<parent> - C<string>

=item * C<page_size> - C<int32>

=item * C<page_token> - C<string>

=back

=item * B<create_external_storage>

    my $response = $client->create_external_storage(
        external_storage_id      => $external_storage_id,
        external_storage         => $external_storage,
    );

Calls the RPC method C<CreateExternalStorage> on C<google.spanner.admin.omni.v1.OmniAdmin>.

Request: L<Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::CreateExternalStorageRequest>

Returns: L<Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::ExternalStorage>

Parameters:

=over 4

=item * C<external_storage_id> - C<string>

=item * C<external_storage> - L<Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::ExternalStorage>

=back

=item * B<list_backup_descriptors>

    my $response = $client->list_backup_descriptors(
        parent                   => $parent,
        page_size                => $page_size,
        page_token               => $page_token,
    );

Calls the RPC method C<ListBackupDescriptors> on C<google.spanner.admin.omni.v1.OmniAdmin>.

Request: L<Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::ListBackupDescriptorsRequest>

Returns: L<Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::ListBackupDescriptorsResponse>

Parameters:

=over 4

=item * C<parent> - C<string>

=item * C<page_size> - C<int32>

=item * C<page_token> - C<string>

=back

=item * B<get_external_storage>

    my $response = $client->get_external_storage(
        name                     => $name,
    );

Calls the RPC method C<GetExternalStorage> on C<google.spanner.admin.omni.v1.OmniAdmin>.

Request: L<Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::GetExternalStorageRequest>

Returns: L<Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::ExternalStorage>

Parameters:

=over 4

=item * C<name> - C<string>

=back

=item * B<delete_external_storage>

    my $response = $client->delete_external_storage(
        name                     => $name,
    );

Calls the RPC method C<DeleteExternalStorage> on C<google.spanner.admin.omni.v1.OmniAdmin>.

Request: L<Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::DeleteExternalStorageRequest>

Returns: L<Google::Protobuf::Empty::Empty>

Parameters:

=over 4

=item * C<name> - C<string>

=back

=item * B<list_external_storages>

    my $response = $client->list_external_storages(
        page_size                => $page_size,
        page_token               => $page_token,
    );

Calls the RPC method C<ListExternalStorages> on C<google.spanner.admin.omni.v1.OmniAdmin>.

Request: L<Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::ListExternalStoragesRequest>

Returns: L<Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::ListExternalStoragesResponse>

Parameters:

=over 4

=item * C<page_size> - C<int32>

=item * C<page_token> - C<string>

=back

=item * B<get_iam_policy>

    my $response = $client->get_iam_policy();

Calls the RPC method C<GetIamPolicy> on C<google.spanner.admin.omni.v1.OmniAdmin>.

Request: L<Google::Iam::V1::IamPolicy::GetIamPolicyRequest>

Returns: L<Google::Iam::V1::Policy::Policy>

=item * B<set_iam_policy>

    my $response = $client->set_iam_policy();

Calls the RPC method C<SetIamPolicy> on C<google.spanner.admin.omni.v1.OmniAdmin>.

Request: L<Google::Iam::V1::IamPolicy::SetIamPolicyRequest>

Returns: L<Google::Iam::V1::Policy::Policy>

=item * B<import_backup>

    my $response = $client->import_backup(
        parent                   => $parent,
        backup_id                => $backup_id,
        expiration_time          => $expiration_time,
    );

Calls the RPC method C<ImportBackup> on C<google.spanner.admin.omni.v1.OmniAdmin>.

Request: L<Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::ImportBackupRequest>

Returns: L<Google::Longrunning::Operations::Operation>

Parameters:

=over 4

=item * C<parent> - C<string>

=item * C<backup_id> - C<string>

=item * C<expiration_time> - L<Google::Protobuf::Timestamp::Timestamp>

=back

=item * B<list_rollouts>

    my $response = $client->list_rollouts(
        page_size                => $page_size,
        page_token               => $page_token,
    );

Calls the RPC method C<ListRollouts> on C<google.spanner.admin.omni.v1.OmniAdmin>.

Request: L<Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::ListRolloutsRequest>

Returns: L<Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::ListRolloutsResponse>

Parameters:

=over 4

=item * C<page_size> - C<int32>

=item * C<page_token> - C<string>

=back

=item * B<get_rollout>

    my $response = $client->get_rollout(
        name                     => $name,
    );

Calls the RPC method C<GetRollout> on C<google.spanner.admin.omni.v1.OmniAdmin>.

Request: L<Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::GetRolloutRequest>

Returns: L<Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::Rollout>

Parameters:

=over 4

=item * C<name> - C<string>

=back

=item * B<schedule_rollout_phase>

    my $response = $client->schedule_rollout_phase(
        name                     => $name,
        scheduled_time           => $scheduled_time,
    );

Calls the RPC method C<ScheduleRolloutPhase> on C<google.spanner.admin.omni.v1.OmniAdmin>.

Request: L<Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::ScheduleRolloutPhaseRequest>

Returns: L<Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::Rollout>

Parameters:

=over 4

=item * C<name> - C<string>

=item * C<scheduled_time> - L<Google::Protobuf::Timestamp::Timestamp>

=back

=item * B<abort_rollout>

    my $response = $client->abort_rollout(
        name                     => $name,
    );

Calls the RPC method C<AbortRollout> on C<google.spanner.admin.omni.v1.OmniAdmin>.

Request: L<Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::AbortRolloutRequest>

Returns: L<Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::Rollout>

Parameters:

=over 4

=item * C<name> - C<string>

=back

=item * B<rollback_rollout>

    my $response = $client->rollback_rollout(
        name                     => $name,
    );

Calls the RPC method C<RollbackRollout> on C<google.spanner.admin.omni.v1.OmniAdmin>.

Request: L<Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::RollbackRolloutRequest>

Returns: L<Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::Rollout>

Parameters:

=over 4

=item * C<name> - C<string>

=back

=item * B<rotate_internal_keys>

    my $response = $client->rotate_internal_keys(
        key_types                => [ ... ],
    );

Calls the RPC method C<RotateInternalKeys> on C<google.spanner.admin.omni.v1.OmniAdmin>.

Request: L<Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::RotateInternalKeysRequest>

Returns: L<Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::RotateInternalKeysResponse>

Parameters:

=over 4

=item * C<key_types> - ArrayRef of L<Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::KeyType>

=back

=back



=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
