use strict;
use warnings;
use Test::More;
use File::Spec;

# A. Mock Google::Auth
package Google::Auth;
BEGIN { $INC{'Google/Auth.pm'} = 1; }
sub default {
    my ($class, %args) = @_;
    return bless \%args, 'Google::Auth::MockCredentials';
}
package Google::Auth::MockCredentials;
sub get_token {
    return 'mock-token';
}

# B. Mock Google::gRPC::Client
package Google::gRPC::Client;
BEGIN { $INC{'Google/gRPC/Client.pm'} = 1; }
sub new {
    my $class = shift;
    my $args = ( @_ == 1 && ref($_[0]) eq 'HASH' ) ? $_[0] : { @_ };
    return bless $args, $class;
}
sub call {
    my ($self, $args) = @_;
    if ($self->{mock_call}) {
        return $self->{mock_call}->($args);
    }
    die 'No mock_call handler configured in transport!';
}

# C. Fallback Mocks for External Response Classes
BEGIN {
    for my $pkg (qw( Google::Iam::V1::Policy::Policy Google::Longrunning::Operations::Operation Google::Protobuf::Empty::Empty Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::ExternalStorage Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::ListBackupDescriptorsResponse Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::ListExternalStoragesResponse Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::ListLocationDistancesResponse Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::ListLocationsResponse Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::ListRolloutsResponse Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::ListServerOperationsResponse Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::ListServersResponse Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::ListZoneOperationsResponse Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::ListZonesResponse Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::Location Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::LocationDistance Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::Rollout Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::RotateInternalKeysResponse Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::Server Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::Zone )) {
        unless ($pkg->can('new')) {
            no strict 'refs';
            *{"${pkg}::new"} = sub { bless {}, $_[0] };
            $INC{join('/', split('::', $pkg)) . '.pm'} = 1;
        }
    }
}

# D. Main test execution
package main;
use Google::Cloud::Spanner::Admin::Omni::V1::OmniAdminClient;

my $client = Google::Cloud::Spanner::Admin::Omni::V1::OmniAdminClient->new();
ok($client, 'Instantiated generated client');
isa_ok($client->transport, 'Google::gRPC::Client', 'Client transport');

subtest 'create_location method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.spanner.admin.omni.v1.OmniAdmin', 'Correct service path');
        is($args->{method}, 'CreateLocation', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::CreateLocationRequest', 'Request object');
        
        my $response = 'Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::Location'->new();
        return $response;
    };
    
    my $res = $client->create_location();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::Location', 'Response object class');
    done_testing();
};

subtest 'get_location method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.spanner.admin.omni.v1.OmniAdmin', 'Correct service path');
        is($args->{method}, 'GetLocation', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::GetLocationRequest', 'Request object');
        
        my $response = 'Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::Location'->new();
        return $response;
    };
    
    my $res = $client->get_location();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::Location', 'Response object class');
    done_testing();
};

subtest 'list_locations method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.spanner.admin.omni.v1.OmniAdmin', 'Correct service path');
        is($args->{method}, 'ListLocations', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::ListLocationsRequest', 'Request object');
        
        my $response = 'Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::ListLocationsResponse'->new();
        return $response;
    };
    
    my $res = $client->list_locations();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::ListLocationsResponse', 'Response object class');
    done_testing();
};

subtest 'delete_location method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.spanner.admin.omni.v1.OmniAdmin', 'Correct service path');
        is($args->{method}, 'DeleteLocation', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::DeleteLocationRequest', 'Request object');
        
        my $response = 'Google::Protobuf::Empty::Empty'->new();
        return $response;
    };
    
    my $res = $client->delete_location();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Protobuf::Empty::Empty', 'Response object class');
    done_testing();
};

subtest 'create_location_distance method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.spanner.admin.omni.v1.OmniAdmin', 'Correct service path');
        is($args->{method}, 'CreateLocationDistance', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::CreateLocationDistanceRequest', 'Request object');
        
        my $response = 'Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::LocationDistance'->new();
        return $response;
    };
    
    my $res = $client->create_location_distance();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::LocationDistance', 'Response object class');
    done_testing();
};

subtest 'get_location_distance method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.spanner.admin.omni.v1.OmniAdmin', 'Correct service path');
        is($args->{method}, 'GetLocationDistance', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::GetLocationDistanceRequest', 'Request object');
        
        my $response = 'Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::LocationDistance'->new();
        return $response;
    };
    
    my $res = $client->get_location_distance();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::LocationDistance', 'Response object class');
    done_testing();
};

subtest 'list_location_distances method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.spanner.admin.omni.v1.OmniAdmin', 'Correct service path');
        is($args->{method}, 'ListLocationDistances', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::ListLocationDistancesRequest', 'Request object');
        
        my $response = 'Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::ListLocationDistancesResponse'->new();
        return $response;
    };
    
    my $res = $client->list_location_distances();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::ListLocationDistancesResponse', 'Response object class');
    done_testing();
};

subtest 'update_location_distance method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.spanner.admin.omni.v1.OmniAdmin', 'Correct service path');
        is($args->{method}, 'UpdateLocationDistance', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::UpdateLocationDistanceRequest', 'Request object');
        
        my $response = 'Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::LocationDistance'->new();
        return $response;
    };
    
    my $res = $client->update_location_distance();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::LocationDistance', 'Response object class');
    done_testing();
};

subtest 'delete_location_distance method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.spanner.admin.omni.v1.OmniAdmin', 'Correct service path');
        is($args->{method}, 'DeleteLocationDistance', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::DeleteLocationDistanceRequest', 'Request object');
        
        my $response = 'Google::Protobuf::Empty::Empty'->new();
        return $response;
    };
    
    my $res = $client->delete_location_distance();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Protobuf::Empty::Empty', 'Response object class');
    done_testing();
};

subtest 'get_zone method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.spanner.admin.omni.v1.OmniAdmin', 'Correct service path');
        is($args->{method}, 'GetZone', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::GetZoneRequest', 'Request object');
        
        my $response = 'Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::Zone'->new();
        return $response;
    };
    
    my $res = $client->get_zone();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::Zone', 'Response object class');
    done_testing();
};

subtest 'list_zones method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.spanner.admin.omni.v1.OmniAdmin', 'Correct service path');
        is($args->{method}, 'ListZones', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::ListZonesRequest', 'Request object');
        
        my $response = 'Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::ListZonesResponse'->new();
        return $response;
    };
    
    my $res = $client->list_zones();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::ListZonesResponse', 'Response object class');
    done_testing();
};

subtest 'list_zone_operations method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.spanner.admin.omni.v1.OmniAdmin', 'Correct service path');
        is($args->{method}, 'ListZoneOperations', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::ListZoneOperationsRequest', 'Request object');
        
        my $response = 'Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::ListZoneOperationsResponse'->new();
        return $response;
    };
    
    my $res = $client->list_zone_operations();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::ListZoneOperationsResponse', 'Response object class');
    done_testing();
};

subtest 'create_zone method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.spanner.admin.omni.v1.OmniAdmin', 'Correct service path');
        is($args->{method}, 'CreateZone', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::CreateZoneRequest', 'Request object');
        
        my $response = 'Google::Longrunning::Operations::Operation'->new();
        return $response;
    };
    
    my $res = $client->create_zone();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Longrunning::Operations::Operation', 'Response object class');
    done_testing();
};

subtest 'delete_zone method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.spanner.admin.omni.v1.OmniAdmin', 'Correct service path');
        is($args->{method}, 'DeleteZone', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::DeleteZoneRequest', 'Request object');
        
        my $response = 'Google::Longrunning::Operations::Operation'->new();
        return $response;
    };
    
    my $res = $client->delete_zone();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Longrunning::Operations::Operation', 'Response object class');
    done_testing();
};

subtest 'create_server method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.spanner.admin.omni.v1.OmniAdmin', 'Correct service path');
        is($args->{method}, 'CreateServer', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::CreateServerRequest', 'Request object');
        
        my $response = 'Google::Longrunning::Operations::Operation'->new();
        return $response;
    };
    
    my $res = $client->create_server();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Longrunning::Operations::Operation', 'Response object class');
    done_testing();
};

subtest 'get_server method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.spanner.admin.omni.v1.OmniAdmin', 'Correct service path');
        is($args->{method}, 'GetServer', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::GetServerRequest', 'Request object');
        
        my $response = 'Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::Server'->new();
        return $response;
    };
    
    my $res = $client->get_server();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::Server', 'Response object class');
    done_testing();
};

subtest 'list_servers method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.spanner.admin.omni.v1.OmniAdmin', 'Correct service path');
        is($args->{method}, 'ListServers', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::ListServersRequest', 'Request object');
        
        my $response = 'Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::ListServersResponse'->new();
        return $response;
    };
    
    my $res = $client->list_servers();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::ListServersResponse', 'Response object class');
    done_testing();
};

subtest 'delete_server method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.spanner.admin.omni.v1.OmniAdmin', 'Correct service path');
        is($args->{method}, 'DeleteServer', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::DeleteServerRequest', 'Request object');
        
        my $response = 'Google::Longrunning::Operations::Operation'->new();
        return $response;
    };
    
    my $res = $client->delete_server();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Longrunning::Operations::Operation', 'Response object class');
    done_testing();
};

subtest 'list_server_operations method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.spanner.admin.omni.v1.OmniAdmin', 'Correct service path');
        is($args->{method}, 'ListServerOperations', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::ListServerOperationsRequest', 'Request object');
        
        my $response = 'Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::ListServerOperationsResponse'->new();
        return $response;
    };
    
    my $res = $client->list_server_operations();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::ListServerOperationsResponse', 'Response object class');
    done_testing();
};

subtest 'create_external_storage method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.spanner.admin.omni.v1.OmniAdmin', 'Correct service path');
        is($args->{method}, 'CreateExternalStorage', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::CreateExternalStorageRequest', 'Request object');
        
        my $response = 'Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::ExternalStorage'->new();
        return $response;
    };
    
    my $res = $client->create_external_storage();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::ExternalStorage', 'Response object class');
    done_testing();
};

subtest 'list_backup_descriptors method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.spanner.admin.omni.v1.OmniAdmin', 'Correct service path');
        is($args->{method}, 'ListBackupDescriptors', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::ListBackupDescriptorsRequest', 'Request object');
        
        my $response = 'Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::ListBackupDescriptorsResponse'->new();
        return $response;
    };
    
    my $res = $client->list_backup_descriptors();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::ListBackupDescriptorsResponse', 'Response object class');
    done_testing();
};

subtest 'get_external_storage method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.spanner.admin.omni.v1.OmniAdmin', 'Correct service path');
        is($args->{method}, 'GetExternalStorage', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::GetExternalStorageRequest', 'Request object');
        
        my $response = 'Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::ExternalStorage'->new();
        return $response;
    };
    
    my $res = $client->get_external_storage();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::ExternalStorage', 'Response object class');
    done_testing();
};

subtest 'delete_external_storage method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.spanner.admin.omni.v1.OmniAdmin', 'Correct service path');
        is($args->{method}, 'DeleteExternalStorage', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::DeleteExternalStorageRequest', 'Request object');
        
        my $response = 'Google::Protobuf::Empty::Empty'->new();
        return $response;
    };
    
    my $res = $client->delete_external_storage();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Protobuf::Empty::Empty', 'Response object class');
    done_testing();
};

subtest 'list_external_storages method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.spanner.admin.omni.v1.OmniAdmin', 'Correct service path');
        is($args->{method}, 'ListExternalStorages', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::ListExternalStoragesRequest', 'Request object');
        
        my $response = 'Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::ListExternalStoragesResponse'->new();
        return $response;
    };
    
    my $res = $client->list_external_storages();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::ListExternalStoragesResponse', 'Response object class');
    done_testing();
};

subtest 'get_iam_policy method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.spanner.admin.omni.v1.OmniAdmin', 'Correct service path');
        is($args->{method}, 'GetIamPolicy', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Iam::V1::IamPolicy::GetIamPolicyRequest', 'Request object');
        
        my $response = 'Google::Iam::V1::Policy::Policy'->new();
        return $response;
    };
    
    my $res = $client->get_iam_policy();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Iam::V1::Policy::Policy', 'Response object class');
    done_testing();
};

subtest 'set_iam_policy method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.spanner.admin.omni.v1.OmniAdmin', 'Correct service path');
        is($args->{method}, 'SetIamPolicy', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Iam::V1::IamPolicy::SetIamPolicyRequest', 'Request object');
        
        my $response = 'Google::Iam::V1::Policy::Policy'->new();
        return $response;
    };
    
    my $res = $client->set_iam_policy();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Iam::V1::Policy::Policy', 'Response object class');
    done_testing();
};

subtest 'import_backup method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.spanner.admin.omni.v1.OmniAdmin', 'Correct service path');
        is($args->{method}, 'ImportBackup', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::ImportBackupRequest', 'Request object');
        
        my $response = 'Google::Longrunning::Operations::Operation'->new();
        return $response;
    };
    
    my $res = $client->import_backup();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Longrunning::Operations::Operation', 'Response object class');
    done_testing();
};

subtest 'list_rollouts method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.spanner.admin.omni.v1.OmniAdmin', 'Correct service path');
        is($args->{method}, 'ListRollouts', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::ListRolloutsRequest', 'Request object');
        
        my $response = 'Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::ListRolloutsResponse'->new();
        return $response;
    };
    
    my $res = $client->list_rollouts();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::ListRolloutsResponse', 'Response object class');
    done_testing();
};

subtest 'get_rollout method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.spanner.admin.omni.v1.OmniAdmin', 'Correct service path');
        is($args->{method}, 'GetRollout', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::GetRolloutRequest', 'Request object');
        
        my $response = 'Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::Rollout'->new();
        return $response;
    };
    
    my $res = $client->get_rollout();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::Rollout', 'Response object class');
    done_testing();
};

subtest 'schedule_rollout_phase method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.spanner.admin.omni.v1.OmniAdmin', 'Correct service path');
        is($args->{method}, 'ScheduleRolloutPhase', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::ScheduleRolloutPhaseRequest', 'Request object');
        
        my $response = 'Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::Rollout'->new();
        return $response;
    };
    
    my $res = $client->schedule_rollout_phase();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::Rollout', 'Response object class');
    done_testing();
};

subtest 'abort_rollout method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.spanner.admin.omni.v1.OmniAdmin', 'Correct service path');
        is($args->{method}, 'AbortRollout', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::AbortRolloutRequest', 'Request object');
        
        my $response = 'Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::Rollout'->new();
        return $response;
    };
    
    my $res = $client->abort_rollout();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::Rollout', 'Response object class');
    done_testing();
};

subtest 'rollback_rollout method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.spanner.admin.omni.v1.OmniAdmin', 'Correct service path');
        is($args->{method}, 'RollbackRollout', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::RollbackRolloutRequest', 'Request object');
        
        my $response = 'Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::Rollout'->new();
        return $response;
    };
    
    my $res = $client->rollback_rollout();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::Rollout', 'Response object class');
    done_testing();
};

subtest 'rotate_internal_keys method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.spanner.admin.omni.v1.OmniAdmin', 'Correct service path');
        is($args->{method}, 'RotateInternalKeys', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::RotateInternalKeysRequest', 'Request object');
        
        my $response = 'Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::RotateInternalKeysResponse'->new();
        return $response;
    };
    
    my $res = $client->rotate_internal_keys();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Spanner::Admin::Omni::V1::SpannerOmniAdmin::RotateInternalKeysResponse', 'Response object class');
    done_testing();
};

done_testing();
