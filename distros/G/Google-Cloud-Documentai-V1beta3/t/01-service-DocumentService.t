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
    for my $pkg (qw( Google::Cloud::Documentai::V1beta3::Dataset::DatasetSchema Google::Cloud::Documentai::V1beta3::DocumentService::GetDocumentResponse Google::Longrunning::Operations::Operation )) {
        unless ($pkg->can('new')) {
            no strict 'refs';
            *{"${pkg}::new"} = sub { bless {}, $_[0] };
            $INC{join('/', split('::', $pkg)) . '.pm'} = 1;
        }
    }
}

# D. Main test execution
package main;
use Google::Cloud::Documentai::V1beta3::DocumentServiceClient;

my $client = Google::Cloud::Documentai::V1beta3::DocumentServiceClient->new();
ok($client, 'Instantiated generated client');
isa_ok($client->transport, 'Google::gRPC::Client', 'Client transport');

subtest 'update_dataset method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.documentai.v1beta3.DocumentService', 'Correct service path');
        is($args->{method}, 'UpdateDataset', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Documentai::V1beta3::DocumentService::UpdateDatasetRequest', 'Request object');
        
        my $response = 'Google::Longrunning::Operations::Operation'->new();
        return $response;
    };
    
    my $res = $client->update_dataset();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Longrunning::Operations::Operation', 'Response object class');
    done_testing();
};

subtest 'get_document method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.documentai.v1beta3.DocumentService', 'Correct service path');
        is($args->{method}, 'GetDocument', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Documentai::V1beta3::DocumentService::GetDocumentRequest', 'Request object');
        
        my $response = 'Google::Cloud::Documentai::V1beta3::DocumentService::GetDocumentResponse'->new();
        return $response;
    };
    
    my $res = $client->get_document();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Documentai::V1beta3::DocumentService::GetDocumentResponse', 'Response object class');
    done_testing();
};

subtest 'batch_delete_documents method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.documentai.v1beta3.DocumentService', 'Correct service path');
        is($args->{method}, 'BatchDeleteDocuments', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Documentai::V1beta3::DocumentService::BatchDeleteDocumentsRequest', 'Request object');
        
        my $response = 'Google::Longrunning::Operations::Operation'->new();
        return $response;
    };
    
    my $res = $client->batch_delete_documents();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Longrunning::Operations::Operation', 'Response object class');
    done_testing();
};

subtest 'update_dataset_schema method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.documentai.v1beta3.DocumentService', 'Correct service path');
        is($args->{method}, 'UpdateDatasetSchema', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Documentai::V1beta3::DocumentService::UpdateDatasetSchemaRequest', 'Request object');
        
        my $response = 'Google::Cloud::Documentai::V1beta3::Dataset::DatasetSchema'->new();
        return $response;
    };
    
    my $res = $client->update_dataset_schema();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Documentai::V1beta3::Dataset::DatasetSchema', 'Response object class');
    done_testing();
};

done_testing();
