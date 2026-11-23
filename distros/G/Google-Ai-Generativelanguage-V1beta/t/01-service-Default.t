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
    for my $pkg (qw( Google::Ai::Generativelanguage::V1beta::CacheService::ListCachedContentsResponse Google::Ai::Generativelanguage::V1beta::CachedContent::CachedContent Google::Ai::Generativelanguage::V1beta::DiscussService::CountMessageTokensResponse Google::Ai::Generativelanguage::V1beta::DiscussService::GenerateMessageResponse Google::Ai::Generativelanguage::V1beta::File::File Google::Ai::Generativelanguage::V1beta::FileService::CreateFileResponse Google::Ai::Generativelanguage::V1beta::FileService::DownloadFileResponse Google::Ai::Generativelanguage::V1beta::FileService::ListFilesResponse Google::Ai::Generativelanguage::V1beta::GenerativeService::BatchEmbedContentsResponse Google::Ai::Generativelanguage::V1beta::GenerativeService::BidiGenerateContentServerMessage Google::Ai::Generativelanguage::V1beta::GenerativeService::CountTokensResponse Google::Ai::Generativelanguage::V1beta::GenerativeService::EmbedContentResponse Google::Ai::Generativelanguage::V1beta::GenerativeService::GenerateAnswerResponse Google::Ai::Generativelanguage::V1beta::GenerativeService::GenerateContentResponse Google::Ai::Generativelanguage::V1beta::Model::Model Google::Ai::Generativelanguage::V1beta::ModelService::ListModelsResponse Google::Ai::Generativelanguage::V1beta::ModelService::ListTunedModelsResponse Google::Ai::Generativelanguage::V1beta::Permission::Permission Google::Ai::Generativelanguage::V1beta::PermissionService::TransferOwnershipResponse Google::Ai::Generativelanguage::V1beta::PredictionService::PredictResponse Google::Ai::Generativelanguage::V1beta::Retriever::Corpus Google::Ai::Generativelanguage::V1beta::TextService::BatchEmbedTextResponse Google::Ai::Generativelanguage::V1beta::TextService::CountTextTokensResponse Google::Ai::Generativelanguage::V1beta::TextService::EmbedTextResponse Google::Ai::Generativelanguage::V1beta::TextService::GenerateTextResponse Google::Ai::Generativelanguage::V1beta::TunedModel::TunedModel Google::Longrunning::Operations::Operation Google::Protobuf::Empty::Empty )) {
        unless ($pkg->can('new')) {
            no strict 'refs';
            *{"${pkg}::new"} = sub { bless {}, $_[0] };
            $INC{join('/', split('::', $pkg)) . '.pm'} = 1;
        }
    }
}

# D. Main test execution
package main;
use Google::Ai::Generativelanguage::V1beta;

my $client = Google::Ai::Generativelanguage::V1beta->new();
ok($client, 'Instantiated generated client');
isa_ok($client->transport, 'Google::gRPC::Client', 'Client transport');

subtest 'list_cached_contents method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.ai.generativelanguage.v1beta.CacheService', 'Correct service path');
        is($args->{method}, 'ListCachedContents', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Ai::Generativelanguage::V1beta::CacheService::ListCachedContentsRequest', 'Request object');
        
        my $response = 'Google::Ai::Generativelanguage::V1beta::CacheService::ListCachedContentsResponse'->new();
        return $response;
    };
    
    my $res = $client->list_cached_contents();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Ai::Generativelanguage::V1beta::CacheService::ListCachedContentsResponse', 'Response object class');
    done_testing();
};

subtest 'create_cached_content method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.ai.generativelanguage.v1beta.CacheService', 'Correct service path');
        is($args->{method}, 'CreateCachedContent', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Ai::Generativelanguage::V1beta::CacheService::CreateCachedContentRequest', 'Request object');
        
        my $response = 'Google::Ai::Generativelanguage::V1beta::CachedContent::CachedContent'->new();
        return $response;
    };
    
    my $res = $client->create_cached_content();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Ai::Generativelanguage::V1beta::CachedContent::CachedContent', 'Response object class');
    done_testing();
};

subtest 'get_cached_content method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.ai.generativelanguage.v1beta.CacheService', 'Correct service path');
        is($args->{method}, 'GetCachedContent', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Ai::Generativelanguage::V1beta::CacheService::GetCachedContentRequest', 'Request object');
        
        my $response = 'Google::Ai::Generativelanguage::V1beta::CachedContent::CachedContent'->new();
        return $response;
    };
    
    my $res = $client->get_cached_content();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Ai::Generativelanguage::V1beta::CachedContent::CachedContent', 'Response object class');
    done_testing();
};

subtest 'update_cached_content method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.ai.generativelanguage.v1beta.CacheService', 'Correct service path');
        is($args->{method}, 'UpdateCachedContent', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Ai::Generativelanguage::V1beta::CacheService::UpdateCachedContentRequest', 'Request object');
        
        my $response = 'Google::Ai::Generativelanguage::V1beta::CachedContent::CachedContent'->new();
        return $response;
    };
    
    my $res = $client->update_cached_content();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Ai::Generativelanguage::V1beta::CachedContent::CachedContent', 'Response object class');
    done_testing();
};

subtest 'delete_cached_content method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.ai.generativelanguage.v1beta.CacheService', 'Correct service path');
        is($args->{method}, 'DeleteCachedContent', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Ai::Generativelanguage::V1beta::CacheService::DeleteCachedContentRequest', 'Request object');
        
        my $response = 'Google::Protobuf::Empty::Empty'->new();
        return $response;
    };
    
    my $res = $client->delete_cached_content();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Protobuf::Empty::Empty', 'Response object class');
    done_testing();
};

subtest 'generate_message method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.ai.generativelanguage.v1beta.DiscussService', 'Correct service path');
        is($args->{method}, 'GenerateMessage', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Ai::Generativelanguage::V1beta::DiscussService::GenerateMessageRequest', 'Request object');
        
        my $response = 'Google::Ai::Generativelanguage::V1beta::DiscussService::GenerateMessageResponse'->new();
        return $response;
    };
    
    my $res = $client->generate_message();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Ai::Generativelanguage::V1beta::DiscussService::GenerateMessageResponse', 'Response object class');
    done_testing();
};

subtest 'count_message_tokens method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.ai.generativelanguage.v1beta.DiscussService', 'Correct service path');
        is($args->{method}, 'CountMessageTokens', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Ai::Generativelanguage::V1beta::DiscussService::CountMessageTokensRequest', 'Request object');
        
        my $response = 'Google::Ai::Generativelanguage::V1beta::DiscussService::CountMessageTokensResponse'->new();
        return $response;
    };
    
    my $res = $client->count_message_tokens();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Ai::Generativelanguage::V1beta::DiscussService::CountMessageTokensResponse', 'Response object class');
    done_testing();
};

subtest 'create_file method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.ai.generativelanguage.v1beta.FileService', 'Correct service path');
        is($args->{method}, 'CreateFile', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Ai::Generativelanguage::V1beta::FileService::CreateFileRequest', 'Request object');
        
        my $response = 'Google::Ai::Generativelanguage::V1beta::FileService::CreateFileResponse'->new();
        return $response;
    };
    
    my $res = $client->create_file();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Ai::Generativelanguage::V1beta::FileService::CreateFileResponse', 'Response object class');
    done_testing();
};

subtest 'list_files method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.ai.generativelanguage.v1beta.FileService', 'Correct service path');
        is($args->{method}, 'ListFiles', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Ai::Generativelanguage::V1beta::FileService::ListFilesRequest', 'Request object');
        
        my $response = 'Google::Ai::Generativelanguage::V1beta::FileService::ListFilesResponse'->new();
        return $response;
    };
    
    my $res = $client->list_files();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Ai::Generativelanguage::V1beta::FileService::ListFilesResponse', 'Response object class');
    done_testing();
};

subtest 'get_file method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.ai.generativelanguage.v1beta.FileService', 'Correct service path');
        is($args->{method}, 'GetFile', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Ai::Generativelanguage::V1beta::FileService::GetFileRequest', 'Request object');
        
        my $response = 'Google::Ai::Generativelanguage::V1beta::File::File'->new();
        return $response;
    };
    
    my $res = $client->get_file();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Ai::Generativelanguage::V1beta::File::File', 'Response object class');
    done_testing();
};

subtest 'delete_file method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.ai.generativelanguage.v1beta.FileService', 'Correct service path');
        is($args->{method}, 'DeleteFile', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Ai::Generativelanguage::V1beta::FileService::DeleteFileRequest', 'Request object');
        
        my $response = 'Google::Protobuf::Empty::Empty'->new();
        return $response;
    };
    
    my $res = $client->delete_file();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Protobuf::Empty::Empty', 'Response object class');
    done_testing();
};

subtest 'download_file method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.ai.generativelanguage.v1beta.FileService', 'Correct service path');
        is($args->{method}, 'DownloadFile', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Ai::Generativelanguage::V1beta::FileService::DownloadFileRequest', 'Request object');
        
        my $response = 'Google::Ai::Generativelanguage::V1beta::FileService::DownloadFileResponse'->new();
        return $response;
    };
    
    my $res = $client->download_file();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Ai::Generativelanguage::V1beta::FileService::DownloadFileResponse', 'Response object class');
    done_testing();
};

subtest 'generate_content method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.ai.generativelanguage.v1beta.GenerativeService', 'Correct service path');
        is($args->{method}, 'GenerateContent', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Ai::Generativelanguage::V1beta::GenerativeService::GenerateContentRequest', 'Request object');
        
        my $response = 'Google::Ai::Generativelanguage::V1beta::GenerativeService::GenerateContentResponse'->new();
        return $response;
    };
    
    my $res = $client->generate_content();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Ai::Generativelanguage::V1beta::GenerativeService::GenerateContentResponse', 'Response object class');
    done_testing();
};

subtest 'generate_answer method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.ai.generativelanguage.v1beta.GenerativeService', 'Correct service path');
        is($args->{method}, 'GenerateAnswer', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Ai::Generativelanguage::V1beta::GenerativeService::GenerateAnswerRequest', 'Request object');
        
        my $response = 'Google::Ai::Generativelanguage::V1beta::GenerativeService::GenerateAnswerResponse'->new();
        return $response;
    };
    
    my $res = $client->generate_answer();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Ai::Generativelanguage::V1beta::GenerativeService::GenerateAnswerResponse', 'Response object class');
    done_testing();
};

subtest 'stream_generate_content method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.ai.generativelanguage.v1beta.GenerativeService', 'Correct service path');
        is($args->{method}, 'StreamGenerateContent', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Ai::Generativelanguage::V1beta::GenerativeService::GenerateContentRequest', 'Request object');
        
        my $response = 'Google::Ai::Generativelanguage::V1beta::GenerativeService::GenerateContentResponse'->new();
        return $response;
    };
    
    my $res = $client->stream_generate_content();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Ai::Generativelanguage::V1beta::GenerativeService::GenerateContentResponse', 'Response object class');
    done_testing();
};

subtest 'embed_content method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.ai.generativelanguage.v1beta.GenerativeService', 'Correct service path');
        is($args->{method}, 'EmbedContent', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Ai::Generativelanguage::V1beta::GenerativeService::EmbedContentRequest', 'Request object');
        
        my $response = 'Google::Ai::Generativelanguage::V1beta::GenerativeService::EmbedContentResponse'->new();
        return $response;
    };
    
    my $res = $client->embed_content();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Ai::Generativelanguage::V1beta::GenerativeService::EmbedContentResponse', 'Response object class');
    done_testing();
};

subtest 'batch_embed_contents method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.ai.generativelanguage.v1beta.GenerativeService', 'Correct service path');
        is($args->{method}, 'BatchEmbedContents', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Ai::Generativelanguage::V1beta::GenerativeService::BatchEmbedContentsRequest', 'Request object');
        
        my $response = 'Google::Ai::Generativelanguage::V1beta::GenerativeService::BatchEmbedContentsResponse'->new();
        return $response;
    };
    
    my $res = $client->batch_embed_contents();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Ai::Generativelanguage::V1beta::GenerativeService::BatchEmbedContentsResponse', 'Response object class');
    done_testing();
};

subtest 'count_tokens method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.ai.generativelanguage.v1beta.GenerativeService', 'Correct service path');
        is($args->{method}, 'CountTokens', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Ai::Generativelanguage::V1beta::GenerativeService::CountTokensRequest', 'Request object');
        
        my $response = 'Google::Ai::Generativelanguage::V1beta::GenerativeService::CountTokensResponse'->new();
        return $response;
    };
    
    my $res = $client->count_tokens();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Ai::Generativelanguage::V1beta::GenerativeService::CountTokensResponse', 'Response object class');
    done_testing();
};

subtest 'bidi_generate_content method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.ai.generativelanguage.v1beta.GenerativeService', 'Correct service path');
        is($args->{method}, 'BidiGenerateContent', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Ai::Generativelanguage::V1beta::GenerativeService::BidiGenerateContentClientMessage', 'Request object');
        
        my $response = 'Google::Ai::Generativelanguage::V1beta::GenerativeService::BidiGenerateContentServerMessage'->new();
        return $response;
    };
    
    my $res = $client->bidi_generate_content();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Ai::Generativelanguage::V1beta::GenerativeService::BidiGenerateContentServerMessage', 'Response object class');
    done_testing();
};

subtest 'get_model method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.ai.generativelanguage.v1beta.ModelService', 'Correct service path');
        is($args->{method}, 'GetModel', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Ai::Generativelanguage::V1beta::ModelService::GetModelRequest', 'Request object');
        
        my $response = 'Google::Ai::Generativelanguage::V1beta::Model::Model'->new();
        return $response;
    };
    
    my $res = $client->get_model();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Ai::Generativelanguage::V1beta::Model::Model', 'Response object class');
    done_testing();
};

subtest 'list_models method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.ai.generativelanguage.v1beta.ModelService', 'Correct service path');
        is($args->{method}, 'ListModels', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Ai::Generativelanguage::V1beta::ModelService::ListModelsRequest', 'Request object');
        
        my $response = 'Google::Ai::Generativelanguage::V1beta::ModelService::ListModelsResponse'->new();
        return $response;
    };
    
    my $res = $client->list_models();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Ai::Generativelanguage::V1beta::ModelService::ListModelsResponse', 'Response object class');
    done_testing();
};

subtest 'get_tuned_model method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.ai.generativelanguage.v1beta.ModelService', 'Correct service path');
        is($args->{method}, 'GetTunedModel', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Ai::Generativelanguage::V1beta::ModelService::GetTunedModelRequest', 'Request object');
        
        my $response = 'Google::Ai::Generativelanguage::V1beta::TunedModel::TunedModel'->new();
        return $response;
    };
    
    my $res = $client->get_tuned_model();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Ai::Generativelanguage::V1beta::TunedModel::TunedModel', 'Response object class');
    done_testing();
};

subtest 'list_tuned_models method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.ai.generativelanguage.v1beta.ModelService', 'Correct service path');
        is($args->{method}, 'ListTunedModels', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Ai::Generativelanguage::V1beta::ModelService::ListTunedModelsRequest', 'Request object');
        
        my $response = 'Google::Ai::Generativelanguage::V1beta::ModelService::ListTunedModelsResponse'->new();
        return $response;
    };
    
    my $res = $client->list_tuned_models();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Ai::Generativelanguage::V1beta::ModelService::ListTunedModelsResponse', 'Response object class');
    done_testing();
};

subtest 'create_tuned_model method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.ai.generativelanguage.v1beta.ModelService', 'Correct service path');
        is($args->{method}, 'CreateTunedModel', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Ai::Generativelanguage::V1beta::ModelService::CreateTunedModelRequest', 'Request object');
        
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
        is($args->{service}, 'google.ai.generativelanguage.v1beta.ModelService', 'Correct service path');
        is($args->{method}, 'UpdateTunedModel', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Ai::Generativelanguage::V1beta::ModelService::UpdateTunedModelRequest', 'Request object');
        
        my $response = 'Google::Ai::Generativelanguage::V1beta::TunedModel::TunedModel'->new();
        return $response;
    };
    
    my $res = $client->update_tuned_model();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Ai::Generativelanguage::V1beta::TunedModel::TunedModel', 'Response object class');
    done_testing();
};

subtest 'delete_tuned_model method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.ai.generativelanguage.v1beta.ModelService', 'Correct service path');
        is($args->{method}, 'DeleteTunedModel', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Ai::Generativelanguage::V1beta::ModelService::DeleteTunedModelRequest', 'Request object');
        
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
        is($args->{service}, 'google.ai.generativelanguage.v1beta.PermissionService', 'Correct service path');
        is($args->{method}, 'CreatePermission', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Ai::Generativelanguage::V1beta::PermissionService::CreatePermissionRequest', 'Request object');
        
        my $response = 'Google::Ai::Generativelanguage::V1beta::Permission::Permission'->new();
        return $response;
    };
    
    my $res = $client->create_permission();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Ai::Generativelanguage::V1beta::Permission::Permission', 'Response object class');
    done_testing();
};

subtest 'transfer_ownership method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.ai.generativelanguage.v1beta.PermissionService', 'Correct service path');
        is($args->{method}, 'TransferOwnership', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Ai::Generativelanguage::V1beta::PermissionService::TransferOwnershipRequest', 'Request object');
        
        my $response = 'Google::Ai::Generativelanguage::V1beta::PermissionService::TransferOwnershipResponse'->new();
        return $response;
    };
    
    my $res = $client->transfer_ownership();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Ai::Generativelanguage::V1beta::PermissionService::TransferOwnershipResponse', 'Response object class');
    done_testing();
};

subtest 'predict method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.ai.generativelanguage.v1beta.PredictionService', 'Correct service path');
        is($args->{method}, 'Predict', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Ai::Generativelanguage::V1beta::PredictionService::PredictRequest', 'Request object');
        
        my $response = 'Google::Ai::Generativelanguage::V1beta::PredictionService::PredictResponse'->new();
        return $response;
    };
    
    my $res = $client->predict();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Ai::Generativelanguage::V1beta::PredictionService::PredictResponse', 'Response object class');
    done_testing();
};

subtest 'predict_long_running method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.ai.generativelanguage.v1beta.PredictionService', 'Correct service path');
        is($args->{method}, 'PredictLongRunning', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Ai::Generativelanguage::V1beta::PredictionService::PredictLongRunningRequest', 'Request object');
        
        my $response = 'Google::Longrunning::Operations::Operation'->new();
        return $response;
    };
    
    my $res = $client->predict_long_running();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Longrunning::Operations::Operation', 'Response object class');
    done_testing();
};

subtest 'create_corpus method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.ai.generativelanguage.v1beta.RetrieverService', 'Correct service path');
        is($args->{method}, 'CreateCorpus', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Ai::Generativelanguage::V1beta::RetrieverService::CreateCorpusRequest', 'Request object');
        
        my $response = 'Google::Ai::Generativelanguage::V1beta::Retriever::Corpus'->new();
        return $response;
    };
    
    my $res = $client->create_corpus();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Ai::Generativelanguage::V1beta::Retriever::Corpus', 'Response object class');
    done_testing();
};

subtest 'get_corpus method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.ai.generativelanguage.v1beta.RetrieverService', 'Correct service path');
        is($args->{method}, 'GetCorpus', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Ai::Generativelanguage::V1beta::RetrieverService::GetCorpusRequest', 'Request object');
        
        my $response = 'Google::Ai::Generativelanguage::V1beta::Retriever::Corpus'->new();
        return $response;
    };
    
    my $res = $client->get_corpus();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Ai::Generativelanguage::V1beta::Retriever::Corpus', 'Response object class');
    done_testing();
};

subtest 'generate_text method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.ai.generativelanguage.v1beta.TextService', 'Correct service path');
        is($args->{method}, 'GenerateText', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Ai::Generativelanguage::V1beta::TextService::GenerateTextRequest', 'Request object');
        
        my $response = 'Google::Ai::Generativelanguage::V1beta::TextService::GenerateTextResponse'->new();
        return $response;
    };
    
    my $res = $client->generate_text();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Ai::Generativelanguage::V1beta::TextService::GenerateTextResponse', 'Response object class');
    done_testing();
};

subtest 'embed_text method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.ai.generativelanguage.v1beta.TextService', 'Correct service path');
        is($args->{method}, 'EmbedText', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Ai::Generativelanguage::V1beta::TextService::EmbedTextRequest', 'Request object');
        
        my $response = 'Google::Ai::Generativelanguage::V1beta::TextService::EmbedTextResponse'->new();
        return $response;
    };
    
    my $res = $client->embed_text();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Ai::Generativelanguage::V1beta::TextService::EmbedTextResponse', 'Response object class');
    done_testing();
};

subtest 'batch_embed_text method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.ai.generativelanguage.v1beta.TextService', 'Correct service path');
        is($args->{method}, 'BatchEmbedText', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Ai::Generativelanguage::V1beta::TextService::BatchEmbedTextRequest', 'Request object');
        
        my $response = 'Google::Ai::Generativelanguage::V1beta::TextService::BatchEmbedTextResponse'->new();
        return $response;
    };
    
    my $res = $client->batch_embed_text();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Ai::Generativelanguage::V1beta::TextService::BatchEmbedTextResponse', 'Response object class');
    done_testing();
};

subtest 'count_text_tokens method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.ai.generativelanguage.v1beta.TextService', 'Correct service path');
        is($args->{method}, 'CountTextTokens', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Ai::Generativelanguage::V1beta::TextService::CountTextTokensRequest', 'Request object');
        
        my $response = 'Google::Ai::Generativelanguage::V1beta::TextService::CountTextTokensResponse'->new();
        return $response;
    };
    
    my $res = $client->count_text_tokens();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Ai::Generativelanguage::V1beta::TextService::CountTextTokensResponse', 'Response object class');
    done_testing();
};

done_testing();
