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
    for my $pkg (qw( Google::Developers::Knowledge::V1::Developerknowledge::AnswerQueryResponse Google::Developers::Knowledge::V1::Developerknowledge::BatchGetDocumentsResponse Google::Developers::Knowledge::V1::Developerknowledge::Document Google::Developers::Knowledge::V1::Developerknowledge::SearchDocumentChunksResponse )) {
        unless ($pkg->can('new')) {
            no strict 'refs';
            *{"${pkg}::new"} = sub { bless {}, $_[0] };
            $INC{join('/', split('::', $pkg)) . '.pm'} = 1;
        }
    }
}

# D. Main test execution
package main;
use Google::Cloud::Developers::Knowledge::V1;

my $client = Google::Cloud::Developers::Knowledge::V1->new();
ok($client, 'Instantiated generated client');
isa_ok($client->transport, 'Google::gRPC::Client', 'Client transport');

subtest 'search_document_chunks method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.developers.knowledge.v1.DeveloperKnowledge', 'Correct service path');
        is($args->{method}, 'SearchDocumentChunks', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Developers::Knowledge::V1::Developerknowledge::SearchDocumentChunksRequest', 'Request object');
        
        my $response = 'Google::Developers::Knowledge::V1::Developerknowledge::SearchDocumentChunksResponse'->new();
        return $response;
    };
    
    my $res = $client->search_document_chunks();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Developers::Knowledge::V1::Developerknowledge::SearchDocumentChunksResponse', 'Response object class');
    done_testing();
};

subtest 'get_document method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.developers.knowledge.v1.DeveloperKnowledge', 'Correct service path');
        is($args->{method}, 'GetDocument', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Developers::Knowledge::V1::Developerknowledge::GetDocumentRequest', 'Request object');
        
        my $response = 'Google::Developers::Knowledge::V1::Developerknowledge::Document'->new();
        return $response;
    };
    
    my $res = $client->get_document();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Developers::Knowledge::V1::Developerknowledge::Document', 'Response object class');
    done_testing();
};

subtest 'batch_get_documents method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.developers.knowledge.v1.DeveloperKnowledge', 'Correct service path');
        is($args->{method}, 'BatchGetDocuments', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Developers::Knowledge::V1::Developerknowledge::BatchGetDocumentsRequest', 'Request object');
        
        my $response = 'Google::Developers::Knowledge::V1::Developerknowledge::BatchGetDocumentsResponse'->new();
        return $response;
    };
    
    my $res = $client->batch_get_documents();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Developers::Knowledge::V1::Developerknowledge::BatchGetDocumentsResponse', 'Response object class');
    done_testing();
};

subtest 'answer_query method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.developers.knowledge.v1.DeveloperKnowledge', 'Correct service path');
        is($args->{method}, 'AnswerQuery', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Developers::Knowledge::V1::Developerknowledge::AnswerQueryRequest', 'Request object');
        
        my $response = 'Google::Developers::Knowledge::V1::Developerknowledge::AnswerQueryResponse'->new();
        return $response;
    };
    
    my $res = $client->answer_query();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Developers::Knowledge::V1::Developerknowledge::AnswerQueryResponse', 'Response object class');
    done_testing();
};

done_testing();
