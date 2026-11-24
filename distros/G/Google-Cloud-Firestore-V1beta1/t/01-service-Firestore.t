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
    for my $pkg (qw( Google::Firestore::V1beta1::Document::Document Google::Firestore::V1beta1::Firestore::BatchGetDocumentsResponse Google::Firestore::V1beta1::Firestore::BatchWriteResponse Google::Firestore::V1beta1::Firestore::PartitionQueryResponse )) {
        unless ($pkg->can('new')) {
            no strict 'refs';
            *{"${pkg}::new"} = sub { bless {}, $_[0] };
            $INC{join('/', split('::', $pkg)) . '.pm'} = 1;
        }
    }
}

# D. Main test execution
package main;
use Google::Cloud::Firestore::V1beta1::FirestoreClient;

my $client = Google::Cloud::Firestore::V1beta1::FirestoreClient->new();
ok($client, 'Instantiated generated client');
isa_ok($client->transport, 'Google::gRPC::Client', 'Client transport');

subtest 'get_document method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.firestore.v1beta1.Firestore', 'Correct service path');
        is($args->{method}, 'GetDocument', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Firestore::V1beta1::Firestore::GetDocumentRequest', 'Request object');
        
        my $response = 'Google::Firestore::V1beta1::Document::Document'->new();
        return $response;
    };
    
    my $res = $client->get_document();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Firestore::V1beta1::Document::Document', 'Response object class');
    done_testing();
};

subtest 'update_document method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.firestore.v1beta1.Firestore', 'Correct service path');
        is($args->{method}, 'UpdateDocument', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Firestore::V1beta1::Firestore::UpdateDocumentRequest', 'Request object');
        
        my $response = 'Google::Firestore::V1beta1::Document::Document'->new();
        return $response;
    };
    
    my $res = $client->update_document();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Firestore::V1beta1::Document::Document', 'Response object class');
    done_testing();
};

subtest 'batch_get_documents method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.firestore.v1beta1.Firestore', 'Correct service path');
        is($args->{method}, 'BatchGetDocuments', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Firestore::V1beta1::Firestore::BatchGetDocumentsRequest', 'Request object');
        
        my $response = 'Google::Firestore::V1beta1::Firestore::BatchGetDocumentsResponse'->new();
        return $response;
    };
    
    my $res = $client->batch_get_documents();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Firestore::V1beta1::Firestore::BatchGetDocumentsResponse', 'Response object class');
    done_testing();
};

subtest 'partition_query method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.firestore.v1beta1.Firestore', 'Correct service path');
        is($args->{method}, 'PartitionQuery', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Firestore::V1beta1::Firestore::PartitionQueryRequest', 'Request object');
        
        my $response = 'Google::Firestore::V1beta1::Firestore::PartitionQueryResponse'->new();
        return $response;
    };
    
    my $res = $client->partition_query();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Firestore::V1beta1::Firestore::PartitionQueryResponse', 'Response object class');
    done_testing();
};

subtest 'batch_write method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.firestore.v1beta1.Firestore', 'Correct service path');
        is($args->{method}, 'BatchWrite', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Firestore::V1beta1::Firestore::BatchWriteRequest', 'Request object');
        
        my $response = 'Google::Firestore::V1beta1::Firestore::BatchWriteResponse'->new();
        return $response;
    };
    
    my $res = $client->batch_write();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Firestore::V1beta1::Firestore::BatchWriteResponse', 'Response object class');
    done_testing();
};

done_testing();
