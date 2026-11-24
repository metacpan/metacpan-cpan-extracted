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
    for my $pkg (qw( Google::Cloud::Dialogflow::V2::KnowledgeBase::KnowledgeBase Google::Cloud::Dialogflow::V2::KnowledgeBase::ListKnowledgeBasesResponse Google::Protobuf::Empty::Empty )) {
        unless ($pkg->can('new')) {
            no strict 'refs';
            *{"${pkg}::new"} = sub { bless {}, $_[0] };
            $INC{join('/', split('::', $pkg)) . '.pm'} = 1;
        }
    }
}

# D. Main test execution
package main;
use Google::Cloud::Dialogflow::V2::KnowledgeBasesClient;

my $client = Google::Cloud::Dialogflow::V2::KnowledgeBasesClient->new();
ok($client, 'Instantiated generated client');
isa_ok($client->transport, 'Google::gRPC::Client', 'Client transport');

subtest 'list_knowledge_bases method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.dialogflow.v2.KnowledgeBases', 'Correct service path');
        is($args->{method}, 'ListKnowledgeBases', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Dialogflow::V2::KnowledgeBase::ListKnowledgeBasesRequest', 'Request object');
        
        my $response = 'Google::Cloud::Dialogflow::V2::KnowledgeBase::ListKnowledgeBasesResponse'->new();
        return $response;
    };
    
    my $res = $client->list_knowledge_bases();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Dialogflow::V2::KnowledgeBase::ListKnowledgeBasesResponse', 'Response object class');
    done_testing();
};

subtest 'get_knowledge_base method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.dialogflow.v2.KnowledgeBases', 'Correct service path');
        is($args->{method}, 'GetKnowledgeBase', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Dialogflow::V2::KnowledgeBase::GetKnowledgeBaseRequest', 'Request object');
        
        my $response = 'Google::Cloud::Dialogflow::V2::KnowledgeBase::KnowledgeBase'->new();
        return $response;
    };
    
    my $res = $client->get_knowledge_base();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Dialogflow::V2::KnowledgeBase::KnowledgeBase', 'Response object class');
    done_testing();
};

subtest 'delete_knowledge_base method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.dialogflow.v2.KnowledgeBases', 'Correct service path');
        is($args->{method}, 'DeleteKnowledgeBase', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Dialogflow::V2::KnowledgeBase::DeleteKnowledgeBaseRequest', 'Request object');
        
        my $response = 'Google::Protobuf::Empty::Empty'->new();
        return $response;
    };
    
    my $res = $client->delete_knowledge_base();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Protobuf::Empty::Empty', 'Response object class');
    done_testing();
};

done_testing();
