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
    for my $pkg (qw( Google::Cloud::Dialogflow::V2beta1::Agent::Agent Google::Cloud::Dialogflow::V2beta1::AnswerRecord::AnswerRecord Google::Cloud::Dialogflow::V2beta1::CompanionAgent::CompanionAgent Google::Cloud::Dialogflow::V2beta1::Context::ListContextsResponse Google::Cloud::Dialogflow::V2beta1::Conversation::Conversation Google::Cloud::Dialogflow::V2beta1::ConversationProfile::ListConversationProfilesResponse Google::Cloud::Dialogflow::V2beta1::Document::ListDocumentsResponse Google::Cloud::Dialogflow::V2beta1::EncryptionSpec::EncryptionSpec Google::Cloud::Dialogflow::V2beta1::EntityType::EntityType Google::Cloud::Dialogflow::V2beta1::EntityType::ListEntityTypesResponse Google::Cloud::Dialogflow::V2beta1::Environment::Environment Google::Cloud::Dialogflow::V2beta1::Environment::ListEnvironmentsResponse Google::Cloud::Dialogflow::V2beta1::Fulfillment::Fulfillment Google::Cloud::Dialogflow::V2beta1::Generator::Generator Google::Cloud::Dialogflow::V2beta1::Intent::Intent Google::Cloud::Dialogflow::V2beta1::Intent::ListIntentsResponse Google::Cloud::Dialogflow::V2beta1::KnowledgeBase::KnowledgeBase Google::Cloud::Dialogflow::V2beta1::KnowledgeBase::ListKnowledgeBasesResponse Google::Cloud::Dialogflow::V2beta1::Participant::Participant Google::Cloud::Dialogflow::V2beta1::PhoneNumber::ListPhoneNumbersResponse Google::Cloud::Dialogflow::V2beta1::Session::DetectIntentResponse Google::Cloud::Dialogflow::V2beta1::Session::StreamingDetectIntentResponse Google::Cloud::Dialogflow::V2beta1::SessionEntityType::ListSessionEntityTypesResponse Google::Cloud::Dialogflow::V2beta1::SipTrunk::SipTrunk Google::Cloud::Dialogflow::V2beta1::Tool::Tool Google::Cloud::Dialogflow::V2beta1::Version::ListVersionsResponse Google::Cloud::Dialogflow::V2beta1::Version::Version Google::Longrunning::Operations::Operation Google::Protobuf::Empty::Empty )) {
        unless ($pkg->can('new')) {
            no strict 'refs';
            *{"${pkg}::new"} = sub { bless {}, $_[0] };
            $INC{join('/', split('::', $pkg)) . '.pm'} = 1;
        }
    }
}

# D. Main test execution
package main;
use Google::Cloud::Dialogflow::V2beta1;

my $client = Google::Cloud::Dialogflow::V2beta1->new();
ok($client, 'Instantiated generated client');
isa_ok($client->transport, 'Google::gRPC::Client', 'Client transport');

subtest 'get_agent method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.dialogflow.v2beta1.Agents', 'Correct service path');
        is($args->{method}, 'GetAgent', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Dialogflow::V2beta1::Agent::GetAgentRequest', 'Request object');
        
        my $response = 'Google::Cloud::Dialogflow::V2beta1::Agent::Agent'->new();
        return $response;
    };
    
    my $res = $client->get_agent();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Dialogflow::V2beta1::Agent::Agent', 'Response object class');
    done_testing();
};

subtest 'get_answer_record method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.dialogflow.v2beta1.AnswerRecords', 'Correct service path');
        is($args->{method}, 'GetAnswerRecord', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Dialogflow::V2beta1::AnswerRecord::GetAnswerRecordRequest', 'Request object');
        
        my $response = 'Google::Cloud::Dialogflow::V2beta1::AnswerRecord::AnswerRecord'->new();
        return $response;
    };
    
    my $res = $client->get_answer_record();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Dialogflow::V2beta1::AnswerRecord::AnswerRecord', 'Response object class');
    done_testing();
};

subtest 'create_companion_agent method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.dialogflow.v2beta1.CompanionAgents', 'Correct service path');
        is($args->{method}, 'CreateCompanionAgent', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Dialogflow::V2beta1::CompanionAgent::CreateCompanionAgentRequest', 'Request object');
        
        my $response = 'Google::Cloud::Dialogflow::V2beta1::CompanionAgent::CompanionAgent'->new();
        return $response;
    };
    
    my $res = $client->create_companion_agent();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Dialogflow::V2beta1::CompanionAgent::CompanionAgent', 'Response object class');
    done_testing();
};

subtest 'list_contexts method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.dialogflow.v2beta1.Contexts', 'Correct service path');
        is($args->{method}, 'ListContexts', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Dialogflow::V2beta1::Context::ListContextsRequest', 'Request object');
        
        my $response = 'Google::Cloud::Dialogflow::V2beta1::Context::ListContextsResponse'->new();
        return $response;
    };
    
    my $res = $client->list_contexts();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Dialogflow::V2beta1::Context::ListContextsResponse', 'Response object class');
    done_testing();
};

subtest 'create_conversation method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.dialogflow.v2beta1.Conversations', 'Correct service path');
        is($args->{method}, 'CreateConversation', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Dialogflow::V2beta1::Conversation::CreateConversationRequest', 'Request object');
        
        my $response = 'Google::Cloud::Dialogflow::V2beta1::Conversation::Conversation'->new();
        return $response;
    };
    
    my $res = $client->create_conversation();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Dialogflow::V2beta1::Conversation::Conversation', 'Response object class');
    done_testing();
};

subtest 'list_conversation_profiles method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.dialogflow.v2beta1.ConversationProfiles', 'Correct service path');
        is($args->{method}, 'ListConversationProfiles', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Dialogflow::V2beta1::ConversationProfile::ListConversationProfilesRequest', 'Request object');
        
        my $response = 'Google::Cloud::Dialogflow::V2beta1::ConversationProfile::ListConversationProfilesResponse'->new();
        return $response;
    };
    
    my $res = $client->list_conversation_profiles();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Dialogflow::V2beta1::ConversationProfile::ListConversationProfilesResponse', 'Response object class');
    done_testing();
};

subtest 'list_documents method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.dialogflow.v2beta1.Documents', 'Correct service path');
        is($args->{method}, 'ListDocuments', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Dialogflow::V2beta1::Document::ListDocumentsRequest', 'Request object');
        
        my $response = 'Google::Cloud::Dialogflow::V2beta1::Document::ListDocumentsResponse'->new();
        return $response;
    };
    
    my $res = $client->list_documents();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Dialogflow::V2beta1::Document::ListDocumentsResponse', 'Response object class');
    done_testing();
};

subtest 'get_encryption_spec method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.dialogflow.v2beta1.EncryptionSpecService', 'Correct service path');
        is($args->{method}, 'GetEncryptionSpec', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Dialogflow::V2beta1::EncryptionSpec::GetEncryptionSpecRequest', 'Request object');
        
        my $response = 'Google::Cloud::Dialogflow::V2beta1::EncryptionSpec::EncryptionSpec'->new();
        return $response;
    };
    
    my $res = $client->get_encryption_spec();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Dialogflow::V2beta1::EncryptionSpec::EncryptionSpec', 'Response object class');
    done_testing();
};

subtest 'initialize_encryption_spec method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.dialogflow.v2beta1.EncryptionSpecService', 'Correct service path');
        is($args->{method}, 'InitializeEncryptionSpec', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Dialogflow::V2beta1::EncryptionSpec::InitializeEncryptionSpecRequest', 'Request object');
        
        my $response = 'Google::Longrunning::Operations::Operation'->new();
        return $response;
    };
    
    my $res = $client->initialize_encryption_spec();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Longrunning::Operations::Operation', 'Response object class');
    done_testing();
};

subtest 'list_entity_types method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.dialogflow.v2beta1.EntityTypes', 'Correct service path');
        is($args->{method}, 'ListEntityTypes', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Dialogflow::V2beta1::EntityType::ListEntityTypesRequest', 'Request object');
        
        my $response = 'Google::Cloud::Dialogflow::V2beta1::EntityType::ListEntityTypesResponse'->new();
        return $response;
    };
    
    my $res = $client->list_entity_types();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Dialogflow::V2beta1::EntityType::ListEntityTypesResponse', 'Response object class');
    done_testing();
};

subtest 'update_entity_type method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.dialogflow.v2beta1.EntityTypes', 'Correct service path');
        is($args->{method}, 'UpdateEntityType', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Dialogflow::V2beta1::EntityType::UpdateEntityTypeRequest', 'Request object');
        
        my $response = 'Google::Cloud::Dialogflow::V2beta1::EntityType::EntityType'->new();
        return $response;
    };
    
    my $res = $client->update_entity_type();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Dialogflow::V2beta1::EntityType::EntityType', 'Response object class');
    done_testing();
};

subtest 'batch_delete_entity_types method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.dialogflow.v2beta1.EntityTypes', 'Correct service path');
        is($args->{method}, 'BatchDeleteEntityTypes', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Dialogflow::V2beta1::EntityType::BatchDeleteEntityTypesRequest', 'Request object');
        
        my $response = 'Google::Longrunning::Operations::Operation'->new();
        return $response;
    };
    
    my $res = $client->batch_delete_entity_types();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Longrunning::Operations::Operation', 'Response object class');
    done_testing();
};

subtest 'list_environments method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.dialogflow.v2beta1.Environments', 'Correct service path');
        is($args->{method}, 'ListEnvironments', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Dialogflow::V2beta1::Environment::ListEnvironmentsRequest', 'Request object');
        
        my $response = 'Google::Cloud::Dialogflow::V2beta1::Environment::ListEnvironmentsResponse'->new();
        return $response;
    };
    
    my $res = $client->list_environments();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Dialogflow::V2beta1::Environment::ListEnvironmentsResponse', 'Response object class');
    done_testing();
};

subtest 'update_environment method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.dialogflow.v2beta1.Environments', 'Correct service path');
        is($args->{method}, 'UpdateEnvironment', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Dialogflow::V2beta1::Environment::UpdateEnvironmentRequest', 'Request object');
        
        my $response = 'Google::Cloud::Dialogflow::V2beta1::Environment::Environment'->new();
        return $response;
    };
    
    my $res = $client->update_environment();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Dialogflow::V2beta1::Environment::Environment', 'Response object class');
    done_testing();
};

subtest 'get_fulfillment method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.dialogflow.v2beta1.Fulfillments', 'Correct service path');
        is($args->{method}, 'GetFulfillment', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Dialogflow::V2beta1::Fulfillment::GetFulfillmentRequest', 'Request object');
        
        my $response = 'Google::Cloud::Dialogflow::V2beta1::Fulfillment::Fulfillment'->new();
        return $response;
    };
    
    my $res = $client->get_fulfillment();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Dialogflow::V2beta1::Fulfillment::Fulfillment', 'Response object class');
    done_testing();
};

subtest 'create_generator method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.dialogflow.v2beta1.Generators', 'Correct service path');
        is($args->{method}, 'CreateGenerator', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Dialogflow::V2beta1::Generator::CreateGeneratorRequest', 'Request object');
        
        my $response = 'Google::Cloud::Dialogflow::V2beta1::Generator::Generator'->new();
        return $response;
    };
    
    my $res = $client->create_generator();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Dialogflow::V2beta1::Generator::Generator', 'Response object class');
    done_testing();
};

subtest 'create_generator_evaluation method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.dialogflow.v2beta1.GeneratorEvaluations', 'Correct service path');
        is($args->{method}, 'CreateGeneratorEvaluation', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Dialogflow::V2beta1::GeneratorEvaluation::CreateGeneratorEvaluationRequest', 'Request object');
        
        my $response = 'Google::Longrunning::Operations::Operation'->new();
        return $response;
    };
    
    my $res = $client->create_generator_evaluation();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Longrunning::Operations::Operation', 'Response object class');
    done_testing();
};

subtest 'list_intents method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.dialogflow.v2beta1.Intents', 'Correct service path');
        is($args->{method}, 'ListIntents', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Dialogflow::V2beta1::Intent::ListIntentsRequest', 'Request object');
        
        my $response = 'Google::Cloud::Dialogflow::V2beta1::Intent::ListIntentsResponse'->new();
        return $response;
    };
    
    my $res = $client->list_intents();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Dialogflow::V2beta1::Intent::ListIntentsResponse', 'Response object class');
    done_testing();
};

subtest 'update_intent method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.dialogflow.v2beta1.Intents', 'Correct service path');
        is($args->{method}, 'UpdateIntent', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Dialogflow::V2beta1::Intent::UpdateIntentRequest', 'Request object');
        
        my $response = 'Google::Cloud::Dialogflow::V2beta1::Intent::Intent'->new();
        return $response;
    };
    
    my $res = $client->update_intent();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Dialogflow::V2beta1::Intent::Intent', 'Response object class');
    done_testing();
};

subtest 'batch_delete_intents method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.dialogflow.v2beta1.Intents', 'Correct service path');
        is($args->{method}, 'BatchDeleteIntents', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Dialogflow::V2beta1::Intent::BatchDeleteIntentsRequest', 'Request object');
        
        my $response = 'Google::Longrunning::Operations::Operation'->new();
        return $response;
    };
    
    my $res = $client->batch_delete_intents();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Longrunning::Operations::Operation', 'Response object class');
    done_testing();
};

subtest 'list_knowledge_bases method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.dialogflow.v2beta1.KnowledgeBases', 'Correct service path');
        is($args->{method}, 'ListKnowledgeBases', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Dialogflow::V2beta1::KnowledgeBase::ListKnowledgeBasesRequest', 'Request object');
        
        my $response = 'Google::Cloud::Dialogflow::V2beta1::KnowledgeBase::ListKnowledgeBasesResponse'->new();
        return $response;
    };
    
    my $res = $client->list_knowledge_bases();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Dialogflow::V2beta1::KnowledgeBase::ListKnowledgeBasesResponse', 'Response object class');
    done_testing();
};

subtest 'get_knowledge_base method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.dialogflow.v2beta1.KnowledgeBases', 'Correct service path');
        is($args->{method}, 'GetKnowledgeBase', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Dialogflow::V2beta1::KnowledgeBase::GetKnowledgeBaseRequest', 'Request object');
        
        my $response = 'Google::Cloud::Dialogflow::V2beta1::KnowledgeBase::KnowledgeBase'->new();
        return $response;
    };
    
    my $res = $client->get_knowledge_base();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Dialogflow::V2beta1::KnowledgeBase::KnowledgeBase', 'Response object class');
    done_testing();
};

subtest 'delete_knowledge_base method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.dialogflow.v2beta1.KnowledgeBases', 'Correct service path');
        is($args->{method}, 'DeleteKnowledgeBase', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Dialogflow::V2beta1::KnowledgeBase::DeleteKnowledgeBaseRequest', 'Request object');
        
        my $response = 'Google::Protobuf::Empty::Empty'->new();
        return $response;
    };
    
    my $res = $client->delete_knowledge_base();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Protobuf::Empty::Empty', 'Response object class');
    done_testing();
};

subtest 'create_participant method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.dialogflow.v2beta1.Participants', 'Correct service path');
        is($args->{method}, 'CreateParticipant', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Dialogflow::V2beta1::Participant::CreateParticipantRequest', 'Request object');
        
        my $response = 'Google::Cloud::Dialogflow::V2beta1::Participant::Participant'->new();
        return $response;
    };
    
    my $res = $client->create_participant();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Dialogflow::V2beta1::Participant::Participant', 'Response object class');
    done_testing();
};

subtest 'list_phone_numbers method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.dialogflow.v2beta1.PhoneNumbers', 'Correct service path');
        is($args->{method}, 'ListPhoneNumbers', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Dialogflow::V2beta1::PhoneNumber::ListPhoneNumbersRequest', 'Request object');
        
        my $response = 'Google::Cloud::Dialogflow::V2beta1::PhoneNumber::ListPhoneNumbersResponse'->new();
        return $response;
    };
    
    my $res = $client->list_phone_numbers();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Dialogflow::V2beta1::PhoneNumber::ListPhoneNumbersResponse', 'Response object class');
    done_testing();
};

subtest 'detect_intent method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.dialogflow.v2beta1.Sessions', 'Correct service path');
        is($args->{method}, 'DetectIntent', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Dialogflow::V2beta1::Session::DetectIntentRequest', 'Request object');
        
        my $response = 'Google::Cloud::Dialogflow::V2beta1::Session::DetectIntentResponse'->new();
        return $response;
    };
    
    my $res = $client->detect_intent();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Dialogflow::V2beta1::Session::DetectIntentResponse', 'Response object class');
    done_testing();
};

subtest 'streaming_detect_intent method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.dialogflow.v2beta1.Sessions', 'Correct service path');
        is($args->{method}, 'StreamingDetectIntent', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Dialogflow::V2beta1::Session::StreamingDetectIntentRequest', 'Request object');
        
        my $response = 'Google::Cloud::Dialogflow::V2beta1::Session::StreamingDetectIntentResponse'->new();
        return $response;
    };
    
    my $res = $client->streaming_detect_intent();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Dialogflow::V2beta1::Session::StreamingDetectIntentResponse', 'Response object class');
    done_testing();
};

subtest 'list_session_entity_types method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.dialogflow.v2beta1.SessionEntityTypes', 'Correct service path');
        is($args->{method}, 'ListSessionEntityTypes', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Dialogflow::V2beta1::SessionEntityType::ListSessionEntityTypesRequest', 'Request object');
        
        my $response = 'Google::Cloud::Dialogflow::V2beta1::SessionEntityType::ListSessionEntityTypesResponse'->new();
        return $response;
    };
    
    my $res = $client->list_session_entity_types();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Dialogflow::V2beta1::SessionEntityType::ListSessionEntityTypesResponse', 'Response object class');
    done_testing();
};

subtest 'create_sip_trunk method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.dialogflow.v2beta1.SipTrunks', 'Correct service path');
        is($args->{method}, 'CreateSipTrunk', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Dialogflow::V2beta1::SipTrunk::CreateSipTrunkRequest', 'Request object');
        
        my $response = 'Google::Cloud::Dialogflow::V2beta1::SipTrunk::SipTrunk'->new();
        return $response;
    };
    
    my $res = $client->create_sip_trunk();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Dialogflow::V2beta1::SipTrunk::SipTrunk', 'Response object class');
    done_testing();
};

subtest 'create_tool method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.dialogflow.v2beta1.Tools', 'Correct service path');
        is($args->{method}, 'CreateTool', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Dialogflow::V2beta1::Tool::CreateToolRequest', 'Request object');
        
        my $response = 'Google::Cloud::Dialogflow::V2beta1::Tool::Tool'->new();
        return $response;
    };
    
    my $res = $client->create_tool();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Dialogflow::V2beta1::Tool::Tool', 'Response object class');
    done_testing();
};

subtest 'list_versions method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.dialogflow.v2beta1.Versions', 'Correct service path');
        is($args->{method}, 'ListVersions', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Dialogflow::V2beta1::Version::ListVersionsRequest', 'Request object');
        
        my $response = 'Google::Cloud::Dialogflow::V2beta1::Version::ListVersionsResponse'->new();
        return $response;
    };
    
    my $res = $client->list_versions();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Dialogflow::V2beta1::Version::ListVersionsResponse', 'Response object class');
    done_testing();
};

subtest 'update_version method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.dialogflow.v2beta1.Versions', 'Correct service path');
        is($args->{method}, 'UpdateVersion', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Dialogflow::V2beta1::Version::UpdateVersionRequest', 'Request object');
        
        my $response = 'Google::Cloud::Dialogflow::V2beta1::Version::Version'->new();
        return $response;
    };
    
    my $res = $client->update_version();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Dialogflow::V2beta1::Version::Version', 'Response object class');
    done_testing();
};

done_testing();
