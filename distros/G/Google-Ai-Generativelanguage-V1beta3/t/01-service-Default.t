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
    for my $pkg (qw( Google::Ai::Generativelanguage::V1beta3::DiscussService::CountMessageTokensResponse Google::Ai::Generativelanguage::V1beta3::DiscussService::GenerateMessageResponse Google::Ai::Generativelanguage::V1beta3::Model::Model Google::Ai::Generativelanguage::V1beta3::ModelService::ListModelsResponse Google::Ai::Generativelanguage::V1beta3::ModelService::ListTunedModelsResponse Google::Ai::Generativelanguage::V1beta3::Permission::Permission Google::Ai::Generativelanguage::V1beta3::PermissionService::TransferOwnershipResponse Google::Ai::Generativelanguage::V1beta3::TextService::BatchEmbedTextResponse Google::Ai::Generativelanguage::V1beta3::TextService::CountTextTokensResponse Google::Ai::Generativelanguage::V1beta3::TextService::EmbedTextResponse Google::Ai::Generativelanguage::V1beta3::TextService::GenerateTextResponse Google::Ai::Generativelanguage::V1beta3::TunedModel::TunedModel Google::Longrunning::Operations::Operation Google::Protobuf::Empty::Empty )) {
        unless ($pkg->can('new')) {
            no strict 'refs';
            *{"${pkg}::new"} = sub { bless {}, $_[0] };
            $INC{join('/', split('::', $pkg)) . '.pm'} = 1;
        }
    }
}

# D. Main test execution
package main;
use Google::Ai::Generativelanguage::V1beta3;

my $client = Google::Ai::Generativelanguage::V1beta3->new();
ok($client, 'Instantiated generated client');
isa_ok($client->transport, 'Google::gRPC::Client', 'Client transport');

subtest 'generate_message method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.ai.generativelanguage.v1beta3.DiscussService', 'Correct service path');
        is($args->{method}, 'GenerateMessage', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Ai::Generativelanguage::V1beta3::DiscussService::GenerateMessageRequest', 'Request object');
        
        my $response = 'Google::Ai::Generativelanguage::V1beta3::DiscussService::GenerateMessageResponse'->new();
        return $response;
    };
    
    my $res = $client->generate_message();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Ai::Generativelanguage::V1beta3::DiscussService::GenerateMessageResponse', 'Response object class');
    done_testing();
};

subtest 'count_message_tokens method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.ai.generativelanguage.v1beta3.DiscussService', 'Correct service path');
        is($args->{method}, 'CountMessageTokens', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Ai::Generativelanguage::V1beta3::DiscussService::CountMessageTokensRequest', 'Request object');
        
        my $response = 'Google::Ai::Generativelanguage::V1beta3::DiscussService::CountMessageTokensResponse'->new();
        return $response;
    };
    
    my $res = $client->count_message_tokens();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Ai::Generativelanguage::V1beta3::DiscussService::CountMessageTokensResponse', 'Response object class');
    done_testing();
};

subtest 'get_model method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.ai.generativelanguage.v1beta3.ModelService', 'Correct service path');
        is($args->{method}, 'GetModel', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Ai::Generativelanguage::V1beta3::ModelService::GetModelRequest', 'Request object');
        
        my $response = 'Google::Ai::Generativelanguage::V1beta3::Model::Model'->new();
        return $response;
    };
    
    my $res = $client->get_model();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Ai::Generativelanguage::V1beta3::Model::Model', 'Response object class');
    done_testing();
};

subtest 'list_models method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.ai.generativelanguage.v1beta3.ModelService', 'Correct service path');
        is($args->{method}, 'ListModels', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Ai::Generativelanguage::V1beta3::ModelService::ListModelsRequest', 'Request object');
        
        my $response = 'Google::Ai::Generativelanguage::V1beta3::ModelService::ListModelsResponse'->new();
        return $response;
    };
    
    my $res = $client->list_models();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Ai::Generativelanguage::V1beta3::ModelService::ListModelsResponse', 'Response object class');
    done_testing();
};

subtest 'get_tuned_model method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.ai.generativelanguage.v1beta3.ModelService', 'Correct service path');
        is($args->{method}, 'GetTunedModel', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Ai::Generativelanguage::V1beta3::ModelService::GetTunedModelRequest', 'Request object');
        
        my $response = 'Google::Ai::Generativelanguage::V1beta3::TunedModel::TunedModel'->new();
        return $response;
    };
    
    my $res = $client->get_tuned_model();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Ai::Generativelanguage::V1beta3::TunedModel::TunedModel', 'Response object class');
    done_testing();
};

subtest 'list_tuned_models method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.ai.generativelanguage.v1beta3.ModelService', 'Correct service path');
        is($args->{method}, 'ListTunedModels', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Ai::Generativelanguage::V1beta3::ModelService::ListTunedModelsRequest', 'Request object');
        
        my $response = 'Google::Ai::Generativelanguage::V1beta3::ModelService::ListTunedModelsResponse'->new();
        return $response;
    };
    
    my $res = $client->list_tuned_models();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Ai::Generativelanguage::V1beta3::ModelService::ListTunedModelsResponse', 'Response object class');
    done_testing();
};

subtest 'create_tuned_model method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.ai.generativelanguage.v1beta3.ModelService', 'Correct service path');
        is($args->{method}, 'CreateTunedModel', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Ai::Generativelanguage::V1beta3::ModelService::CreateTunedModelRequest', 'Request object');
        
        my $response = 'Google::Longrunning::Operations::Operation'->new();
        return $response;
    };
    
    my $res = $client->create_tuned_model();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Longrunning::Operations::Operation', 'Response object class');
    done_testing();
};

subtest 'update_tuned_model method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.ai.generativelanguage.v1beta3.ModelService', 'Correct service path');
        is($args->{method}, 'UpdateTunedModel', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Ai::Generativelanguage::V1beta3::ModelService::UpdateTunedModelRequest', 'Request object');
        
        my $response = 'Google::Ai::Generativelanguage::V1beta3::TunedModel::TunedModel'->new();
        return $response;
    };
    
    my $res = $client->update_tuned_model();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Ai::Generativelanguage::V1beta3::TunedModel::TunedModel', 'Response object class');
    done_testing();
};

subtest 'delete_tuned_model method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.ai.generativelanguage.v1beta3.ModelService', 'Correct service path');
        is($args->{method}, 'DeleteTunedModel', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Ai::Generativelanguage::V1beta3::ModelService::DeleteTunedModelRequest', 'Request object');
        
        my $response = 'Google::Protobuf::Empty::Empty'->new();
        return $response;
    };
    
    my $res = $client->delete_tuned_model();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Protobuf::Empty::Empty', 'Response object class');
    done_testing();
};

subtest 'create_permission method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.ai.generativelanguage.v1beta3.PermissionService', 'Correct service path');
        is($args->{method}, 'CreatePermission', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Ai::Generativelanguage::V1beta3::PermissionService::CreatePermissionRequest', 'Request object');
        
        my $response = 'Google::Ai::Generativelanguage::V1beta3::Permission::Permission'->new();
        return $response;
    };
    
    my $res = $client->create_permission();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Ai::Generativelanguage::V1beta3::Permission::Permission', 'Response object class');
    done_testing();
};

subtest 'transfer_ownership method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.ai.generativelanguage.v1beta3.PermissionService', 'Correct service path');
        is($args->{method}, 'TransferOwnership', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Ai::Generativelanguage::V1beta3::PermissionService::TransferOwnershipRequest', 'Request object');
        
        my $response = 'Google::Ai::Generativelanguage::V1beta3::PermissionService::TransferOwnershipResponse'->new();
        return $response;
    };
    
    my $res = $client->transfer_ownership();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Ai::Generativelanguage::V1beta3::PermissionService::TransferOwnershipResponse', 'Response object class');
    done_testing();
};

subtest 'generate_text method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.ai.generativelanguage.v1beta3.TextService', 'Correct service path');
        is($args->{method}, 'GenerateText', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Ai::Generativelanguage::V1beta3::TextService::GenerateTextRequest', 'Request object');
        
        my $response = 'Google::Ai::Generativelanguage::V1beta3::TextService::GenerateTextResponse'->new();
        return $response;
    };
    
    my $res = $client->generate_text();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Ai::Generativelanguage::V1beta3::TextService::GenerateTextResponse', 'Response object class');
    done_testing();
};

subtest 'embed_text method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.ai.generativelanguage.v1beta3.TextService', 'Correct service path');
        is($args->{method}, 'EmbedText', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Ai::Generativelanguage::V1beta3::TextService::EmbedTextRequest', 'Request object');
        
        my $response = 'Google::Ai::Generativelanguage::V1beta3::TextService::EmbedTextResponse'->new();
        return $response;
    };
    
    my $res = $client->embed_text();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Ai::Generativelanguage::V1beta3::TextService::EmbedTextResponse', 'Response object class');
    done_testing();
};

subtest 'batch_embed_text method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.ai.generativelanguage.v1beta3.TextService', 'Correct service path');
        is($args->{method}, 'BatchEmbedText', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Ai::Generativelanguage::V1beta3::TextService::BatchEmbedTextRequest', 'Request object');
        
        my $response = 'Google::Ai::Generativelanguage::V1beta3::TextService::BatchEmbedTextResponse'->new();
        return $response;
    };
    
    my $res = $client->batch_embed_text();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Ai::Generativelanguage::V1beta3::TextService::BatchEmbedTextResponse', 'Response object class');
    done_testing();
};

subtest 'count_text_tokens method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.ai.generativelanguage.v1beta3.TextService', 'Correct service path');
        is($args->{method}, 'CountTextTokens', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Ai::Generativelanguage::V1beta3::TextService::CountTextTokensRequest', 'Request object');
        
        my $response = 'Google::Ai::Generativelanguage::V1beta3::TextService::CountTextTokensResponse'->new();
        return $response;
    };
    
    my $res = $client->count_text_tokens();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Ai::Generativelanguage::V1beta3::TextService::CountTextTokensResponse', 'Response object class');
    done_testing();
};

done_testing();
