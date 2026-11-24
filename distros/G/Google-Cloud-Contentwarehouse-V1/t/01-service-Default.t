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
    for my $pkg (qw( Google::Cloud::Contentwarehouse::V1::DocumentLinkService::ListLinkedTargetsResponse Google::Cloud::Contentwarehouse::V1::DocumentSchema::DocumentSchema Google::Cloud::Contentwarehouse::V1::DocumentService::CreateDocumentResponse Google::Cloud::Contentwarehouse::V1::RuleEngine::RuleSet Google::Cloud::Contentwarehouse::V1::Synonymset::SynonymSet Google::Longrunning::Operations::Operation )) {
        unless ($pkg->can('new')) {
            no strict 'refs';
            *{"${pkg}::new"} = sub { bless {}, $_[0] };
            $INC{join('/', split('::', $pkg)) . '.pm'} = 1;
        }
    }
}

# D. Main test execution
package main;
use Google::Cloud::Contentwarehouse::V1;

my $client = Google::Cloud::Contentwarehouse::V1->new();
ok($client, 'Instantiated generated client');
isa_ok($client->transport, 'Google::gRPC::Client', 'Client transport');

subtest 'list_linked_targets method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.contentwarehouse.v1.DocumentLinkService', 'Correct service path');
        is($args->{method}, 'ListLinkedTargets', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Contentwarehouse::V1::DocumentLinkService::ListLinkedTargetsRequest', 'Request object');
        
        my $response = 'Google::Cloud::Contentwarehouse::V1::DocumentLinkService::ListLinkedTargetsResponse'->new();
        return $response;
    };
    
    my $res = $client->list_linked_targets();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Contentwarehouse::V1::DocumentLinkService::ListLinkedTargetsResponse', 'Response object class');
    done_testing();
};

subtest 'create_document_schema method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.contentwarehouse.v1.DocumentSchemaService', 'Correct service path');
        is($args->{method}, 'CreateDocumentSchema', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Contentwarehouse::V1::DocumentSchemaService::CreateDocumentSchemaRequest', 'Request object');
        
        my $response = 'Google::Cloud::Contentwarehouse::V1::DocumentSchema::DocumentSchema'->new();
        return $response;
    };
    
    my $res = $client->create_document_schema();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Contentwarehouse::V1::DocumentSchema::DocumentSchema', 'Response object class');
    done_testing();
};

subtest 'create_document method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.contentwarehouse.v1.DocumentService', 'Correct service path');
        is($args->{method}, 'CreateDocument', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Contentwarehouse::V1::DocumentServiceRequest::CreateDocumentRequest', 'Request object');
        
        my $response = 'Google::Cloud::Contentwarehouse::V1::DocumentService::CreateDocumentResponse'->new();
        return $response;
    };
    
    my $res = $client->create_document();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Contentwarehouse::V1::DocumentService::CreateDocumentResponse', 'Response object class');
    done_testing();
};

subtest 'run_pipeline method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.contentwarehouse.v1.PipelineService', 'Correct service path');
        is($args->{method}, 'RunPipeline', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Contentwarehouse::V1::PipelineService::RunPipelineRequest', 'Request object');
        
        my $response = 'Google::Longrunning::Operations::Operation'->new();
        return $response;
    };
    
    my $res = $client->run_pipeline();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Longrunning::Operations::Operation', 'Response object class');
    done_testing();
};

subtest 'create_rule_set method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.contentwarehouse.v1.RuleSetService', 'Correct service path');
        is($args->{method}, 'CreateRuleSet', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Contentwarehouse::V1::RulesetServiceRequest::CreateRuleSetRequest', 'Request object');
        
        my $response = 'Google::Cloud::Contentwarehouse::V1::RuleEngine::RuleSet'->new();
        return $response;
    };
    
    my $res = $client->create_rule_set();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Contentwarehouse::V1::RuleEngine::RuleSet', 'Response object class');
    done_testing();
};

subtest 'create_synonym_set method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.contentwarehouse.v1.SynonymSetService', 'Correct service path');
        is($args->{method}, 'CreateSynonymSet', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Contentwarehouse::V1::SynonymsetServiceRequest::CreateSynonymSetRequest', 'Request object');
        
        my $response = 'Google::Cloud::Contentwarehouse::V1::Synonymset::SynonymSet'->new();
        return $response;
    };
    
    my $res = $client->create_synonym_set();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Contentwarehouse::V1::Synonymset::SynonymSet', 'Response object class');
    done_testing();
};

done_testing();
