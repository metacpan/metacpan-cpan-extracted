package Google::Cloud::Sql::V1beta4;

use strict;
use warnings;
use Moo;
use Google::gRPC::Client;
use Google::Cloud::REST::Client;
use Google::Auth;
use Carp qw(croak);

use Protobuf;
use Google::Api::Common;
use Google::Cloud::Sql::V1beta4::CloudSqlIamPolicies;
use Google::Cloud::Sql::V1beta4::CloudSqlTiers;
use Google::Cloud::Sql::V1beta4::CloudSqlData;
use Google::Cloud::Sql::V1beta4::CloudSqlResources;
use Google::Cloud::Sql::V1beta4::CloudSqlBlueGreenDeployments;
use Google::Cloud::Sql::V1beta4::CloudSql;
use Google::Cloud::Sql::V1beta4::CloudSqlUsers;
use Google::Cloud::Sql::V1beta4::CloudSqlConnect;
use Google::Cloud::Sql::V1beta4::CloudSqlWorkloadCaptures;

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

    my $target = 'sqladmin.googleapis.com:443';
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

sub delete {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Sql::V1beta4::CloudSql::SqlBackupRunsDeleteRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Sql::V1beta4::CloudSqlResources::Operation';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.sql.v1beta4.SqlBackupRunsService/Delete',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.sql.v1beta4.SqlBackupRunsService',
        method         => 'Delete',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub get {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Sql::V1beta4::CloudSql::SqlBackupRunsGetRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Sql::V1beta4::CloudSqlResources::BackupRun';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.sql.v1beta4.SqlBackupRunsService/Get',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.sql.v1beta4.SqlBackupRunsService',
        method         => 'Get',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub insert {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Sql::V1beta4::CloudSql::SqlBackupRunsInsertRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Sql::V1beta4::CloudSqlResources::Operation';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.sql.v1beta4.SqlBackupRunsService/Insert',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.sql.v1beta4.SqlBackupRunsService',
        method         => 'Insert',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub list {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Sql::V1beta4::CloudSql::SqlBackupRunsListRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Sql::V1beta4::CloudSqlResources::BackupRunsListResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.sql.v1beta4.SqlBackupRunsService/List',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.sql.v1beta4.SqlBackupRunsService',
        method         => 'List',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub patch {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Sql::V1beta4::CloudSql::SqlDatabasesUpdateRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Sql::V1beta4::CloudSqlResources::Operation';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.sql.v1beta4.SqlDatabasesService/Patch',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.sql.v1beta4.SqlDatabasesService',
        method         => 'Patch',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub update {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Sql::V1beta4::CloudSql::SqlDatabasesUpdateRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Sql::V1beta4::CloudSqlResources::Operation';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.sql.v1beta4.SqlDatabasesService/Update',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.sql.v1beta4.SqlDatabasesService',
        method         => 'Update',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub add_server_ca {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Sql::V1beta4::CloudSql::SqlInstancesAddServerCaRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Sql::V1beta4::CloudSqlResources::Operation';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.sql.v1beta4.SqlInstancesService/AddServerCa',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.sql.v1beta4.SqlInstancesService',
        method         => 'AddServerCa',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub add_server_certificate {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Sql::V1beta4::CloudSql::SqlInstancesAddServerCertificateRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Sql::V1beta4::CloudSqlResources::Operation';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.sql.v1beta4.SqlInstancesService/AddServerCertificate',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.sql.v1beta4.SqlInstancesService',
        method         => 'AddServerCertificate',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub add_entra_id_certificate {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Sql::V1beta4::CloudSql::SqlInstancesAddEntraIdCertificateRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Sql::V1beta4::CloudSqlResources::Operation';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.sql.v1beta4.SqlInstancesService/AddEntraIdCertificate',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.sql.v1beta4.SqlInstancesService',
        method         => 'AddEntraIdCertificate',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub clone {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Sql::V1beta4::CloudSql::SqlInstancesCloneRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Sql::V1beta4::CloudSqlResources::Operation';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.sql.v1beta4.SqlInstancesService/Clone',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.sql.v1beta4.SqlInstancesService',
        method         => 'Clone',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub demote_master {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Sql::V1beta4::CloudSql::SqlInstancesDemoteMasterRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Sql::V1beta4::CloudSqlResources::Operation';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.sql.v1beta4.SqlInstancesService/DemoteMaster',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.sql.v1beta4.SqlInstancesService',
        method         => 'DemoteMaster',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub demote {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Sql::V1beta4::CloudSql::SqlInstancesDemoteRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Sql::V1beta4::CloudSqlResources::Operation';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.sql.v1beta4.SqlInstancesService/Demote',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.sql.v1beta4.SqlInstancesService',
        method         => 'Demote',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub export {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Sql::V1beta4::CloudSql::SqlInstancesExportRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Sql::V1beta4::CloudSqlResources::Operation';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.sql.v1beta4.SqlInstancesService/Export',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.sql.v1beta4.SqlInstancesService',
        method         => 'Export',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub failover {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Sql::V1beta4::CloudSql::SqlInstancesFailoverRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Sql::V1beta4::CloudSqlResources::Operation';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.sql.v1beta4.SqlInstancesService/Failover',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.sql.v1beta4.SqlInstancesService',
        method         => 'Failover',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub reencrypt {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Sql::V1beta4::CloudSql::SqlInstancesReencryptRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Sql::V1beta4::CloudSqlResources::Operation';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.sql.v1beta4.SqlInstancesService/Reencrypt',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.sql.v1beta4.SqlInstancesService',
        method         => 'Reencrypt',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub import_rpc {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Sql::V1beta4::CloudSql::SqlInstancesImportRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Sql::V1beta4::CloudSqlResources::Operation';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.sql.v1beta4.SqlInstancesService/Import',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.sql.v1beta4.SqlInstancesService',
        method         => 'Import',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub list_server_cas {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Sql::V1beta4::CloudSql::SqlInstancesListServerCasRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Sql::V1beta4::CloudSqlResources::InstancesListServerCasResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.sql.v1beta4.SqlInstancesService/ListServerCas',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.sql.v1beta4.SqlInstancesService',
        method         => 'ListServerCas',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub list_server_certificates {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Sql::V1beta4::CloudSql::SqlInstancesListServerCertificatesRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Sql::V1beta4::CloudSqlResources::InstancesListServerCertificatesResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.sql.v1beta4.SqlInstancesService/ListServerCertificates',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.sql.v1beta4.SqlInstancesService',
        method         => 'ListServerCertificates',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub list_entra_id_certificates {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Sql::V1beta4::CloudSql::SqlInstancesListEntraIdCertificatesRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Sql::V1beta4::CloudSqlResources::InstancesListEntraIdCertificatesResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.sql.v1beta4.SqlInstancesService/ListEntraIdCertificates',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.sql.v1beta4.SqlInstancesService',
        method         => 'ListEntraIdCertificates',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub promote_replica {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Sql::V1beta4::CloudSql::SqlInstancesPromoteReplicaRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Sql::V1beta4::CloudSqlResources::Operation';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.sql.v1beta4.SqlInstancesService/PromoteReplica',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.sql.v1beta4.SqlInstancesService',
        method         => 'PromoteReplica',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub switchover {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Sql::V1beta4::CloudSql::SqlInstancesSwitchoverRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Sql::V1beta4::CloudSqlResources::Operation';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.sql.v1beta4.SqlInstancesService/Switchover',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.sql.v1beta4.SqlInstancesService',
        method         => 'Switchover',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub reset_ssl_config {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Sql::V1beta4::CloudSql::SqlInstancesResetSslConfigRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Sql::V1beta4::CloudSqlResources::Operation';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.sql.v1beta4.SqlInstancesService/ResetSslConfig',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.sql.v1beta4.SqlInstancesService',
        method         => 'ResetSslConfig',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub restart {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Sql::V1beta4::CloudSql::SqlInstancesRestartRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Sql::V1beta4::CloudSqlResources::Operation';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.sql.v1beta4.SqlInstancesService/Restart',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.sql.v1beta4.SqlInstancesService',
        method         => 'Restart',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub start {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Sql::V1beta4::CloudSql::SqlInstancesStartRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Sql::V1beta4::CloudSqlResources::Operation';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.sql.v1beta4.SqlInstancesService/Start',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.sql.v1beta4.SqlInstancesService',
        method         => 'Start',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub stop {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Sql::V1beta4::CloudSql::SqlInstancesStopRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Sql::V1beta4::CloudSqlResources::Operation';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.sql.v1beta4.SqlInstancesService/Stop',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.sql.v1beta4.SqlInstancesService',
        method         => 'Stop',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub restore_backup {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Sql::V1beta4::CloudSql::SqlInstancesRestoreBackupRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Sql::V1beta4::CloudSqlResources::Operation';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.sql.v1beta4.SqlInstancesService/RestoreBackup',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.sql.v1beta4.SqlInstancesService',
        method         => 'RestoreBackup',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub rotate_server_ca {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Sql::V1beta4::CloudSql::SqlInstancesRotateServerCaRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Sql::V1beta4::CloudSqlResources::Operation';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.sql.v1beta4.SqlInstancesService/RotateServerCa',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.sql.v1beta4.SqlInstancesService',
        method         => 'RotateServerCa',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub rotate_server_certificate {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Sql::V1beta4::CloudSql::SqlInstancesRotateServerCertificateRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Sql::V1beta4::CloudSqlResources::Operation';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.sql.v1beta4.SqlInstancesService/RotateServerCertificate',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.sql.v1beta4.SqlInstancesService',
        method         => 'RotateServerCertificate',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub rotate_entra_id_certificate {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Sql::V1beta4::CloudSql::SqlInstancesRotateEntraIdCertificateRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Sql::V1beta4::CloudSqlResources::Operation';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.sql.v1beta4.SqlInstancesService/RotateEntraIdCertificate',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.sql.v1beta4.SqlInstancesService',
        method         => 'RotateEntraIdCertificate',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub start_replica {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Sql::V1beta4::CloudSql::SqlInstancesStartReplicaRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Sql::V1beta4::CloudSqlResources::Operation';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.sql.v1beta4.SqlInstancesService/StartReplica',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.sql.v1beta4.SqlInstancesService',
        method         => 'StartReplica',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub stop_replica {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Sql::V1beta4::CloudSql::SqlInstancesStopReplicaRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Sql::V1beta4::CloudSqlResources::Operation';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.sql.v1beta4.SqlInstancesService/StopReplica',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.sql.v1beta4.SqlInstancesService',
        method         => 'StopReplica',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub truncate_log {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Sql::V1beta4::CloudSql::SqlInstancesTruncateLogRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Sql::V1beta4::CloudSqlResources::Operation';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.sql.v1beta4.SqlInstancesService/TruncateLog',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.sql.v1beta4.SqlInstancesService',
        method         => 'TruncateLog',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub create_ephemeral {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Sql::V1beta4::CloudSql::SqlInstancesCreateEphemeralCertRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Sql::V1beta4::CloudSqlResources::SslCert';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.sql.v1beta4.SqlInstancesService/CreateEphemeral',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.sql.v1beta4.SqlInstancesService',
        method         => 'CreateEphemeral',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub reschedule_maintenance {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Sql::V1beta4::CloudSql::SqlInstancesRescheduleMaintenanceRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Sql::V1beta4::CloudSqlResources::Operation';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.sql.v1beta4.SqlInstancesService/RescheduleMaintenance',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.sql.v1beta4.SqlInstancesService',
        method         => 'RescheduleMaintenance',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub verify_external_sync_settings {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Sql::V1beta4::CloudSql::SqlInstancesVerifyExternalSyncSettingsRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Sql::V1beta4::CloudSqlResources::SqlInstancesVerifyExternalSyncSettingsResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.sql.v1beta4.SqlInstancesService/VerifyExternalSyncSettings',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.sql.v1beta4.SqlInstancesService',
        method         => 'VerifyExternalSyncSettings',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub start_external_sync {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Sql::V1beta4::CloudSql::SqlInstancesStartExternalSyncRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Sql::V1beta4::CloudSqlResources::Operation';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.sql.v1beta4.SqlInstancesService/StartExternalSync',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.sql.v1beta4.SqlInstancesService',
        method         => 'StartExternalSync',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub perform_disk_shrink {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Sql::V1beta4::CloudSql::SqlInstancesPerformDiskShrinkRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Sql::V1beta4::CloudSqlResources::Operation';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.sql.v1beta4.SqlInstancesService/PerformDiskShrink',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.sql.v1beta4.SqlInstancesService',
        method         => 'PerformDiskShrink',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub get_disk_shrink_config {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Sql::V1beta4::CloudSql::SqlInstancesGetDiskShrinkConfigRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Sql::V1beta4::CloudSqlResources::SqlInstancesGetDiskShrinkConfigResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.sql.v1beta4.SqlInstancesService/GetDiskShrinkConfig',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.sql.v1beta4.SqlInstancesService',
        method         => 'GetDiskShrinkConfig',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub reset_replica_size {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Sql::V1beta4::CloudSql::SqlInstancesResetReplicaSizeRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Sql::V1beta4::CloudSqlResources::Operation';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.sql.v1beta4.SqlInstancesService/ResetReplicaSize',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.sql.v1beta4.SqlInstancesService',
        method         => 'ResetReplicaSize',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub get_latest_recovery_time {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Sql::V1beta4::CloudSql::SqlInstancesGetLatestRecoveryTimeRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Sql::V1beta4::CloudSql::SqlInstancesGetLatestRecoveryTimeResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.sql.v1beta4.SqlInstancesService/GetLatestRecoveryTime',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.sql.v1beta4.SqlInstancesService',
        method         => 'GetLatestRecoveryTime',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub execute_sql_read_only {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Sql::V1beta4::CloudSql::SqlInstancesExecuteSqlReadOnlyRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Sql::V1beta4::CloudSql::SqlInstancesExecuteSqlReadOnlyResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.sql.v1beta4.SqlInstancesService/ExecuteSqlReadOnly',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.sql.v1beta4.SqlInstancesService',
        method         => 'ExecuteSqlReadOnly',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub execute_sql {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Sql::V1beta4::CloudSql::SqlInstancesExecuteSqlRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Sql::V1beta4::CloudSql::SqlInstancesExecuteSqlResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.sql.v1beta4.SqlInstancesService/ExecuteSql',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.sql.v1beta4.SqlInstancesService',
        method         => 'ExecuteSql',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub acquire_ssrs_lease {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Sql::V1beta4::CloudSql::SqlInstancesAcquireSsrsLeaseRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Sql::V1beta4::CloudSql::SqlInstancesAcquireSsrsLeaseResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.sql.v1beta4.SqlInstancesService/AcquireSsrsLease',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.sql.v1beta4.SqlInstancesService',
        method         => 'AcquireSsrsLease',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub release_ssrs_lease {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Sql::V1beta4::CloudSql::SqlInstancesReleaseSsrsLeaseRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Sql::V1beta4::CloudSql::SqlInstancesReleaseSsrsLeaseResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.sql.v1beta4.SqlInstancesService/ReleaseSsrsLease',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.sql.v1beta4.SqlInstancesService',
        method         => 'ReleaseSsrsLease',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub pre_check_major_version_upgrade {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Sql::V1beta4::CloudSql::SqlInstancesPreCheckMajorVersionUpgradeRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Sql::V1beta4::CloudSqlResources::Operation';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.sql.v1beta4.SqlInstancesService/PreCheckMajorVersionUpgrade',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.sql.v1beta4.SqlInstancesService',
        method         => 'PreCheckMajorVersionUpgrade',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub point_in_time_restore {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Sql::V1beta4::CloudSql::SqlInstancesPointInTimeRestoreRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Sql::V1beta4::CloudSqlResources::Operation';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.sql.v1beta4.SqlInstancesService/PointInTimeRestore',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.sql.v1beta4.SqlInstancesService',
        method         => 'PointInTimeRestore',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub create_blue_green_deployment {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Sql::V1beta4::CloudSqlBlueGreenDeployments::CreateBlueGreenDeploymentRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Sql::V1beta4::CloudSqlResources::Operation';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.sql.v1beta4.BlueGreenDeploymentsService/CreateBlueGreenDeployment',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.sql.v1beta4.BlueGreenDeploymentsService',
        method         => 'CreateBlueGreenDeployment',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub get_connect_settings {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Sql::V1beta4::CloudSqlConnect::GetConnectSettingsRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Sql::V1beta4::CloudSqlConnect::ConnectSettings';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.sql.v1beta4.SqlConnectService/GetConnectSettings',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.sql.v1beta4.SqlConnectService',
        method         => 'GetConnectSettings',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub resolve_connect_settings {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Sql::V1beta4::CloudSqlConnect::ResolveConnectSettingsRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Sql::V1beta4::CloudSqlConnect::ConnectSettings';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.sql.v1beta4.SqlConnectService/ResolveConnectSettings',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.sql.v1beta4.SqlConnectService',
        method         => 'ResolveConnectSettings',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub generate_ephemeral_cert {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Sql::V1beta4::CloudSqlConnect::GenerateEphemeralCertRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Sql::V1beta4::CloudSqlConnect::GenerateEphemeralCertResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.sql.v1beta4.SqlConnectService/GenerateEphemeralCert',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.sql.v1beta4.SqlConnectService',
        method         => 'GenerateEphemeralCert',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub stream_sql_data {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Sql::V1beta4::CloudSqlData::StreamSqlDataRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Sql::V1beta4::CloudSqlData::StreamSqlDataResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.sql.v1beta4.SqlDataService/StreamSqlData',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.sql.v1beta4.SqlDataService',
        method         => 'StreamSqlData',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub start_replay {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Sql::V1beta4::CloudSqlWorkloadCaptures::WorkloadCapturesStartReplayRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Sql::V1beta4::CloudSqlResources::Operation';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.sql.v1beta4.SqlWorkloadCapturesService/StartReplay',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.sql.v1beta4.SqlWorkloadCapturesService',
        method         => 'StartReplay',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub stop_replay {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Sql::V1beta4::CloudSqlWorkloadCaptures::WorkloadCapturesStopReplayRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Sql::V1beta4::CloudSqlResources::Operation';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.sql.v1beta4.SqlWorkloadCapturesService/StopReplay',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.sql.v1beta4.SqlWorkloadCapturesService',
        method         => 'StopReplay',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}
1; # End of Google::Cloud::Sql::V1beta4

__END__

=head1 NAME

Google::Cloud::Sql::V1beta4 - Client library for Google Cloud Services

=head1 SYNOPSIS

    use Google::Cloud::Sql::V1beta4;
    use Google::Auth;

    my $auth = Google::Auth->default();

    # 1. High-performance gRPC Transport (Default)
    my $grpc_client = Google::Cloud::Sql::V1beta4->new(
        credentials => $auth,
        transport   => 'grpc', # Optional: 'grpc' is default
    );

    # 2. HTTP/REST Transport
    my $rest_client = Google::Cloud::Sql::V1beta4->new(
        credentials => $auth,
        transport   => 'rest',
    );

    # Execute service methods
    my $res = $grpc_client->some_method( %params );

=head1 DESCRIPTION

C<Google::Cloud::Sql::V1beta4> is an auto-generated client library for Google Cloud Services.

It provides a unified client interface supporting both high-performance HTTP/2 gRPC and HTTP/REST transports, with automatic Google Cloud Application Default Credentials (ADC) resolution and typed Protocol Buffers message handling.

=head1 SOURCE

Generated from the following Protocol Buffers schemas:

=over 4

=item * C<googleapis/google/cloud/sql/v1beta4/cloud_sql.proto>

=item * C<googleapis/google/cloud/sql/v1beta4/cloud_sql_blue_green_deployments.proto>

=item * C<googleapis/google/cloud/sql/v1beta4/cloud_sql_connect.proto>

=item * C<googleapis/google/cloud/sql/v1beta4/cloud_sql_data.proto>

=item * C<googleapis/google/cloud/sql/v1beta4/cloud_sql_iam_policies.proto>

=item * C<googleapis/google/cloud/sql/v1beta4/cloud_sql_resources.proto>

=item * C<googleapis/google/cloud/sql/v1beta4/cloud_sql_tiers.proto>

=item * C<googleapis/google/cloud/sql/v1beta4/cloud_sql_users.proto>

=item * C<googleapis/google/cloud/sql/v1beta4/cloud_sql_workload_captures.proto>



=back

=head1 CONSTRUCTOR

=head2 new

    my $client = Google::Cloud::Sql::V1beta4->new(
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

=item * B<delete>

    my $response = $client->delete(
        id                       => $id,
        instance                 => $instance,
        project                  => $project,
    );

Calls the RPC method C<Delete> on C<google.cloud.sql.v1beta4.SqlBackupRunsService>.

Request: L<Google::Cloud::Sql::V1beta4::CloudSql::SqlBackupRunsDeleteRequest>

Returns: L<Google::Cloud::Sql::V1beta4::CloudSqlResources::Operation>

Parameters:

=over 4

=item * C<id> - C<int64>

=item * C<instance> - C<string>

=item * C<project> - C<string>

=back

=item * B<get>

    my $response = $client->get(
        id                       => $id,
        instance                 => $instance,
        project                  => $project,
    );

Calls the RPC method C<Get> on C<google.cloud.sql.v1beta4.SqlBackupRunsService>.

Request: L<Google::Cloud::Sql::V1beta4::CloudSql::SqlBackupRunsGetRequest>

Returns: L<Google::Cloud::Sql::V1beta4::CloudSqlResources::BackupRun>

Parameters:

=over 4

=item * C<id> - C<int64>

=item * C<instance> - C<string>

=item * C<project> - C<string>

=back

=item * B<insert>

    my $response = $client->insert(
        instance                 => $instance,
        project                  => $project,
        body                     => $body,
    );

Calls the RPC method C<Insert> on C<google.cloud.sql.v1beta4.SqlBackupRunsService>.

Request: L<Google::Cloud::Sql::V1beta4::CloudSql::SqlBackupRunsInsertRequest>

Returns: L<Google::Cloud::Sql::V1beta4::CloudSqlResources::Operation>

Parameters:

=over 4

=item * C<instance> - C<string>

=item * C<project> - C<string>

=item * C<body> - L<Google::Cloud::Sql::V1beta4::CloudSqlResources::BackupRun>

=back

=item * B<list>

    my $response = $client->list(
        instance                 => $instance,
        max_results              => $max_results,
        page_token               => $page_token,
        project                  => $project,
    );

Calls the RPC method C<List> on C<google.cloud.sql.v1beta4.SqlBackupRunsService>.

Request: L<Google::Cloud::Sql::V1beta4::CloudSql::SqlBackupRunsListRequest>

Returns: L<Google::Cloud::Sql::V1beta4::CloudSqlResources::BackupRunsListResponse>

Parameters:

=over 4

=item * C<instance> - C<string>

=item * C<max_results> - C<int32>

=item * C<page_token> - C<string>

=item * C<project> - C<string>

=back

=item * B<patch>

    my $response = $client->patch(
        database                 => $database,
        instance                 => $instance,
        project                  => $project,
        body                     => $body,
        location                 => $location,
    );

Calls the RPC method C<Patch> on C<google.cloud.sql.v1beta4.SqlDatabasesService>.

Request: L<Google::Cloud::Sql::V1beta4::CloudSql::SqlDatabasesUpdateRequest>

Returns: L<Google::Cloud::Sql::V1beta4::CloudSqlResources::Operation>

Parameters:

=over 4

=item * C<database> - C<string>

=item * C<instance> - C<string>

=item * C<project> - C<string>

=item * C<body> - L<Google::Cloud::Sql::V1beta4::CloudSqlResources::Database>

=item * C<location> - C<string>

=back

=item * B<update>

    my $response = $client->update(
        database                 => $database,
        instance                 => $instance,
        project                  => $project,
        body                     => $body,
        location                 => $location,
    );

Calls the RPC method C<Update> on C<google.cloud.sql.v1beta4.SqlDatabasesService>.

Request: L<Google::Cloud::Sql::V1beta4::CloudSql::SqlDatabasesUpdateRequest>

Returns: L<Google::Cloud::Sql::V1beta4::CloudSqlResources::Operation>

Parameters:

=over 4

=item * C<database> - C<string>

=item * C<instance> - C<string>

=item * C<project> - C<string>

=item * C<body> - L<Google::Cloud::Sql::V1beta4::CloudSqlResources::Database>

=item * C<location> - C<string>

=back

=item * B<add_server_ca>

    my $response = $client->add_server_ca(
        instance                 => $instance,
        project                  => $project,
        location                 => $location,
    );

Calls the RPC method C<AddServerCa> on C<google.cloud.sql.v1beta4.SqlInstancesService>.

Request: L<Google::Cloud::Sql::V1beta4::CloudSql::SqlInstancesAddServerCaRequest>

Returns: L<Google::Cloud::Sql::V1beta4::CloudSqlResources::Operation>

Parameters:

=over 4

=item * C<instance> - C<string>

=item * C<project> - C<string>

=item * C<location> - C<string>

=back

=item * B<add_server_certificate>

    my $response = $client->add_server_certificate(
        instance                 => $instance,
        project                  => $project,
        location                 => $location,
    );

Calls the RPC method C<AddServerCertificate> on C<google.cloud.sql.v1beta4.SqlInstancesService>.

Request: L<Google::Cloud::Sql::V1beta4::CloudSql::SqlInstancesAddServerCertificateRequest>

Returns: L<Google::Cloud::Sql::V1beta4::CloudSqlResources::Operation>

Parameters:

=over 4

=item * C<instance> - C<string>

=item * C<project> - C<string>

=item * C<location> - C<string>

=back

=item * B<add_entra_id_certificate>

    my $response = $client->add_entra_id_certificate(
        instance                 => $instance,
        project                  => $project,
        location                 => $location,
    );

Calls the RPC method C<AddEntraIdCertificate> on C<google.cloud.sql.v1beta4.SqlInstancesService>.

Request: L<Google::Cloud::Sql::V1beta4::CloudSql::SqlInstancesAddEntraIdCertificateRequest>

Returns: L<Google::Cloud::Sql::V1beta4::CloudSqlResources::Operation>

Parameters:

=over 4

=item * C<instance> - C<string>

=item * C<project> - C<string>

=item * C<location> - C<string>

=back

=item * B<clone>

    my $response = $client->clone(
        instance                 => $instance,
        project                  => $project,
        body                     => $body,
        location                 => $location,
    );

Calls the RPC method C<Clone> on C<google.cloud.sql.v1beta4.SqlInstancesService>.

Request: L<Google::Cloud::Sql::V1beta4::CloudSql::SqlInstancesCloneRequest>

Returns: L<Google::Cloud::Sql::V1beta4::CloudSqlResources::Operation>

Parameters:

=over 4

=item * C<instance> - C<string>

=item * C<project> - C<string>

=item * C<body> - L<Google::Cloud::Sql::V1beta4::CloudSqlResources::InstancesCloneRequest>

=item * C<location> - C<string>

=back

=item * B<demote_master>

    my $response = $client->demote_master(
        instance                 => $instance,
        project                  => $project,
        body                     => $body,
        location                 => $location,
    );

Calls the RPC method C<DemoteMaster> on C<google.cloud.sql.v1beta4.SqlInstancesService>.

Request: L<Google::Cloud::Sql::V1beta4::CloudSql::SqlInstancesDemoteMasterRequest>

Returns: L<Google::Cloud::Sql::V1beta4::CloudSqlResources::Operation>

Parameters:

=over 4

=item * C<instance> - C<string>

=item * C<project> - C<string>

=item * C<body> - L<Google::Cloud::Sql::V1beta4::CloudSqlResources::InstancesDemoteMasterRequest>

=item * C<location> - C<string>

=back

=item * B<demote>

    my $response = $client->demote(
        instance                 => $instance,
        project                  => $project,
        body                     => $body,
        location                 => $location,
    );

Calls the RPC method C<Demote> on C<google.cloud.sql.v1beta4.SqlInstancesService>.

Request: L<Google::Cloud::Sql::V1beta4::CloudSql::SqlInstancesDemoteRequest>

Returns: L<Google::Cloud::Sql::V1beta4::CloudSqlResources::Operation>

Parameters:

=over 4

=item * C<instance> - C<string>

=item * C<project> - C<string>

=item * C<body> - L<Google::Cloud::Sql::V1beta4::CloudSqlResources::InstancesDemoteRequest>

=item * C<location> - C<string>

=back

=item * B<export>

    my $response = $client->export(
        instance                 => $instance,
        project                  => $project,
        body                     => $body,
        location                 => $location,
    );

Calls the RPC method C<Export> on C<google.cloud.sql.v1beta4.SqlInstancesService>.

Request: L<Google::Cloud::Sql::V1beta4::CloudSql::SqlInstancesExportRequest>

Returns: L<Google::Cloud::Sql::V1beta4::CloudSqlResources::Operation>

Parameters:

=over 4

=item * C<instance> - C<string>

=item * C<project> - C<string>

=item * C<body> - L<Google::Cloud::Sql::V1beta4::CloudSqlResources::InstancesExportRequest>

=item * C<location> - C<string>

=back

=item * B<failover>

    my $response = $client->failover(
        instance                 => $instance,
        project                  => $project,
        body                     => $body,
        location                 => $location,
    );

Calls the RPC method C<Failover> on C<google.cloud.sql.v1beta4.SqlInstancesService>.

Request: L<Google::Cloud::Sql::V1beta4::CloudSql::SqlInstancesFailoverRequest>

Returns: L<Google::Cloud::Sql::V1beta4::CloudSqlResources::Operation>

Parameters:

=over 4

=item * C<instance> - C<string>

=item * C<project> - C<string>

=item * C<body> - L<Google::Cloud::Sql::V1beta4::CloudSqlResources::InstancesFailoverRequest>

=item * C<location> - C<string>

=back

=item * B<reencrypt>

    my $response = $client->reencrypt(
        instance                 => $instance,
        project                  => $project,
        body                     => $body,
        location                 => $location,
    );

Calls the RPC method C<Reencrypt> on C<google.cloud.sql.v1beta4.SqlInstancesService>.

Request: L<Google::Cloud::Sql::V1beta4::CloudSql::SqlInstancesReencryptRequest>

Returns: L<Google::Cloud::Sql::V1beta4::CloudSqlResources::Operation>

Parameters:

=over 4

=item * C<instance> - C<string>

=item * C<project> - C<string>

=item * C<body> - L<Google::Cloud::Sql::V1beta4::CloudSql::InstancesReencryptRequest>

=item * C<location> - C<string>

=back

=item * B<import_rpc>

    my $response = $client->import_rpc(
        instance                 => $instance,
        project                  => $project,
        body                     => $body,
        location                 => $location,
    );

Calls the RPC method C<Import> on C<google.cloud.sql.v1beta4.SqlInstancesService>.

Request: L<Google::Cloud::Sql::V1beta4::CloudSql::SqlInstancesImportRequest>

Returns: L<Google::Cloud::Sql::V1beta4::CloudSqlResources::Operation>

Parameters:

=over 4

=item * C<instance> - C<string>

=item * C<project> - C<string>

=item * C<body> - L<Google::Cloud::Sql::V1beta4::CloudSqlResources::InstancesImportRequest>

=item * C<location> - C<string>

=back

=item * B<list_server_cas>

    my $response = $client->list_server_cas(
        instance                 => $instance,
        project                  => $project,
        location                 => $location,
    );

Calls the RPC method C<ListServerCas> on C<google.cloud.sql.v1beta4.SqlInstancesService>.

Request: L<Google::Cloud::Sql::V1beta4::CloudSql::SqlInstancesListServerCasRequest>

Returns: L<Google::Cloud::Sql::V1beta4::CloudSqlResources::InstancesListServerCasResponse>

Parameters:

=over 4

=item * C<instance> - C<string>

=item * C<project> - C<string>

=item * C<location> - C<string>

=back

=item * B<list_server_certificates>

    my $response = $client->list_server_certificates(
        instance                 => $instance,
        project                  => $project,
        location                 => $location,
    );

Calls the RPC method C<ListServerCertificates> on C<google.cloud.sql.v1beta4.SqlInstancesService>.

Request: L<Google::Cloud::Sql::V1beta4::CloudSql::SqlInstancesListServerCertificatesRequest>

Returns: L<Google::Cloud::Sql::V1beta4::CloudSqlResources::InstancesListServerCertificatesResponse>

Parameters:

=over 4

=item * C<instance> - C<string>

=item * C<project> - C<string>

=item * C<location> - C<string>

=back

=item * B<list_entra_id_certificates>

    my $response = $client->list_entra_id_certificates(
        instance                 => $instance,
        project                  => $project,
        location                 => $location,
    );

Calls the RPC method C<ListEntraIdCertificates> on C<google.cloud.sql.v1beta4.SqlInstancesService>.

Request: L<Google::Cloud::Sql::V1beta4::CloudSql::SqlInstancesListEntraIdCertificatesRequest>

Returns: L<Google::Cloud::Sql::V1beta4::CloudSqlResources::InstancesListEntraIdCertificatesResponse>

Parameters:

=over 4

=item * C<instance> - C<string>

=item * C<project> - C<string>

=item * C<location> - C<string>

=back

=item * B<promote_replica>

    my $response = $client->promote_replica(
        instance                 => $instance,
        project                  => $project,
        failover                 => $failover,
        location                 => $location,
    );

Calls the RPC method C<PromoteReplica> on C<google.cloud.sql.v1beta4.SqlInstancesService>.

Request: L<Google::Cloud::Sql::V1beta4::CloudSql::SqlInstancesPromoteReplicaRequest>

Returns: L<Google::Cloud::Sql::V1beta4::CloudSqlResources::Operation>

Parameters:

=over 4

=item * C<instance> - C<string>

=item * C<project> - C<string>

=item * C<failover> - C<bool>

=item * C<location> - C<string>

=back

=item * B<switchover>

    my $response = $client->switchover(
        instance                 => $instance,
        project                  => $project,
        db_timeout               => $db_timeout,
        location                 => $location,
    );

Calls the RPC method C<Switchover> on C<google.cloud.sql.v1beta4.SqlInstancesService>.

Request: L<Google::Cloud::Sql::V1beta4::CloudSql::SqlInstancesSwitchoverRequest>

Returns: L<Google::Cloud::Sql::V1beta4::CloudSqlResources::Operation>

Parameters:

=over 4

=item * C<instance> - C<string>

=item * C<project> - C<string>

=item * C<db_timeout> - L<Google::Protobuf::Duration::Duration>

=item * C<location> - C<string>

=back

=item * B<reset_ssl_config>

    my $response = $client->reset_ssl_config(
        instance                 => $instance,
        project                  => $project,
        mode                     => $mode,
        location                 => $location,
    );

Calls the RPC method C<ResetSslConfig> on C<google.cloud.sql.v1beta4.SqlInstancesService>.

Request: L<Google::Cloud::Sql::V1beta4::CloudSql::SqlInstancesResetSslConfigRequest>

Returns: L<Google::Cloud::Sql::V1beta4::CloudSqlResources::Operation>

Parameters:

=over 4

=item * C<instance> - C<string>

=item * C<project> - C<string>

=item * C<mode> - L<Google::Cloud::Sql::V1beta4::CloudSql::ResetSslMode>

=item * C<location> - C<string>

=back

=item * B<restart>

    my $response = $client->restart(
        instance                 => $instance,
        project                  => $project,
        location                 => $location,
    );

Calls the RPC method C<Restart> on C<google.cloud.sql.v1beta4.SqlInstancesService>.

Request: L<Google::Cloud::Sql::V1beta4::CloudSql::SqlInstancesRestartRequest>

Returns: L<Google::Cloud::Sql::V1beta4::CloudSqlResources::Operation>

Parameters:

=over 4

=item * C<instance> - C<string>

=item * C<project> - C<string>

=item * C<location> - C<string>

=back

=item * B<start>

    my $response = $client->start(
        instance                 => $instance,
        project                  => $project,
        location                 => $location,
    );

Calls the RPC method C<Start> on C<google.cloud.sql.v1beta4.SqlInstancesService>.

Request: L<Google::Cloud::Sql::V1beta4::CloudSql::SqlInstancesStartRequest>

Returns: L<Google::Cloud::Sql::V1beta4::CloudSqlResources::Operation>

Parameters:

=over 4

=item * C<instance> - C<string>

=item * C<project> - C<string>

=item * C<location> - C<string>

=back

=item * B<stop>

    my $response = $client->stop(
        instance                 => $instance,
        project                  => $project,
        location                 => $location,
    );

Calls the RPC method C<Stop> on C<google.cloud.sql.v1beta4.SqlInstancesService>.

Request: L<Google::Cloud::Sql::V1beta4::CloudSql::SqlInstancesStopRequest>

Returns: L<Google::Cloud::Sql::V1beta4::CloudSqlResources::Operation>

Parameters:

=over 4

=item * C<instance> - C<string>

=item * C<project> - C<string>

=item * C<location> - C<string>

=back

=item * B<restore_backup>

    my $response = $client->restore_backup(
        instance                 => $instance,
        project                  => $project,
        body                     => $body,
        location                 => $location,
    );

Calls the RPC method C<RestoreBackup> on C<google.cloud.sql.v1beta4.SqlInstancesService>.

Request: L<Google::Cloud::Sql::V1beta4::CloudSql::SqlInstancesRestoreBackupRequest>

Returns: L<Google::Cloud::Sql::V1beta4::CloudSqlResources::Operation>

Parameters:

=over 4

=item * C<instance> - C<string>

=item * C<project> - C<string>

=item * C<body> - L<Google::Cloud::Sql::V1beta4::CloudSqlResources::InstancesRestoreBackupRequest>

=item * C<location> - C<string>

=back

=item * B<rotate_server_ca>

    my $response = $client->rotate_server_ca(
        instance                 => $instance,
        project                  => $project,
        body                     => $body,
        location                 => $location,
    );

Calls the RPC method C<RotateServerCa> on C<google.cloud.sql.v1beta4.SqlInstancesService>.

Request: L<Google::Cloud::Sql::V1beta4::CloudSql::SqlInstancesRotateServerCaRequest>

Returns: L<Google::Cloud::Sql::V1beta4::CloudSqlResources::Operation>

Parameters:

=over 4

=item * C<instance> - C<string>

=item * C<project> - C<string>

=item * C<body> - L<Google::Cloud::Sql::V1beta4::CloudSqlResources::InstancesRotateServerCaRequest>

=item * C<location> - C<string>

=back

=item * B<rotate_server_certificate>

    my $response = $client->rotate_server_certificate(
        instance                 => $instance,
        project                  => $project,
        body                     => $body,
        location                 => $location,
    );

Calls the RPC method C<RotateServerCertificate> on C<google.cloud.sql.v1beta4.SqlInstancesService>.

Request: L<Google::Cloud::Sql::V1beta4::CloudSql::SqlInstancesRotateServerCertificateRequest>

Returns: L<Google::Cloud::Sql::V1beta4::CloudSqlResources::Operation>

Parameters:

=over 4

=item * C<instance> - C<string>

=item * C<project> - C<string>

=item * C<body> - L<Google::Cloud::Sql::V1beta4::CloudSqlResources::InstancesRotateServerCertificateRequest>

=item * C<location> - C<string>

=back

=item * B<rotate_entra_id_certificate>

    my $response = $client->rotate_entra_id_certificate(
        instance                 => $instance,
        project                  => $project,
        body                     => $body,
        location                 => $location,
    );

Calls the RPC method C<RotateEntraIdCertificate> on C<google.cloud.sql.v1beta4.SqlInstancesService>.

Request: L<Google::Cloud::Sql::V1beta4::CloudSql::SqlInstancesRotateEntraIdCertificateRequest>

Returns: L<Google::Cloud::Sql::V1beta4::CloudSqlResources::Operation>

Parameters:

=over 4

=item * C<instance> - C<string>

=item * C<project> - C<string>

=item * C<body> - L<Google::Cloud::Sql::V1beta4::CloudSqlResources::InstancesRotateEntraIdCertificateRequest>

=item * C<location> - C<string>

=back

=item * B<start_replica>

    my $response = $client->start_replica(
        instance                 => $instance,
        project                  => $project,
        location                 => $location,
    );

Calls the RPC method C<StartReplica> on C<google.cloud.sql.v1beta4.SqlInstancesService>.

Request: L<Google::Cloud::Sql::V1beta4::CloudSql::SqlInstancesStartReplicaRequest>

Returns: L<Google::Cloud::Sql::V1beta4::CloudSqlResources::Operation>

Parameters:

=over 4

=item * C<instance> - C<string>

=item * C<project> - C<string>

=item * C<location> - C<string>

=back

=item * B<stop_replica>

    my $response = $client->stop_replica(
        instance                 => $instance,
        project                  => $project,
        location                 => $location,
    );

Calls the RPC method C<StopReplica> on C<google.cloud.sql.v1beta4.SqlInstancesService>.

Request: L<Google::Cloud::Sql::V1beta4::CloudSql::SqlInstancesStopReplicaRequest>

Returns: L<Google::Cloud::Sql::V1beta4::CloudSqlResources::Operation>

Parameters:

=over 4

=item * C<instance> - C<string>

=item * C<project> - C<string>

=item * C<location> - C<string>

=back

=item * B<truncate_log>

    my $response = $client->truncate_log(
        instance                 => $instance,
        project                  => $project,
        body                     => $body,
        location                 => $location,
    );

Calls the RPC method C<TruncateLog> on C<google.cloud.sql.v1beta4.SqlInstancesService>.

Request: L<Google::Cloud::Sql::V1beta4::CloudSql::SqlInstancesTruncateLogRequest>

Returns: L<Google::Cloud::Sql::V1beta4::CloudSqlResources::Operation>

Parameters:

=over 4

=item * C<instance> - C<string>

=item * C<project> - C<string>

=item * C<body> - L<Google::Cloud::Sql::V1beta4::CloudSqlResources::InstancesTruncateLogRequest>

=item * C<location> - C<string>

=back

=item * B<create_ephemeral>

    my $response = $client->create_ephemeral(
        instance                 => $instance,
        project                  => $project,
        body                     => $body,
        location                 => $location,
    );

Calls the RPC method C<CreateEphemeral> on C<google.cloud.sql.v1beta4.SqlInstancesService>.

Request: L<Google::Cloud::Sql::V1beta4::CloudSql::SqlInstancesCreateEphemeralCertRequest>

Returns: L<Google::Cloud::Sql::V1beta4::CloudSqlResources::SslCert>

Parameters:

=over 4

=item * C<instance> - C<string>

=item * C<project> - C<string>

=item * C<body> - L<Google::Cloud::Sql::V1beta4::CloudSqlResources::SslCertsCreateEphemeralRequest>

=item * C<location> - C<string>

=back

=item * B<reschedule_maintenance>

    my $response = $client->reschedule_maintenance(
        instance                 => $instance,
        project                  => $project,
        body                     => $body,
        location                 => $location,
    );

Calls the RPC method C<RescheduleMaintenance> on C<google.cloud.sql.v1beta4.SqlInstancesService>.

Request: L<Google::Cloud::Sql::V1beta4::CloudSql::SqlInstancesRescheduleMaintenanceRequest>

Returns: L<Google::Cloud::Sql::V1beta4::CloudSqlResources::Operation>

Parameters:

=over 4

=item * C<instance> - C<string>

=item * C<project> - C<string>

=item * C<body> - L<Google::Cloud::Sql::V1beta4::CloudSqlResources::SqlInstancesRescheduleMaintenanceRequestBody>

=item * C<location> - C<string>

=back

=item * B<verify_external_sync_settings>

    my $response = $client->verify_external_sync_settings(
        instance                 => $instance,
        project                  => $project,
        verify_connection_only   => $verify_connection_only,
        sync_mode                => $sync_mode,
        verify_replication_only  => $verify_replication_only,
        migration_type           => $migration_type,
        sync_parallel_level      => $sync_parallel_level,
        selected_objects         => [ ... ],
        location                 => $location,
    );

Calls the RPC method C<VerifyExternalSyncSettings> on C<google.cloud.sql.v1beta4.SqlInstancesService>.

Request: L<Google::Cloud::Sql::V1beta4::CloudSql::SqlInstancesVerifyExternalSyncSettingsRequest>

Returns: L<Google::Cloud::Sql::V1beta4::CloudSqlResources::SqlInstancesVerifyExternalSyncSettingsResponse>

Parameters:

=over 4

=item * C<instance> - C<string>

=item * C<project> - C<string>

=item * C<verify_connection_only> - C<bool>

=item * C<sync_mode> - L<Google::Cloud::Sql::V1beta4::CloudSql::ExternalSyncMode>

=item * C<verify_replication_only> - C<bool>

=item * C<migration_type> - L<Google::Cloud::Sql::V1beta4::CloudSql::MigrationType>

=item * C<sync_parallel_level> - L<Google::Cloud::Sql::V1beta4::CloudSql::ExternalSyncParallelLevel>

=item * C<selected_objects> - ArrayRef of L<Google::Cloud::Sql::V1beta4::CloudSql::ExternalSyncSelectedObject>

=item * C<location> - C<string>

=back

=item * B<start_external_sync>

    my $response = $client->start_external_sync(
        instance                 => $instance,
        project                  => $project,
        sync_mode                => $sync_mode,
        skip_verification        => $skip_verification,
        sync_parallel_level      => $sync_parallel_level,
        migration_type           => $migration_type,
        replica_overwrite_enabled => $replica_overwrite_enabled,
        location                 => $location,
    );

Calls the RPC method C<StartExternalSync> on C<google.cloud.sql.v1beta4.SqlInstancesService>.

Request: L<Google::Cloud::Sql::V1beta4::CloudSql::SqlInstancesStartExternalSyncRequest>

Returns: L<Google::Cloud::Sql::V1beta4::CloudSqlResources::Operation>

Parameters:

=over 4

=item * C<instance> - C<string>

=item * C<project> - C<string>

=item * C<sync_mode> - L<SqlInstancesVerifyExternalSyncSettingsRequest::ExternalSyncMode::ExternalSyncMode>

=item * C<skip_verification> - C<bool>

=item * C<sync_parallel_level> - L<Google::Cloud::Sql::V1beta4::CloudSql::ExternalSyncParallelLevel>

=item * C<migration_type> - L<SqlInstancesVerifyExternalSyncSettingsRequest::MigrationType::MigrationType>

=item * C<replica_overwrite_enabled> - C<bool>

=item * C<location> - C<string>

=back

=item * B<perform_disk_shrink>

    my $response = $client->perform_disk_shrink(
        instance                 => $instance,
        project                  => $project,
        body                     => $body,
        location                 => $location,
    );

Calls the RPC method C<PerformDiskShrink> on C<google.cloud.sql.v1beta4.SqlInstancesService>.

Request: L<Google::Cloud::Sql::V1beta4::CloudSql::SqlInstancesPerformDiskShrinkRequest>

Returns: L<Google::Cloud::Sql::V1beta4::CloudSqlResources::Operation>

Parameters:

=over 4

=item * C<instance> - C<string>

=item * C<project> - C<string>

=item * C<body> - L<Google::Cloud::Sql::V1beta4::CloudSqlResources::PerformDiskShrinkContext>

=item * C<location> - C<string>

=back

=item * B<get_disk_shrink_config>

    my $response = $client->get_disk_shrink_config(
        instance                 => $instance,
        project                  => $project,
        location                 => $location,
    );

Calls the RPC method C<GetDiskShrinkConfig> on C<google.cloud.sql.v1beta4.SqlInstancesService>.

Request: L<Google::Cloud::Sql::V1beta4::CloudSql::SqlInstancesGetDiskShrinkConfigRequest>

Returns: L<Google::Cloud::Sql::V1beta4::CloudSqlResources::SqlInstancesGetDiskShrinkConfigResponse>

Parameters:

=over 4

=item * C<instance> - C<string>

=item * C<project> - C<string>

=item * C<location> - C<string>

=back

=item * B<reset_replica_size>

    my $response = $client->reset_replica_size(
        instance                 => $instance,
        project                  => $project,
        location                 => $location,
    );

Calls the RPC method C<ResetReplicaSize> on C<google.cloud.sql.v1beta4.SqlInstancesService>.

Request: L<Google::Cloud::Sql::V1beta4::CloudSql::SqlInstancesResetReplicaSizeRequest>

Returns: L<Google::Cloud::Sql::V1beta4::CloudSqlResources::Operation>

Parameters:

=over 4

=item * C<instance> - C<string>

=item * C<project> - C<string>

=item * C<location> - C<string>

=back

=item * B<get_latest_recovery_time>

    my $response = $client->get_latest_recovery_time(
        instance                 => $instance,
        project                  => $project,
        source_instance_deletion_time => $source_instance_deletion_time,
        location                 => $location,
    );

Calls the RPC method C<GetLatestRecoveryTime> on C<google.cloud.sql.v1beta4.SqlInstancesService>.

Request: L<Google::Cloud::Sql::V1beta4::CloudSql::SqlInstancesGetLatestRecoveryTimeRequest>

Returns: L<Google::Cloud::Sql::V1beta4::CloudSql::SqlInstancesGetLatestRecoveryTimeResponse>

Parameters:

=over 4

=item * C<instance> - C<string>

=item * C<project> - C<string>

=item * C<source_instance_deletion_time> - L<Google::Protobuf::Timestamp::Timestamp>

=item * C<location> - C<string>

=back

=item * B<execute_sql_read_only>

    my $response = $client->execute_sql_read_only(
        instance                 => $instance,
        project                  => $project,
        body                     => $body,
        location                 => $location,
    );

Calls the RPC method C<ExecuteSqlReadOnly> on C<google.cloud.sql.v1beta4.SqlInstancesService>.

Request: L<Google::Cloud::Sql::V1beta4::CloudSql::SqlInstancesExecuteSqlReadOnlyRequest>

Returns: L<Google::Cloud::Sql::V1beta4::CloudSql::SqlInstancesExecuteSqlReadOnlyResponse>

Parameters:

=over 4

=item * C<instance> - C<string>

=item * C<project> - C<string>

=item * C<body> - L<Google::Cloud::Sql::V1beta4::CloudSql::ExecuteSqlReadOnlyPayload>

=item * C<location> - C<string>

=back

=item * B<execute_sql>

    my $response = $client->execute_sql(
        instance                 => $instance,
        project                  => $project,
        body                     => $body,
        location                 => $location,
    );

Calls the RPC method C<ExecuteSql> on C<google.cloud.sql.v1beta4.SqlInstancesService>.

Request: L<Google::Cloud::Sql::V1beta4::CloudSql::SqlInstancesExecuteSqlRequest>

Returns: L<Google::Cloud::Sql::V1beta4::CloudSql::SqlInstancesExecuteSqlResponse>

Parameters:

=over 4

=item * C<instance> - C<string>

=item * C<project> - C<string>

=item * C<body> - L<Google::Cloud::Sql::V1beta4::CloudSql::ExecuteSqlPayload>

=item * C<location> - C<string>

=back

=item * B<acquire_ssrs_lease>

    my $response = $client->acquire_ssrs_lease(
        instance                 => $instance,
        project                  => $project,
        body                     => $body,
        location                 => $location,
    );

Calls the RPC method C<AcquireSsrsLease> on C<google.cloud.sql.v1beta4.SqlInstancesService>.

Request: L<Google::Cloud::Sql::V1beta4::CloudSql::SqlInstancesAcquireSsrsLeaseRequest>

Returns: L<Google::Cloud::Sql::V1beta4::CloudSql::SqlInstancesAcquireSsrsLeaseResponse>

Parameters:

=over 4

=item * C<instance> - C<string>

=item * C<project> - C<string>

=item * C<body> - L<Google::Cloud::Sql::V1beta4::CloudSqlResources::InstancesAcquireSsrsLeaseRequest>

=item * C<location> - C<string>

=back

=item * B<release_ssrs_lease>

    my $response = $client->release_ssrs_lease(
        instance                 => $instance,
        project                  => $project,
        location                 => $location,
    );

Calls the RPC method C<ReleaseSsrsLease> on C<google.cloud.sql.v1beta4.SqlInstancesService>.

Request: L<Google::Cloud::Sql::V1beta4::CloudSql::SqlInstancesReleaseSsrsLeaseRequest>

Returns: L<Google::Cloud::Sql::V1beta4::CloudSql::SqlInstancesReleaseSsrsLeaseResponse>

Parameters:

=over 4

=item * C<instance> - C<string>

=item * C<project> - C<string>

=item * C<location> - C<string>

=back

=item * B<pre_check_major_version_upgrade>

    my $response = $client->pre_check_major_version_upgrade(
        instance                 => $instance,
        project                  => $project,
        body                     => $body,
        location                 => $location,
    );

Calls the RPC method C<PreCheckMajorVersionUpgrade> on C<google.cloud.sql.v1beta4.SqlInstancesService>.

Request: L<Google::Cloud::Sql::V1beta4::CloudSql::SqlInstancesPreCheckMajorVersionUpgradeRequest>

Returns: L<Google::Cloud::Sql::V1beta4::CloudSqlResources::Operation>

Parameters:

=over 4

=item * C<instance> - C<string>

=item * C<project> - C<string>

=item * C<body> - L<Google::Cloud::Sql::V1beta4::CloudSqlResources::InstancesPreCheckMajorVersionUpgradeRequest>

=item * C<location> - C<string>

=back

=item * B<point_in_time_restore>

    my $response = $client->point_in_time_restore(
        parent                   => $parent,
        context                  => $context,
    );

Calls the RPC method C<PointInTimeRestore> on C<google.cloud.sql.v1beta4.SqlInstancesService>.

Request: L<Google::Cloud::Sql::V1beta4::CloudSql::SqlInstancesPointInTimeRestoreRequest>

Returns: L<Google::Cloud::Sql::V1beta4::CloudSqlResources::Operation>

Parameters:

=over 4

=item * C<parent> - C<string>

=item * C<context> - L<Google::Cloud::Sql::V1beta4::CloudSqlResources::PointInTimeRestoreContext>

=back

=item * B<create_blue_green_deployment>

    my $response = $client->create_blue_green_deployment(
        parent                   => $parent,
        blue_green_deployment_id => $blue_green_deployment_id,
        blue_green_deployment    => $blue_green_deployment,
    );

Calls the RPC method C<CreateBlueGreenDeployment> on C<google.cloud.sql.v1beta4.BlueGreenDeploymentsService>.

Request: L<Google::Cloud::Sql::V1beta4::CloudSqlBlueGreenDeployments::CreateBlueGreenDeploymentRequest>

Returns: L<Google::Cloud::Sql::V1beta4::CloudSqlResources::Operation>

Parameters:

=over 4

=item * C<parent> - C<string>

=item * C<blue_green_deployment_id> - C<string>

=item * C<blue_green_deployment> - L<Google::Cloud::Sql::V1beta4::CloudSqlBlueGreenDeployments::BlueGreenDeployment>

=back

=item * B<get_connect_settings>

    my $response = $client->get_connect_settings(
        instance                 => $instance,
        project                  => $project,
        read_time                => $read_time,
    );

Calls the RPC method C<GetConnectSettings> on C<google.cloud.sql.v1beta4.SqlConnectService>.

Request: L<Google::Cloud::Sql::V1beta4::CloudSqlConnect::GetConnectSettingsRequest>

Returns: L<Google::Cloud::Sql::V1beta4::CloudSqlConnect::ConnectSettings>

Parameters:

=over 4

=item * C<instance> - C<string>

=item * C<project> - C<string>

=item * C<read_time> - L<Google::Protobuf::Timestamp::Timestamp>

=back

=item * B<resolve_connect_settings>

    my $response = $client->resolve_connect_settings(
        dns_name                 => $dns_name,
        location                 => $location,
    );

Calls the RPC method C<ResolveConnectSettings> on C<google.cloud.sql.v1beta4.SqlConnectService>.

Request: L<Google::Cloud::Sql::V1beta4::CloudSqlConnect::ResolveConnectSettingsRequest>

Returns: L<Google::Cloud::Sql::V1beta4::CloudSqlConnect::ConnectSettings>

Parameters:

=over 4

=item * C<dns_name> - C<string>

=item * C<location> - C<string>

=back

=item * B<generate_ephemeral_cert>

    my $response = $client->generate_ephemeral_cert(
        instance                 => $instance,
        project                  => $project,
        public_key               => $public_key,
        access_token             => $access_token,
        read_time                => $read_time,
        valid_duration           => $valid_duration,
    );

Calls the RPC method C<GenerateEphemeralCert> on C<google.cloud.sql.v1beta4.SqlConnectService>.

Request: L<Google::Cloud::Sql::V1beta4::CloudSqlConnect::GenerateEphemeralCertRequest>

Returns: L<Google::Cloud::Sql::V1beta4::CloudSqlConnect::GenerateEphemeralCertResponse>

Parameters:

=over 4

=item * C<instance> - C<string>

=item * C<project> - C<string>

=item * C<public_key> - C<string>

=item * C<access_token> - C<string>

=item * C<read_time> - L<Google::Protobuf::Timestamp::Timestamp>

=item * C<valid_duration> - L<Google::Protobuf::Duration::Duration>

=back

=item * B<stream_sql_data>

    my $response = $client->stream_sql_data(
        ack                      => $ack,
        instance_id              => $instance_id,
    );

Calls the RPC method C<StreamSqlData> on C<google.cloud.sql.v1beta4.SqlDataService>.

Request: L<Google::Cloud::Sql::V1beta4::CloudSqlData::StreamSqlDataRequest>

Returns: L<Google::Cloud::Sql::V1beta4::CloudSqlData::StreamSqlDataResponse>

Parameters:

=over 4

=item * C<ack> - L<Google::Cloud::Sql::V1beta4::CloudSqlData::Ack>

=item * C<instance_id> - C<string>

=back

=item * B<start_replay>

    my $response = $client->start_replay(
        project                  => $project,
        instance                 => $instance,
        start_workload_replay_context => $start_workload_replay_context,
        workload_id              => $workload_id,
    );

Calls the RPC method C<StartReplay> on C<google.cloud.sql.v1beta4.SqlWorkloadCapturesService>.

Request: L<Google::Cloud::Sql::V1beta4::CloudSqlWorkloadCaptures::WorkloadCapturesStartReplayRequest>

Returns: L<Google::Cloud::Sql::V1beta4::CloudSqlResources::Operation>

Parameters:

=over 4

=item * C<project> - C<string>

=item * C<instance> - C<string>

=item * C<start_workload_replay_context> - L<Google::Cloud::Sql::V1beta4::CloudSqlResources::StartWorkloadReplayContext>

=item * C<workload_id> - C<string>

=back

=item * B<stop_replay>

    my $response = $client->stop_replay(
        project                  => $project,
        instance                 => $instance,
        stop_workload_replay_context => $stop_workload_replay_context,
    );

Calls the RPC method C<StopReplay> on C<google.cloud.sql.v1beta4.SqlWorkloadCapturesService>.

Request: L<Google::Cloud::Sql::V1beta4::CloudSqlWorkloadCaptures::WorkloadCapturesStopReplayRequest>

Returns: L<Google::Cloud::Sql::V1beta4::CloudSqlResources::Operation>

Parameters:

=over 4

=item * C<project> - C<string>

=item * C<instance> - C<string>

=item * C<stop_workload_replay_context> - L<Google::Cloud::Sql::V1beta4::CloudSqlResources::StopWorkloadReplayContext>

=back

=back



=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
