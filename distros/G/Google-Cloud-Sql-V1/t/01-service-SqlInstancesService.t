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
    for my $pkg (qw( Google::Cloud::Sql::V1::CloudSqlInstances::DatabaseInstance Google::Cloud::Sql::V1::CloudSqlInstances::InstancesListEntraIdCertificatesResponse Google::Cloud::Sql::V1::CloudSqlInstances::InstancesListResponse Google::Cloud::Sql::V1::CloudSqlInstances::InstancesListServerCasResponse Google::Cloud::Sql::V1::CloudSqlInstances::InstancesListServerCertificatesResponse Google::Cloud::Sql::V1::CloudSqlInstances::SqlInstancesAcquireSsrsLeaseResponse Google::Cloud::Sql::V1::CloudSqlInstances::SqlInstancesExecuteSqlResponse Google::Cloud::Sql::V1::CloudSqlInstances::SqlInstancesGetDiskShrinkConfigResponse Google::Cloud::Sql::V1::CloudSqlInstances::SqlInstancesGetLatestRecoveryTimeResponse Google::Cloud::Sql::V1::CloudSqlInstances::SqlInstancesReleaseSsrsLeaseResponse Google::Cloud::Sql::V1::CloudSqlInstances::SqlInstancesVerifyExternalSyncSettingsResponse Google::Cloud::Sql::V1::CloudSqlResources::Operation Google::Cloud::Sql::V1::CloudSqlResources::SslCert )) {
        unless ($pkg->can('new')) {
            no strict 'refs';
            *{"${pkg}::new"} = sub { bless {}, $_[0] };
            $INC{join('/', split('::', $pkg)) . '.pm'} = 1;
        }
    }
}

# D. Main test execution
package main;
use Google::Cloud::Sql::V1::SqlInstancesServiceClient;

my $client = Google::Cloud::Sql::V1::SqlInstancesServiceClient->new( credentials => 'dummy' );
ok($client, 'Instantiated generated client');
isa_ok($client->transport, 'Google::gRPC::Client', 'Client transport');

subtest 'add_server_ca method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.sql.v1.SqlInstancesService', 'Correct service path');
        is($args->{method}, 'AddServerCa', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Sql::V1::CloudSqlInstances::SqlInstancesAddServerCaRequest', 'Request object');
        
        my $response = 'Google::Cloud::Sql::V1::CloudSqlResources::Operation'->new();
        return $response;
    };
    
    my $res = $client->add_server_ca();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Sql::V1::CloudSqlResources::Operation', 'Response object class');
    done_testing();
};

subtest 'add_server_certificate method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.sql.v1.SqlInstancesService', 'Correct service path');
        is($args->{method}, 'AddServerCertificate', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Sql::V1::CloudSqlInstances::SqlInstancesAddServerCertificateRequest', 'Request object');
        
        my $response = 'Google::Cloud::Sql::V1::CloudSqlResources::Operation'->new();
        return $response;
    };
    
    my $res = $client->add_server_certificate();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Sql::V1::CloudSqlResources::Operation', 'Response object class');
    done_testing();
};

subtest 'add_entra_id_certificate method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.sql.v1.SqlInstancesService', 'Correct service path');
        is($args->{method}, 'AddEntraIdCertificate', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Sql::V1::CloudSqlInstances::SqlInstancesAddEntraIdCertificateRequest', 'Request object');
        
        my $response = 'Google::Cloud::Sql::V1::CloudSqlResources::Operation'->new();
        return $response;
    };
    
    my $res = $client->add_entra_id_certificate();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Sql::V1::CloudSqlResources::Operation', 'Response object class');
    done_testing();
};

subtest 'clone method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.sql.v1.SqlInstancesService', 'Correct service path');
        is($args->{method}, 'Clone', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Sql::V1::CloudSqlInstances::SqlInstancesCloneRequest', 'Request object');
        
        my $response = 'Google::Cloud::Sql::V1::CloudSqlResources::Operation'->new();
        return $response;
    };
    
    my $res = $client->clone();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Sql::V1::CloudSqlResources::Operation', 'Response object class');
    done_testing();
};

subtest 'delete method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.sql.v1.SqlInstancesService', 'Correct service path');
        is($args->{method}, 'Delete', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Sql::V1::CloudSqlInstances::SqlInstancesDeleteRequest', 'Request object');
        
        my $response = 'Google::Cloud::Sql::V1::CloudSqlResources::Operation'->new();
        return $response;
    };
    
    my $res = $client->delete();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Sql::V1::CloudSqlResources::Operation', 'Response object class');
    done_testing();
};

subtest 'demote_master method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.sql.v1.SqlInstancesService', 'Correct service path');
        is($args->{method}, 'DemoteMaster', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Sql::V1::CloudSqlInstances::SqlInstancesDemoteMasterRequest', 'Request object');
        
        my $response = 'Google::Cloud::Sql::V1::CloudSqlResources::Operation'->new();
        return $response;
    };
    
    my $res = $client->demote_master();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Sql::V1::CloudSqlResources::Operation', 'Response object class');
    done_testing();
};

subtest 'demote method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.sql.v1.SqlInstancesService', 'Correct service path');
        is($args->{method}, 'Demote', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Sql::V1::CloudSqlInstances::SqlInstancesDemoteRequest', 'Request object');
        
        my $response = 'Google::Cloud::Sql::V1::CloudSqlResources::Operation'->new();
        return $response;
    };
    
    my $res = $client->demote();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Sql::V1::CloudSqlResources::Operation', 'Response object class');
    done_testing();
};

subtest 'export method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.sql.v1.SqlInstancesService', 'Correct service path');
        is($args->{method}, 'Export', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Sql::V1::CloudSqlInstances::SqlInstancesExportRequest', 'Request object');
        
        my $response = 'Google::Cloud::Sql::V1::CloudSqlResources::Operation'->new();
        return $response;
    };
    
    my $res = $client->export();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Sql::V1::CloudSqlResources::Operation', 'Response object class');
    done_testing();
};

subtest 'failover method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.sql.v1.SqlInstancesService', 'Correct service path');
        is($args->{method}, 'Failover', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Sql::V1::CloudSqlInstances::SqlInstancesFailoverRequest', 'Request object');
        
        my $response = 'Google::Cloud::Sql::V1::CloudSqlResources::Operation'->new();
        return $response;
    };
    
    my $res = $client->failover();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Sql::V1::CloudSqlResources::Operation', 'Response object class');
    done_testing();
};

subtest 'reencrypt method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.sql.v1.SqlInstancesService', 'Correct service path');
        is($args->{method}, 'Reencrypt', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Sql::V1::CloudSqlInstances::SqlInstancesReencryptRequest', 'Request object');
        
        my $response = 'Google::Cloud::Sql::V1::CloudSqlResources::Operation'->new();
        return $response;
    };
    
    my $res = $client->reencrypt();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Sql::V1::CloudSqlResources::Operation', 'Response object class');
    done_testing();
};

subtest 'get method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.sql.v1.SqlInstancesService', 'Correct service path');
        is($args->{method}, 'Get', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Sql::V1::CloudSqlInstances::SqlInstancesGetRequest', 'Request object');
        
        my $response = 'Google::Cloud::Sql::V1::CloudSqlInstances::DatabaseInstance'->new();
        return $response;
    };
    
    my $res = $client->get();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Sql::V1::CloudSqlInstances::DatabaseInstance', 'Response object class');
    done_testing();
};

subtest 'import_instances method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.sql.v1.SqlInstancesService', 'Correct service path');
        is($args->{method}, 'Import', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Sql::V1::CloudSqlInstances::SqlInstancesImportRequest', 'Request object');
        
        my $response = 'Google::Cloud::Sql::V1::CloudSqlResources::Operation'->new();
        return $response;
    };
    
    my $res = $client->import_instances();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Sql::V1::CloudSqlResources::Operation', 'Response object class');
    done_testing();
};

subtest 'insert method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.sql.v1.SqlInstancesService', 'Correct service path');
        is($args->{method}, 'Insert', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Sql::V1::CloudSqlInstances::SqlInstancesInsertRequest', 'Request object');
        
        my $response = 'Google::Cloud::Sql::V1::CloudSqlResources::Operation'->new();
        return $response;
    };
    
    my $res = $client->insert();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Sql::V1::CloudSqlResources::Operation', 'Response object class');
    done_testing();
};

subtest 'list method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.sql.v1.SqlInstancesService', 'Correct service path');
        is($args->{method}, 'List', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Sql::V1::CloudSqlInstances::SqlInstancesListRequest', 'Request object');
        
        my $response = 'Google::Cloud::Sql::V1::CloudSqlInstances::InstancesListResponse'->new();
        return $response;
    };
    
    my $res = $client->list();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Sql::V1::CloudSqlInstances::InstancesListResponse', 'Response object class');
    done_testing();
};

subtest 'list_server_cas method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.sql.v1.SqlInstancesService', 'Correct service path');
        is($args->{method}, 'ListServerCas', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Sql::V1::CloudSqlInstances::SqlInstancesListServerCasRequest', 'Request object');
        
        my $response = 'Google::Cloud::Sql::V1::CloudSqlInstances::InstancesListServerCasResponse'->new();
        return $response;
    };
    
    my $res = $client->list_server_cas();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Sql::V1::CloudSqlInstances::InstancesListServerCasResponse', 'Response object class');
    done_testing();
};

subtest 'list_server_certificates method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.sql.v1.SqlInstancesService', 'Correct service path');
        is($args->{method}, 'ListServerCertificates', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Sql::V1::CloudSqlInstances::SqlInstancesListServerCertificatesRequest', 'Request object');
        
        my $response = 'Google::Cloud::Sql::V1::CloudSqlInstances::InstancesListServerCertificatesResponse'->new();
        return $response;
    };
    
    my $res = $client->list_server_certificates();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Sql::V1::CloudSqlInstances::InstancesListServerCertificatesResponse', 'Response object class');
    done_testing();
};

subtest 'list_entra_id_certificates method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.sql.v1.SqlInstancesService', 'Correct service path');
        is($args->{method}, 'ListEntraIdCertificates', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Sql::V1::CloudSqlInstances::SqlInstancesListEntraIdCertificatesRequest', 'Request object');
        
        my $response = 'Google::Cloud::Sql::V1::CloudSqlInstances::InstancesListEntraIdCertificatesResponse'->new();
        return $response;
    };
    
    my $res = $client->list_entra_id_certificates();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Sql::V1::CloudSqlInstances::InstancesListEntraIdCertificatesResponse', 'Response object class');
    done_testing();
};

subtest 'patch method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.sql.v1.SqlInstancesService', 'Correct service path');
        is($args->{method}, 'Patch', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Sql::V1::CloudSqlInstances::SqlInstancesPatchRequest', 'Request object');
        
        my $response = 'Google::Cloud::Sql::V1::CloudSqlResources::Operation'->new();
        return $response;
    };
    
    my $res = $client->patch();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Sql::V1::CloudSqlResources::Operation', 'Response object class');
    done_testing();
};

subtest 'promote_replica method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.sql.v1.SqlInstancesService', 'Correct service path');
        is($args->{method}, 'PromoteReplica', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Sql::V1::CloudSqlInstances::SqlInstancesPromoteReplicaRequest', 'Request object');
        
        my $response = 'Google::Cloud::Sql::V1::CloudSqlResources::Operation'->new();
        return $response;
    };
    
    my $res = $client->promote_replica();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Sql::V1::CloudSqlResources::Operation', 'Response object class');
    done_testing();
};

subtest 'switchover method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.sql.v1.SqlInstancesService', 'Correct service path');
        is($args->{method}, 'Switchover', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Sql::V1::CloudSqlInstances::SqlInstancesSwitchoverRequest', 'Request object');
        
        my $response = 'Google::Cloud::Sql::V1::CloudSqlResources::Operation'->new();
        return $response;
    };
    
    my $res = $client->switchover();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Sql::V1::CloudSqlResources::Operation', 'Response object class');
    done_testing();
};

subtest 'reset_ssl_config method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.sql.v1.SqlInstancesService', 'Correct service path');
        is($args->{method}, 'ResetSslConfig', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Sql::V1::CloudSqlInstances::SqlInstancesResetSslConfigRequest', 'Request object');
        
        my $response = 'Google::Cloud::Sql::V1::CloudSqlResources::Operation'->new();
        return $response;
    };
    
    my $res = $client->reset_ssl_config();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Sql::V1::CloudSqlResources::Operation', 'Response object class');
    done_testing();
};

subtest 'restart method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.sql.v1.SqlInstancesService', 'Correct service path');
        is($args->{method}, 'Restart', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Sql::V1::CloudSqlInstances::SqlInstancesRestartRequest', 'Request object');
        
        my $response = 'Google::Cloud::Sql::V1::CloudSqlResources::Operation'->new();
        return $response;
    };
    
    my $res = $client->restart();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Sql::V1::CloudSqlResources::Operation', 'Response object class');
    done_testing();
};

subtest 'restore_backup method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.sql.v1.SqlInstancesService', 'Correct service path');
        is($args->{method}, 'RestoreBackup', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Sql::V1::CloudSqlInstances::SqlInstancesRestoreBackupRequest', 'Request object');
        
        my $response = 'Google::Cloud::Sql::V1::CloudSqlResources::Operation'->new();
        return $response;
    };
    
    my $res = $client->restore_backup();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Sql::V1::CloudSqlResources::Operation', 'Response object class');
    done_testing();
};

subtest 'rotate_server_ca method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.sql.v1.SqlInstancesService', 'Correct service path');
        is($args->{method}, 'RotateServerCa', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Sql::V1::CloudSqlInstances::SqlInstancesRotateServerCaRequest', 'Request object');
        
        my $response = 'Google::Cloud::Sql::V1::CloudSqlResources::Operation'->new();
        return $response;
    };
    
    my $res = $client->rotate_server_ca();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Sql::V1::CloudSqlResources::Operation', 'Response object class');
    done_testing();
};

subtest 'rotate_server_certificate method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.sql.v1.SqlInstancesService', 'Correct service path');
        is($args->{method}, 'RotateServerCertificate', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Sql::V1::CloudSqlInstances::SqlInstancesRotateServerCertificateRequest', 'Request object');
        
        my $response = 'Google::Cloud::Sql::V1::CloudSqlResources::Operation'->new();
        return $response;
    };
    
    my $res = $client->rotate_server_certificate();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Sql::V1::CloudSqlResources::Operation', 'Response object class');
    done_testing();
};

subtest 'rotate_entra_id_certificate method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.sql.v1.SqlInstancesService', 'Correct service path');
        is($args->{method}, 'RotateEntraIdCertificate', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Sql::V1::CloudSqlInstances::SqlInstancesRotateEntraIdCertificateRequest', 'Request object');
        
        my $response = 'Google::Cloud::Sql::V1::CloudSqlResources::Operation'->new();
        return $response;
    };
    
    my $res = $client->rotate_entra_id_certificate();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Sql::V1::CloudSqlResources::Operation', 'Response object class');
    done_testing();
};

subtest 'start_replica method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.sql.v1.SqlInstancesService', 'Correct service path');
        is($args->{method}, 'StartReplica', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Sql::V1::CloudSqlInstances::SqlInstancesStartReplicaRequest', 'Request object');
        
        my $response = 'Google::Cloud::Sql::V1::CloudSqlResources::Operation'->new();
        return $response;
    };
    
    my $res = $client->start_replica();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Sql::V1::CloudSqlResources::Operation', 'Response object class');
    done_testing();
};

subtest 'stop_replica method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.sql.v1.SqlInstancesService', 'Correct service path');
        is($args->{method}, 'StopReplica', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Sql::V1::CloudSqlInstances::SqlInstancesStopReplicaRequest', 'Request object');
        
        my $response = 'Google::Cloud::Sql::V1::CloudSqlResources::Operation'->new();
        return $response;
    };
    
    my $res = $client->stop_replica();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Sql::V1::CloudSqlResources::Operation', 'Response object class');
    done_testing();
};

subtest 'truncate_log method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.sql.v1.SqlInstancesService', 'Correct service path');
        is($args->{method}, 'TruncateLog', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Sql::V1::CloudSqlInstances::SqlInstancesTruncateLogRequest', 'Request object');
        
        my $response = 'Google::Cloud::Sql::V1::CloudSqlResources::Operation'->new();
        return $response;
    };
    
    my $res = $client->truncate_log();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Sql::V1::CloudSqlResources::Operation', 'Response object class');
    done_testing();
};

subtest 'update method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.sql.v1.SqlInstancesService', 'Correct service path');
        is($args->{method}, 'Update', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Sql::V1::CloudSqlInstances::SqlInstancesUpdateRequest', 'Request object');
        
        my $response = 'Google::Cloud::Sql::V1::CloudSqlResources::Operation'->new();
        return $response;
    };
    
    my $res = $client->update();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Sql::V1::CloudSqlResources::Operation', 'Response object class');
    done_testing();
};

subtest 'create_ephemeral method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.sql.v1.SqlInstancesService', 'Correct service path');
        is($args->{method}, 'CreateEphemeral', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Sql::V1::CloudSqlInstances::SqlInstancesCreateEphemeralCertRequest', 'Request object');
        
        my $response = 'Google::Cloud::Sql::V1::CloudSqlResources::SslCert'->new();
        return $response;
    };
    
    my $res = $client->create_ephemeral();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Sql::V1::CloudSqlResources::SslCert', 'Response object class');
    done_testing();
};

subtest 'reschedule_maintenance method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.sql.v1.SqlInstancesService', 'Correct service path');
        is($args->{method}, 'RescheduleMaintenance', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Sql::V1::CloudSqlInstances::SqlInstancesRescheduleMaintenanceRequest', 'Request object');
        
        my $response = 'Google::Cloud::Sql::V1::CloudSqlResources::Operation'->new();
        return $response;
    };
    
    my $res = $client->reschedule_maintenance();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Sql::V1::CloudSqlResources::Operation', 'Response object class');
    done_testing();
};

subtest 'verify_external_sync_settings method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.sql.v1.SqlInstancesService', 'Correct service path');
        is($args->{method}, 'VerifyExternalSyncSettings', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Sql::V1::CloudSqlInstances::SqlInstancesVerifyExternalSyncSettingsRequest', 'Request object');
        
        my $response = 'Google::Cloud::Sql::V1::CloudSqlInstances::SqlInstancesVerifyExternalSyncSettingsResponse'->new();
        return $response;
    };
    
    my $res = $client->verify_external_sync_settings();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Sql::V1::CloudSqlInstances::SqlInstancesVerifyExternalSyncSettingsResponse', 'Response object class');
    done_testing();
};

subtest 'start_external_sync method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.sql.v1.SqlInstancesService', 'Correct service path');
        is($args->{method}, 'StartExternalSync', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Sql::V1::CloudSqlInstances::SqlInstancesStartExternalSyncRequest', 'Request object');
        
        my $response = 'Google::Cloud::Sql::V1::CloudSqlResources::Operation'->new();
        return $response;
    };
    
    my $res = $client->start_external_sync();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Sql::V1::CloudSqlResources::Operation', 'Response object class');
    done_testing();
};

subtest 'perform_disk_shrink method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.sql.v1.SqlInstancesService', 'Correct service path');
        is($args->{method}, 'PerformDiskShrink', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Sql::V1::CloudSqlInstances::SqlInstancesPerformDiskShrinkRequest', 'Request object');
        
        my $response = 'Google::Cloud::Sql::V1::CloudSqlResources::Operation'->new();
        return $response;
    };
    
    my $res = $client->perform_disk_shrink();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Sql::V1::CloudSqlResources::Operation', 'Response object class');
    done_testing();
};

subtest 'get_disk_shrink_config method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.sql.v1.SqlInstancesService', 'Correct service path');
        is($args->{method}, 'GetDiskShrinkConfig', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Sql::V1::CloudSqlInstances::SqlInstancesGetDiskShrinkConfigRequest', 'Request object');
        
        my $response = 'Google::Cloud::Sql::V1::CloudSqlInstances::SqlInstancesGetDiskShrinkConfigResponse'->new();
        return $response;
    };
    
    my $res = $client->get_disk_shrink_config();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Sql::V1::CloudSqlInstances::SqlInstancesGetDiskShrinkConfigResponse', 'Response object class');
    done_testing();
};

subtest 'reset_replica_size method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.sql.v1.SqlInstancesService', 'Correct service path');
        is($args->{method}, 'ResetReplicaSize', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Sql::V1::CloudSqlInstances::SqlInstancesResetReplicaSizeRequest', 'Request object');
        
        my $response = 'Google::Cloud::Sql::V1::CloudSqlResources::Operation'->new();
        return $response;
    };
    
    my $res = $client->reset_replica_size();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Sql::V1::CloudSqlResources::Operation', 'Response object class');
    done_testing();
};

subtest 'get_latest_recovery_time method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.sql.v1.SqlInstancesService', 'Correct service path');
        is($args->{method}, 'GetLatestRecoveryTime', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Sql::V1::CloudSqlInstances::SqlInstancesGetLatestRecoveryTimeRequest', 'Request object');
        
        my $response = 'Google::Cloud::Sql::V1::CloudSqlInstances::SqlInstancesGetLatestRecoveryTimeResponse'->new();
        return $response;
    };
    
    my $res = $client->get_latest_recovery_time();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Sql::V1::CloudSqlInstances::SqlInstancesGetLatestRecoveryTimeResponse', 'Response object class');
    done_testing();
};

subtest 'execute_sql method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.sql.v1.SqlInstancesService', 'Correct service path');
        is($args->{method}, 'ExecuteSql', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Sql::V1::CloudSqlInstances::SqlInstancesExecuteSqlRequest', 'Request object');
        
        my $response = 'Google::Cloud::Sql::V1::CloudSqlInstances::SqlInstancesExecuteSqlResponse'->new();
        return $response;
    };
    
    my $res = $client->execute_sql();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Sql::V1::CloudSqlInstances::SqlInstancesExecuteSqlResponse', 'Response object class');
    done_testing();
};

subtest 'acquire_ssrs_lease method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.sql.v1.SqlInstancesService', 'Correct service path');
        is($args->{method}, 'AcquireSsrsLease', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Sql::V1::CloudSqlInstances::SqlInstancesAcquireSsrsLeaseRequest', 'Request object');
        
        my $response = 'Google::Cloud::Sql::V1::CloudSqlInstances::SqlInstancesAcquireSsrsLeaseResponse'->new();
        return $response;
    };
    
    my $res = $client->acquire_ssrs_lease();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Sql::V1::CloudSqlInstances::SqlInstancesAcquireSsrsLeaseResponse', 'Response object class');
    done_testing();
};

subtest 'release_ssrs_lease method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.sql.v1.SqlInstancesService', 'Correct service path');
        is($args->{method}, 'ReleaseSsrsLease', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Sql::V1::CloudSqlInstances::SqlInstancesReleaseSsrsLeaseRequest', 'Request object');
        
        my $response = 'Google::Cloud::Sql::V1::CloudSqlInstances::SqlInstancesReleaseSsrsLeaseResponse'->new();
        return $response;
    };
    
    my $res = $client->release_ssrs_lease();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Sql::V1::CloudSqlInstances::SqlInstancesReleaseSsrsLeaseResponse', 'Response object class');
    done_testing();
};

subtest 'pre_check_major_version_upgrade method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.sql.v1.SqlInstancesService', 'Correct service path');
        is($args->{method}, 'PreCheckMajorVersionUpgrade', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Sql::V1::CloudSqlInstances::SqlInstancesPreCheckMajorVersionUpgradeRequest', 'Request object');
        
        my $response = 'Google::Cloud::Sql::V1::CloudSqlResources::Operation'->new();
        return $response;
    };
    
    my $res = $client->pre_check_major_version_upgrade();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Sql::V1::CloudSqlResources::Operation', 'Response object class');
    done_testing();
};

subtest 'point_in_time_restore method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.sql.v1.SqlInstancesService', 'Correct service path');
        is($args->{method}, 'PointInTimeRestore', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Sql::V1::CloudSqlInstances::SqlInstancesPointInTimeRestoreRequest', 'Request object');
        
        my $response = 'Google::Cloud::Sql::V1::CloudSqlResources::Operation'->new();
        return $response;
    };
    
    my $res = $client->point_in_time_restore();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Sql::V1::CloudSqlResources::Operation', 'Response object class');
    done_testing();
};

done_testing();
