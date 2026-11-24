package Google::Ai::Generativelanguage::V1alpha;

use strict;
use warnings;
use Moo;
use Google::gRPC::Client;
use Google::Cloud::REST::Client;
use Google::Auth;
use Carp qw(croak);

use Protobuf;
use Google::Api::Common;
use Google::Ai::Generativelanguage::V1alpha::Content;
use Google::Ai::Generativelanguage::V1alpha::Citation;
use Google::Ai::Generativelanguage::V1alpha::Safety;
use Google::Ai::Generativelanguage::V1alpha::Permission;
use Google::Ai::Generativelanguage::V1alpha::Model;
use Google::Ai::Generativelanguage::V1alpha::Retriever;
use Google::Ai::Generativelanguage::V1alpha::TunedModel;
use Google::Ai::Generativelanguage::V1alpha::File;
use Google::Ai::Generativelanguage::V1alpha::PredictionService;
use Google::Ai::Generativelanguage::V1alpha::CachedContent;
use Google::Ai::Generativelanguage::V1alpha::DiscussService;
use Google::Ai::Generativelanguage::V1alpha::TextService;
use Google::Ai::Generativelanguage::V1alpha::PermissionService;
use Google::Ai::Generativelanguage::V1alpha::RetrieverService;
use Google::Ai::Generativelanguage::V1alpha::GenerativeService;
use Google::Ai::Generativelanguage::V1alpha::ModelService;
use Google::Ai::Generativelanguage::V1alpha::FileService;
use Google::Ai::Generativelanguage::V1alpha::CacheService;

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

    my $target = 'generativelanguage.googleapis.com:443';
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

sub list_cached_contents {
    my ($self, %params) = @_;

    my $request_class = 'Google::Ai::Generativelanguage::V1alpha::CacheService::ListCachedContentsRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Ai::Generativelanguage::V1alpha::CacheService::ListCachedContentsResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.ai.generativelanguage.v1alpha.CacheService/ListCachedContents',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.ai.generativelanguage.v1alpha.CacheService',
        method         => 'ListCachedContents',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub create_cached_content {
    my ($self, %params) = @_;

    my $request_class = 'Google::Ai::Generativelanguage::V1alpha::CacheService::CreateCachedContentRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Ai::Generativelanguage::V1alpha::CachedContent::CachedContent';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.ai.generativelanguage.v1alpha.CacheService/CreateCachedContent',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.ai.generativelanguage.v1alpha.CacheService',
        method         => 'CreateCachedContent',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub get_cached_content {
    my ($self, %params) = @_;

    my $request_class = 'Google::Ai::Generativelanguage::V1alpha::CacheService::GetCachedContentRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Ai::Generativelanguage::V1alpha::CachedContent::CachedContent';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.ai.generativelanguage.v1alpha.CacheService/GetCachedContent',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.ai.generativelanguage.v1alpha.CacheService',
        method         => 'GetCachedContent',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub update_cached_content {
    my ($self, %params) = @_;

    my $request_class = 'Google::Ai::Generativelanguage::V1alpha::CacheService::UpdateCachedContentRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Ai::Generativelanguage::V1alpha::CachedContent::CachedContent';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.ai.generativelanguage.v1alpha.CacheService/UpdateCachedContent',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.ai.generativelanguage.v1alpha.CacheService',
        method         => 'UpdateCachedContent',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub delete_cached_content {
    my ($self, %params) = @_;

    my $request_class = 'Google::Ai::Generativelanguage::V1alpha::CacheService::DeleteCachedContentRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Protobuf::Empty::Empty';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.ai.generativelanguage.v1alpha.CacheService/DeleteCachedContent',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.ai.generativelanguage.v1alpha.CacheService',
        method         => 'DeleteCachedContent',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub generate_message {
    my ($self, %params) = @_;

    my $request_class = 'Google::Ai::Generativelanguage::V1alpha::DiscussService::GenerateMessageRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Ai::Generativelanguage::V1alpha::DiscussService::GenerateMessageResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.ai.generativelanguage.v1alpha.DiscussService/GenerateMessage',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.ai.generativelanguage.v1alpha.DiscussService',
        method         => 'GenerateMessage',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub count_message_tokens {
    my ($self, %params) = @_;

    my $request_class = 'Google::Ai::Generativelanguage::V1alpha::DiscussService::CountMessageTokensRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Ai::Generativelanguage::V1alpha::DiscussService::CountMessageTokensResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.ai.generativelanguage.v1alpha.DiscussService/CountMessageTokens',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.ai.generativelanguage.v1alpha.DiscussService',
        method         => 'CountMessageTokens',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub create_file {
    my ($self, %params) = @_;

    my $request_class = 'Google::Ai::Generativelanguage::V1alpha::FileService::CreateFileRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Ai::Generativelanguage::V1alpha::FileService::CreateFileResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.ai.generativelanguage.v1alpha.FileService/CreateFile',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.ai.generativelanguage.v1alpha.FileService',
        method         => 'CreateFile',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub list_files {
    my ($self, %params) = @_;

    my $request_class = 'Google::Ai::Generativelanguage::V1alpha::FileService::ListFilesRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Ai::Generativelanguage::V1alpha::FileService::ListFilesResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.ai.generativelanguage.v1alpha.FileService/ListFiles',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.ai.generativelanguage.v1alpha.FileService',
        method         => 'ListFiles',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub get_file {
    my ($self, %params) = @_;

    my $request_class = 'Google::Ai::Generativelanguage::V1alpha::FileService::GetFileRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Ai::Generativelanguage::V1alpha::File::File';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.ai.generativelanguage.v1alpha.FileService/GetFile',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.ai.generativelanguage.v1alpha.FileService',
        method         => 'GetFile',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub delete_file {
    my ($self, %params) = @_;

    my $request_class = 'Google::Ai::Generativelanguage::V1alpha::FileService::DeleteFileRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Protobuf::Empty::Empty';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.ai.generativelanguage.v1alpha.FileService/DeleteFile',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.ai.generativelanguage.v1alpha.FileService',
        method         => 'DeleteFile',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub generate_content {
    my ($self, %params) = @_;

    my $request_class = 'Google::Ai::Generativelanguage::V1alpha::GenerativeService::GenerateContentRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Ai::Generativelanguage::V1alpha::GenerativeService::GenerateContentResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.ai.generativelanguage.v1alpha.GenerativeService/GenerateContent',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.ai.generativelanguage.v1alpha.GenerativeService',
        method         => 'GenerateContent',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub generate_answer {
    my ($self, %params) = @_;

    my $request_class = 'Google::Ai::Generativelanguage::V1alpha::GenerativeService::GenerateAnswerRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Ai::Generativelanguage::V1alpha::GenerativeService::GenerateAnswerResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.ai.generativelanguage.v1alpha.GenerativeService/GenerateAnswer',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.ai.generativelanguage.v1alpha.GenerativeService',
        method         => 'GenerateAnswer',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub stream_generate_content {
    my ($self, %params) = @_;

    my $request_class = 'Google::Ai::Generativelanguage::V1alpha::GenerativeService::GenerateContentRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Ai::Generativelanguage::V1alpha::GenerativeService::GenerateContentResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.ai.generativelanguage.v1alpha.GenerativeService/StreamGenerateContent',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.ai.generativelanguage.v1alpha.GenerativeService',
        method         => 'StreamGenerateContent',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub embed_content {
    my ($self, %params) = @_;

    my $request_class = 'Google::Ai::Generativelanguage::V1alpha::GenerativeService::EmbedContentRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Ai::Generativelanguage::V1alpha::GenerativeService::EmbedContentResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.ai.generativelanguage.v1alpha.GenerativeService/EmbedContent',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.ai.generativelanguage.v1alpha.GenerativeService',
        method         => 'EmbedContent',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub batch_embed_contents {
    my ($self, %params) = @_;

    my $request_class = 'Google::Ai::Generativelanguage::V1alpha::GenerativeService::BatchEmbedContentsRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Ai::Generativelanguage::V1alpha::GenerativeService::BatchEmbedContentsResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.ai.generativelanguage.v1alpha.GenerativeService/BatchEmbedContents',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.ai.generativelanguage.v1alpha.GenerativeService',
        method         => 'BatchEmbedContents',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub count_tokens {
    my ($self, %params) = @_;

    my $request_class = 'Google::Ai::Generativelanguage::V1alpha::GenerativeService::CountTokensRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Ai::Generativelanguage::V1alpha::GenerativeService::CountTokensResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.ai.generativelanguage.v1alpha.GenerativeService/CountTokens',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.ai.generativelanguage.v1alpha.GenerativeService',
        method         => 'CountTokens',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub bidi_generate_content {
    my ($self, %params) = @_;

    my $request_class = 'Google::Ai::Generativelanguage::V1alpha::GenerativeService::BidiGenerateContentClientMessage';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Ai::Generativelanguage::V1alpha::GenerativeService::BidiGenerateContentServerMessage';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.ai.generativelanguage.v1alpha.GenerativeService/BidiGenerateContent',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.ai.generativelanguage.v1alpha.GenerativeService',
        method         => 'BidiGenerateContent',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub get_model {
    my ($self, %params) = @_;

    my $request_class = 'Google::Ai::Generativelanguage::V1alpha::ModelService::GetModelRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Ai::Generativelanguage::V1alpha::Model::Model';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.ai.generativelanguage.v1alpha.ModelService/GetModel',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.ai.generativelanguage.v1alpha.ModelService',
        method         => 'GetModel',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub list_models {
    my ($self, %params) = @_;

    my $request_class = 'Google::Ai::Generativelanguage::V1alpha::ModelService::ListModelsRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Ai::Generativelanguage::V1alpha::ModelService::ListModelsResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.ai.generativelanguage.v1alpha.ModelService/ListModels',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.ai.generativelanguage.v1alpha.ModelService',
        method         => 'ListModels',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub get_tuned_model {
    my ($self, %params) = @_;

    my $request_class = 'Google::Ai::Generativelanguage::V1alpha::ModelService::GetTunedModelRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Ai::Generativelanguage::V1alpha::TunedModel::TunedModel';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.ai.generativelanguage.v1alpha.ModelService/GetTunedModel',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.ai.generativelanguage.v1alpha.ModelService',
        method         => 'GetTunedModel',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub list_tuned_models {
    my ($self, %params) = @_;

    my $request_class = 'Google::Ai::Generativelanguage::V1alpha::ModelService::ListTunedModelsRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Ai::Generativelanguage::V1alpha::ModelService::ListTunedModelsResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.ai.generativelanguage.v1alpha.ModelService/ListTunedModels',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.ai.generativelanguage.v1alpha.ModelService',
        method         => 'ListTunedModels',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub create_tuned_model {
    my ($self, %params) = @_;

    my $request_class = 'Google::Ai::Generativelanguage::V1alpha::ModelService::CreateTunedModelRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Longrunning::Operations::Operation';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.ai.generativelanguage.v1alpha.ModelService/CreateTunedModel',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.ai.generativelanguage.v1alpha.ModelService',
        method         => 'CreateTunedModel',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub update_tuned_model {
    my ($self, %params) = @_;

    my $request_class = 'Google::Ai::Generativelanguage::V1alpha::ModelService::UpdateTunedModelRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Ai::Generativelanguage::V1alpha::TunedModel::TunedModel';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.ai.generativelanguage.v1alpha.ModelService/UpdateTunedModel',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.ai.generativelanguage.v1alpha.ModelService',
        method         => 'UpdateTunedModel',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub delete_tuned_model {
    my ($self, %params) = @_;

    my $request_class = 'Google::Ai::Generativelanguage::V1alpha::ModelService::DeleteTunedModelRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Protobuf::Empty::Empty';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.ai.generativelanguage.v1alpha.ModelService/DeleteTunedModel',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.ai.generativelanguage.v1alpha.ModelService',
        method         => 'DeleteTunedModel',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub create_permission {
    my ($self, %params) = @_;

    my $request_class = 'Google::Ai::Generativelanguage::V1alpha::PermissionService::CreatePermissionRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Ai::Generativelanguage::V1alpha::Permission::Permission';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.ai.generativelanguage.v1alpha.PermissionService/CreatePermission',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.ai.generativelanguage.v1alpha.PermissionService',
        method         => 'CreatePermission',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub transfer_ownership {
    my ($self, %params) = @_;

    my $request_class = 'Google::Ai::Generativelanguage::V1alpha::PermissionService::TransferOwnershipRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Ai::Generativelanguage::V1alpha::PermissionService::TransferOwnershipResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.ai.generativelanguage.v1alpha.PermissionService/TransferOwnership',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.ai.generativelanguage.v1alpha.PermissionService',
        method         => 'TransferOwnership',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub predict {
    my ($self, %params) = @_;

    my $request_class = 'Google::Ai::Generativelanguage::V1alpha::PredictionService::PredictRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Ai::Generativelanguage::V1alpha::PredictionService::PredictResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.ai.generativelanguage.v1alpha.PredictionService/Predict',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.ai.generativelanguage.v1alpha.PredictionService',
        method         => 'Predict',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub create_corpus {
    my ($self, %params) = @_;

    my $request_class = 'Google::Ai::Generativelanguage::V1alpha::RetrieverService::CreateCorpusRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Ai::Generativelanguage::V1alpha::Retriever::Corpus';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.ai.generativelanguage.v1alpha.RetrieverService/CreateCorpus',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.ai.generativelanguage.v1alpha.RetrieverService',
        method         => 'CreateCorpus',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub get_corpus {
    my ($self, %params) = @_;

    my $request_class = 'Google::Ai::Generativelanguage::V1alpha::RetrieverService::GetCorpusRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Ai::Generativelanguage::V1alpha::Retriever::Corpus';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.ai.generativelanguage.v1alpha.RetrieverService/GetCorpus',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.ai.generativelanguage.v1alpha.RetrieverService',
        method         => 'GetCorpus',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub generate_text {
    my ($self, %params) = @_;

    my $request_class = 'Google::Ai::Generativelanguage::V1alpha::TextService::GenerateTextRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Ai::Generativelanguage::V1alpha::TextService::GenerateTextResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.ai.generativelanguage.v1alpha.TextService/GenerateText',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.ai.generativelanguage.v1alpha.TextService',
        method         => 'GenerateText',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub embed_text {
    my ($self, %params) = @_;

    my $request_class = 'Google::Ai::Generativelanguage::V1alpha::TextService::EmbedTextRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Ai::Generativelanguage::V1alpha::TextService::EmbedTextResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.ai.generativelanguage.v1alpha.TextService/EmbedText',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.ai.generativelanguage.v1alpha.TextService',
        method         => 'EmbedText',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub batch_embed_text {
    my ($self, %params) = @_;

    my $request_class = 'Google::Ai::Generativelanguage::V1alpha::TextService::BatchEmbedTextRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Ai::Generativelanguage::V1alpha::TextService::BatchEmbedTextResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.ai.generativelanguage.v1alpha.TextService/BatchEmbedText',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.ai.generativelanguage.v1alpha.TextService',
        method         => 'BatchEmbedText',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub count_text_tokens {
    my ($self, %params) = @_;

    my $request_class = 'Google::Ai::Generativelanguage::V1alpha::TextService::CountTextTokensRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Ai::Generativelanguage::V1alpha::TextService::CountTextTokensResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.ai.generativelanguage.v1alpha.TextService/CountTextTokens',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.ai.generativelanguage.v1alpha.TextService',
        method         => 'CountTextTokens',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}
1; # End of Google::Ai::Generativelanguage::V1alpha

__END__

=head1 NAME

Google::Ai::Generativelanguage::V1alpha - Client library for Google Cloud Services

=head1 SYNOPSIS

    use Google::Ai::Generativelanguage::V1alpha;
    use Google::Auth;

    my $auth = Google::Auth->default();

    # 1. High-performance gRPC Transport (Default)
    my $grpc_client = Google::Ai::Generativelanguage::V1alpha->new(
        credentials => $auth,
        transport   => 'grpc', # Optional: 'grpc' is default
    );

    # 2. HTTP/REST Transport
    my $rest_client = Google::Ai::Generativelanguage::V1alpha->new(
        credentials => $auth,
        transport   => 'rest',
    );

    # Execute service methods
    my $res = $grpc_client->some_method( %params );

=head1 DESCRIPTION

C<Google::Ai::Generativelanguage::V1alpha> is an auto-generated client library for Google Cloud Services.

It provides a unified client interface supporting both high-performance HTTP/2 gRPC and HTTP/REST transports, with automatic Google Cloud Application Default Credentials (ADC) resolution and typed Protocol Buffers message handling.

=head1 SOURCE

Generated from the following Protocol Buffers schemas:

=over 4

=item * C<googleapis/google/ai/generativelanguage/v1alpha/cache_service.proto>

=item * C<googleapis/google/ai/generativelanguage/v1alpha/cached_content.proto>

=item * C<googleapis/google/ai/generativelanguage/v1alpha/citation.proto>

=item * C<googleapis/google/ai/generativelanguage/v1alpha/content.proto>

=item * C<googleapis/google/ai/generativelanguage/v1alpha/discuss_service.proto>

=item * C<googleapis/google/ai/generativelanguage/v1alpha/file.proto>

=item * C<googleapis/google/ai/generativelanguage/v1alpha/file_service.proto>

=item * C<googleapis/google/ai/generativelanguage/v1alpha/generative_service.proto>

=item * C<googleapis/google/ai/generativelanguage/v1alpha/model.proto>

=item * C<googleapis/google/ai/generativelanguage/v1alpha/model_service.proto>

=item * C<googleapis/google/ai/generativelanguage/v1alpha/permission.proto>

=item * C<googleapis/google/ai/generativelanguage/v1alpha/permission_service.proto>

=item * C<googleapis/google/ai/generativelanguage/v1alpha/prediction_service.proto>

=item * C<googleapis/google/ai/generativelanguage/v1alpha/retriever.proto>

=item * C<googleapis/google/ai/generativelanguage/v1alpha/retriever_service.proto>

=item * C<googleapis/google/ai/generativelanguage/v1alpha/safety.proto>

=item * C<googleapis/google/ai/generativelanguage/v1alpha/text_service.proto>

=item * C<googleapis/google/ai/generativelanguage/v1alpha/tuned_model.proto>



=back

=head1 CONSTRUCTOR

=head2 new

    my $client = Google::Ai::Generativelanguage::V1alpha->new(
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

=item * B<list_cached_contents>

    my $response = $client->list_cached_contents(
        page_size                => $page_size,
        page_token               => $page_token,
    );

Calls the RPC method C<ListCachedContents> on C<google.ai.generativelanguage.v1alpha.CacheService>.

Request: L<Google::Ai::Generativelanguage::V1alpha::CacheService::ListCachedContentsRequest>

Returns: L<Google::Ai::Generativelanguage::V1alpha::CacheService::ListCachedContentsResponse>

Parameters:

=over 4

=item * C<page_size> - C<int32>

=item * C<page_token> - C<string>

=back

=item * B<create_cached_content>

    my $response = $client->create_cached_content(
        cached_content           => $cached_content,
    );

Calls the RPC method C<CreateCachedContent> on C<google.ai.generativelanguage.v1alpha.CacheService>.

Request: L<Google::Ai::Generativelanguage::V1alpha::CacheService::CreateCachedContentRequest>

Returns: L<Google::Ai::Generativelanguage::V1alpha::CachedContent::CachedContent>

Parameters:

=over 4

=item * C<cached_content> - L<Google::Ai::Generativelanguage::V1alpha::CachedContent::CachedContent>

=back

=item * B<get_cached_content>

    my $response = $client->get_cached_content(
        name                     => $name,
    );

Calls the RPC method C<GetCachedContent> on C<google.ai.generativelanguage.v1alpha.CacheService>.

Request: L<Google::Ai::Generativelanguage::V1alpha::CacheService::GetCachedContentRequest>

Returns: L<Google::Ai::Generativelanguage::V1alpha::CachedContent::CachedContent>

Parameters:

=over 4

=item * C<name> - C<string>

=back

=item * B<update_cached_content>

    my $response = $client->update_cached_content(
        cached_content           => $cached_content,
        update_mask              => $update_mask,
    );

Calls the RPC method C<UpdateCachedContent> on C<google.ai.generativelanguage.v1alpha.CacheService>.

Request: L<Google::Ai::Generativelanguage::V1alpha::CacheService::UpdateCachedContentRequest>

Returns: L<Google::Ai::Generativelanguage::V1alpha::CachedContent::CachedContent>

Parameters:

=over 4

=item * C<cached_content> - L<Google::Ai::Generativelanguage::V1alpha::CachedContent::CachedContent>

=item * C<update_mask> - L<Google::Protobuf::FieldMask::FieldMask>

=back

=item * B<delete_cached_content>

    my $response = $client->delete_cached_content(
        name                     => $name,
    );

Calls the RPC method C<DeleteCachedContent> on C<google.ai.generativelanguage.v1alpha.CacheService>.

Request: L<Google::Ai::Generativelanguage::V1alpha::CacheService::DeleteCachedContentRequest>

Returns: L<Google::Protobuf::Empty::Empty>

Parameters:

=over 4

=item * C<name> - C<string>

=back

=item * B<generate_message>

    my $response = $client->generate_message(
        model                    => $model,
        prompt                   => $prompt,
        temperature              => $temperature,
        candidate_count          => $candidate_count,
        top_p                    => $top_p,
        top_k                    => $top_k,
    );

Calls the RPC method C<GenerateMessage> on C<google.ai.generativelanguage.v1alpha.DiscussService>.

Request: L<Google::Ai::Generativelanguage::V1alpha::DiscussService::GenerateMessageRequest>

Returns: L<Google::Ai::Generativelanguage::V1alpha::DiscussService::GenerateMessageResponse>

Parameters:

=over 4

=item * C<model> - C<string>

=item * C<prompt> - L<Google::Ai::Generativelanguage::V1alpha::DiscussService::MessagePrompt>

=item * C<temperature> - C<float>

=item * C<candidate_count> - C<int32>

=item * C<top_p> - C<float>

=item * C<top_k> - C<int32>

=back

=item * B<count_message_tokens>

    my $response = $client->count_message_tokens(
        model                    => $model,
        prompt                   => $prompt,
    );

Calls the RPC method C<CountMessageTokens> on C<google.ai.generativelanguage.v1alpha.DiscussService>.

Request: L<Google::Ai::Generativelanguage::V1alpha::DiscussService::CountMessageTokensRequest>

Returns: L<Google::Ai::Generativelanguage::V1alpha::DiscussService::CountMessageTokensResponse>

Parameters:

=over 4

=item * C<model> - C<string>

=item * C<prompt> - L<Google::Ai::Generativelanguage::V1alpha::DiscussService::MessagePrompt>

=back

=item * B<create_file>

    my $response = $client->create_file(
        file                     => $file,
    );

Calls the RPC method C<CreateFile> on C<google.ai.generativelanguage.v1alpha.FileService>.

Request: L<Google::Ai::Generativelanguage::V1alpha::FileService::CreateFileRequest>

Returns: L<Google::Ai::Generativelanguage::V1alpha::FileService::CreateFileResponse>

Parameters:

=over 4

=item * C<file> - L<Google::Ai::Generativelanguage::V1alpha::File::File>

=back

=item * B<list_files>

    my $response = $client->list_files(
        page_size                => $page_size,
        page_token               => $page_token,
    );

Calls the RPC method C<ListFiles> on C<google.ai.generativelanguage.v1alpha.FileService>.

Request: L<Google::Ai::Generativelanguage::V1alpha::FileService::ListFilesRequest>

Returns: L<Google::Ai::Generativelanguage::V1alpha::FileService::ListFilesResponse>

Parameters:

=over 4

=item * C<page_size> - C<int32>

=item * C<page_token> - C<string>

=back

=item * B<get_file>

    my $response = $client->get_file(
        name                     => $name,
    );

Calls the RPC method C<GetFile> on C<google.ai.generativelanguage.v1alpha.FileService>.

Request: L<Google::Ai::Generativelanguage::V1alpha::FileService::GetFileRequest>

Returns: L<Google::Ai::Generativelanguage::V1alpha::File::File>

Parameters:

=over 4

=item * C<name> - C<string>

=back

=item * B<delete_file>

    my $response = $client->delete_file(
        name                     => $name,
    );

Calls the RPC method C<DeleteFile> on C<google.ai.generativelanguage.v1alpha.FileService>.

Request: L<Google::Ai::Generativelanguage::V1alpha::FileService::DeleteFileRequest>

Returns: L<Google::Protobuf::Empty::Empty>

Parameters:

=over 4

=item * C<name> - C<string>

=back

=item * B<generate_content>

    my $response = $client->generate_content(
        model                    => $model,
        system_instruction       => $system_instruction,
        contents                 => [ ... ],
        tools                    => [ ... ],
        tool_config              => $tool_config,
        safety_settings          => [ ... ],
        generation_config        => $generation_config,
        cached_content           => $cached_content,
    );

Calls the RPC method C<GenerateContent> on C<google.ai.generativelanguage.v1alpha.GenerativeService>.

Request: L<Google::Ai::Generativelanguage::V1alpha::GenerativeService::GenerateContentRequest>

Returns: L<Google::Ai::Generativelanguage::V1alpha::GenerativeService::GenerateContentResponse>

Parameters:

=over 4

=item * C<model> - C<string>

=item * C<system_instruction> - L<Google::Ai::Generativelanguage::V1alpha::Content::Content>

=item * C<contents> - ArrayRef of L<Google::Ai::Generativelanguage::V1alpha::Content::Content>

=item * C<tools> - ArrayRef of L<Google::Ai::Generativelanguage::V1alpha::Content::Tool>

=item * C<tool_config> - L<Google::Ai::Generativelanguage::V1alpha::Content::ToolConfig>

=item * C<safety_settings> - ArrayRef of L<Google::Ai::Generativelanguage::V1alpha::Safety::SafetySetting>

=item * C<generation_config> - L<Google::Ai::Generativelanguage::V1alpha::GenerativeService::GenerationConfig>

=item * C<cached_content> - C<string>

=back

=item * B<generate_answer>

    my $response = $client->generate_answer(
        model                    => $model,
        contents                 => [ ... ],
        answer_style             => $answer_style,
        safety_settings          => [ ... ],
        temperature              => $temperature,
    );

Calls the RPC method C<GenerateAnswer> on C<google.ai.generativelanguage.v1alpha.GenerativeService>.

Request: L<Google::Ai::Generativelanguage::V1alpha::GenerativeService::GenerateAnswerRequest>

Returns: L<Google::Ai::Generativelanguage::V1alpha::GenerativeService::GenerateAnswerResponse>

Parameters:

=over 4

=item * C<model> - C<string>

=item * C<contents> - ArrayRef of L<Google::Ai::Generativelanguage::V1alpha::Content::Content>

=item * C<answer_style> - L<Google::Ai::Generativelanguage::V1alpha::GenerativeService::AnswerStyle>

=item * C<safety_settings> - ArrayRef of L<Google::Ai::Generativelanguage::V1alpha::Safety::SafetySetting>

=item * C<temperature> - C<float>

=back

=item * B<stream_generate_content>

    my $response = $client->stream_generate_content(
        model                    => $model,
        system_instruction       => $system_instruction,
        contents                 => [ ... ],
        tools                    => [ ... ],
        tool_config              => $tool_config,
        safety_settings          => [ ... ],
        generation_config        => $generation_config,
        cached_content           => $cached_content,
    );

Calls the RPC method C<StreamGenerateContent> on C<google.ai.generativelanguage.v1alpha.GenerativeService>.

Request: L<Google::Ai::Generativelanguage::V1alpha::GenerativeService::GenerateContentRequest>

Returns: L<Google::Ai::Generativelanguage::V1alpha::GenerativeService::GenerateContentResponse>

Parameters:

=over 4

=item * C<model> - C<string>

=item * C<system_instruction> - L<Google::Ai::Generativelanguage::V1alpha::Content::Content>

=item * C<contents> - ArrayRef of L<Google::Ai::Generativelanguage::V1alpha::Content::Content>

=item * C<tools> - ArrayRef of L<Google::Ai::Generativelanguage::V1alpha::Content::Tool>

=item * C<tool_config> - L<Google::Ai::Generativelanguage::V1alpha::Content::ToolConfig>

=item * C<safety_settings> - ArrayRef of L<Google::Ai::Generativelanguage::V1alpha::Safety::SafetySetting>

=item * C<generation_config> - L<Google::Ai::Generativelanguage::V1alpha::GenerativeService::GenerationConfig>

=item * C<cached_content> - C<string>

=back

=item * B<embed_content>

    my $response = $client->embed_content(
        model                    => $model,
        content                  => $content,
        task_type                => $task_type,
        title                    => $title,
        output_dimensionality    => $output_dimensionality,
    );

Calls the RPC method C<EmbedContent> on C<google.ai.generativelanguage.v1alpha.GenerativeService>.

Request: L<Google::Ai::Generativelanguage::V1alpha::GenerativeService::EmbedContentRequest>

Returns: L<Google::Ai::Generativelanguage::V1alpha::GenerativeService::EmbedContentResponse>

Parameters:

=over 4

=item * C<model> - C<string>

=item * C<content> - L<Google::Ai::Generativelanguage::V1alpha::Content::Content>

=item * C<task_type> - L<Google::Ai::Generativelanguage::V1alpha::GenerativeService::TaskType>

=item * C<title> - C<string>

=item * C<output_dimensionality> - C<int32>

=back

=item * B<batch_embed_contents>

    my $response = $client->batch_embed_contents(
        model                    => $model,
        requests                 => [ ... ],
    );

Calls the RPC method C<BatchEmbedContents> on C<google.ai.generativelanguage.v1alpha.GenerativeService>.

Request: L<Google::Ai::Generativelanguage::V1alpha::GenerativeService::BatchEmbedContentsRequest>

Returns: L<Google::Ai::Generativelanguage::V1alpha::GenerativeService::BatchEmbedContentsResponse>

Parameters:

=over 4

=item * C<model> - C<string>

=item * C<requests> - ArrayRef of L<Google::Ai::Generativelanguage::V1alpha::GenerativeService::EmbedContentRequest>

=back

=item * B<count_tokens>

    my $response = $client->count_tokens(
        model                    => $model,
        contents                 => [ ... ],
        generate_content_request => $generate_content_request,
    );

Calls the RPC method C<CountTokens> on C<google.ai.generativelanguage.v1alpha.GenerativeService>.

Request: L<Google::Ai::Generativelanguage::V1alpha::GenerativeService::CountTokensRequest>

Returns: L<Google::Ai::Generativelanguage::V1alpha::GenerativeService::CountTokensResponse>

Parameters:

=over 4

=item * C<model> - C<string>

=item * C<contents> - ArrayRef of L<Google::Ai::Generativelanguage::V1alpha::Content::Content>

=item * C<generate_content_request> - L<Google::Ai::Generativelanguage::V1alpha::GenerativeService::GenerateContentRequest>

=back

=item * B<bidi_generate_content>

    my $response = $client->bidi_generate_content();

Calls the RPC method C<BidiGenerateContent> on C<google.ai.generativelanguage.v1alpha.GenerativeService>.

Request: L<Google::Ai::Generativelanguage::V1alpha::GenerativeService::BidiGenerateContentClientMessage>

Returns: L<Google::Ai::Generativelanguage::V1alpha::GenerativeService::BidiGenerateContentServerMessage>

=item * B<get_model>

    my $response = $client->get_model(
        name                     => $name,
    );

Calls the RPC method C<GetModel> on C<google.ai.generativelanguage.v1alpha.ModelService>.

Request: L<Google::Ai::Generativelanguage::V1alpha::ModelService::GetModelRequest>

Returns: L<Google::Ai::Generativelanguage::V1alpha::Model::Model>

Parameters:

=over 4

=item * C<name> - C<string>

=back

=item * B<list_models>

    my $response = $client->list_models(
        page_size                => $page_size,
        page_token               => $page_token,
    );

Calls the RPC method C<ListModels> on C<google.ai.generativelanguage.v1alpha.ModelService>.

Request: L<Google::Ai::Generativelanguage::V1alpha::ModelService::ListModelsRequest>

Returns: L<Google::Ai::Generativelanguage::V1alpha::ModelService::ListModelsResponse>

Parameters:

=over 4

=item * C<page_size> - C<int32>

=item * C<page_token> - C<string>

=back

=item * B<get_tuned_model>

    my $response = $client->get_tuned_model(
        name                     => $name,
    );

Calls the RPC method C<GetTunedModel> on C<google.ai.generativelanguage.v1alpha.ModelService>.

Request: L<Google::Ai::Generativelanguage::V1alpha::ModelService::GetTunedModelRequest>

Returns: L<Google::Ai::Generativelanguage::V1alpha::TunedModel::TunedModel>

Parameters:

=over 4

=item * C<name> - C<string>

=back

=item * B<list_tuned_models>

    my $response = $client->list_tuned_models(
        page_size                => $page_size,
        page_token               => $page_token,
        filter                   => $filter,
    );

Calls the RPC method C<ListTunedModels> on C<google.ai.generativelanguage.v1alpha.ModelService>.

Request: L<Google::Ai::Generativelanguage::V1alpha::ModelService::ListTunedModelsRequest>

Returns: L<Google::Ai::Generativelanguage::V1alpha::ModelService::ListTunedModelsResponse>

Parameters:

=over 4

=item * C<page_size> - C<int32>

=item * C<page_token> - C<string>

=item * C<filter> - C<string>

=back

=item * B<create_tuned_model>

    my $response = $client->create_tuned_model(
        tuned_model_id           => $tuned_model_id,
        tuned_model              => $tuned_model,
    );

Calls the RPC method C<CreateTunedModel> on C<google.ai.generativelanguage.v1alpha.ModelService>.

Request: L<Google::Ai::Generativelanguage::V1alpha::ModelService::CreateTunedModelRequest>

Returns: L<Google::Longrunning::Operations::Operation>

Parameters:

=over 4

=item * C<tuned_model_id> - C<string>

=item * C<tuned_model> - L<Google::Ai::Generativelanguage::V1alpha::TunedModel::TunedModel>

=back

=item * B<update_tuned_model>

    my $response = $client->update_tuned_model(
        tuned_model              => $tuned_model,
        update_mask              => $update_mask,
    );

Calls the RPC method C<UpdateTunedModel> on C<google.ai.generativelanguage.v1alpha.ModelService>.

Request: L<Google::Ai::Generativelanguage::V1alpha::ModelService::UpdateTunedModelRequest>

Returns: L<Google::Ai::Generativelanguage::V1alpha::TunedModel::TunedModel>

Parameters:

=over 4

=item * C<tuned_model> - L<Google::Ai::Generativelanguage::V1alpha::TunedModel::TunedModel>

=item * C<update_mask> - L<Google::Protobuf::FieldMask::FieldMask>

=back

=item * B<delete_tuned_model>

    my $response = $client->delete_tuned_model(
        name                     => $name,
    );

Calls the RPC method C<DeleteTunedModel> on C<google.ai.generativelanguage.v1alpha.ModelService>.

Request: L<Google::Ai::Generativelanguage::V1alpha::ModelService::DeleteTunedModelRequest>

Returns: L<Google::Protobuf::Empty::Empty>

Parameters:

=over 4

=item * C<name> - C<string>

=back

=item * B<create_permission>

    my $response = $client->create_permission(
        parent                   => $parent,
        permission               => $permission,
    );

Calls the RPC method C<CreatePermission> on C<google.ai.generativelanguage.v1alpha.PermissionService>.

Request: L<Google::Ai::Generativelanguage::V1alpha::PermissionService::CreatePermissionRequest>

Returns: L<Google::Ai::Generativelanguage::V1alpha::Permission::Permission>

Parameters:

=over 4

=item * C<parent> - C<string>

=item * C<permission> - L<Google::Ai::Generativelanguage::V1alpha::Permission::Permission>

=back

=item * B<transfer_ownership>

    my $response = $client->transfer_ownership(
        name                     => $name,
        email_address            => $email_address,
    );

Calls the RPC method C<TransferOwnership> on C<google.ai.generativelanguage.v1alpha.PermissionService>.

Request: L<Google::Ai::Generativelanguage::V1alpha::PermissionService::TransferOwnershipRequest>

Returns: L<Google::Ai::Generativelanguage::V1alpha::PermissionService::TransferOwnershipResponse>

Parameters:

=over 4

=item * C<name> - C<string>

=item * C<email_address> - C<string>

=back

=item * B<predict>

    my $response = $client->predict(
        model                    => $model,
        instances                => [ ... ],
        parameters               => $parameters,
    );

Calls the RPC method C<Predict> on C<google.ai.generativelanguage.v1alpha.PredictionService>.

Request: L<Google::Ai::Generativelanguage::V1alpha::PredictionService::PredictRequest>

Returns: L<Google::Ai::Generativelanguage::V1alpha::PredictionService::PredictResponse>

Parameters:

=over 4

=item * C<model> - C<string>

=item * C<instances> - ArrayRef of L<Google::Protobuf::Value::Value>

=item * C<parameters> - L<Google::Protobuf::Value::Value>

=back

=item * B<create_corpus>

    my $response = $client->create_corpus(
        corpus                   => $corpus,
    );

Calls the RPC method C<CreateCorpus> on C<google.ai.generativelanguage.v1alpha.RetrieverService>.

Request: L<Google::Ai::Generativelanguage::V1alpha::RetrieverService::CreateCorpusRequest>

Returns: L<Google::Ai::Generativelanguage::V1alpha::Retriever::Corpus>

Parameters:

=over 4

=item * C<corpus> - L<Google::Ai::Generativelanguage::V1alpha::Retriever::Corpus>

=back

=item * B<get_corpus>

    my $response = $client->get_corpus(
        name                     => $name,
    );

Calls the RPC method C<GetCorpus> on C<google.ai.generativelanguage.v1alpha.RetrieverService>.

Request: L<Google::Ai::Generativelanguage::V1alpha::RetrieverService::GetCorpusRequest>

Returns: L<Google::Ai::Generativelanguage::V1alpha::Retriever::Corpus>

Parameters:

=over 4

=item * C<name> - C<string>

=back

=item * B<generate_text>

    my $response = $client->generate_text(
        model                    => $model,
        prompt                   => $prompt,
        temperature              => $temperature,
        candidate_count          => $candidate_count,
        max_output_tokens        => $max_output_tokens,
        top_p                    => $top_p,
        top_k                    => $top_k,
        safety_settings          => [ ... ],
        stop_sequences           => [ ... ],
    );

Calls the RPC method C<GenerateText> on C<google.ai.generativelanguage.v1alpha.TextService>.

Request: L<Google::Ai::Generativelanguage::V1alpha::TextService::GenerateTextRequest>

Returns: L<Google::Ai::Generativelanguage::V1alpha::TextService::GenerateTextResponse>

Parameters:

=over 4

=item * C<model> - C<string>

=item * C<prompt> - L<Google::Ai::Generativelanguage::V1alpha::TextService::TextPrompt>

=item * C<temperature> - C<float>

=item * C<candidate_count> - C<int32>

=item * C<max_output_tokens> - C<int32>

=item * C<top_p> - C<float>

=item * C<top_k> - C<int32>

=item * C<safety_settings> - ArrayRef of L<Google::Ai::Generativelanguage::V1alpha::Safety::SafetySetting>

=item * C<stop_sequences> - ArrayRef of C<string>

=back

=item * B<embed_text>

    my $response = $client->embed_text(
        model                    => $model,
        text                     => $text,
    );

Calls the RPC method C<EmbedText> on C<google.ai.generativelanguage.v1alpha.TextService>.

Request: L<Google::Ai::Generativelanguage::V1alpha::TextService::EmbedTextRequest>

Returns: L<Google::Ai::Generativelanguage::V1alpha::TextService::EmbedTextResponse>

Parameters:

=over 4

=item * C<model> - C<string>

=item * C<text> - C<string>

=back

=item * B<batch_embed_text>

    my $response = $client->batch_embed_text(
        model                    => $model,
        texts                    => [ ... ],
        requests                 => [ ... ],
    );

Calls the RPC method C<BatchEmbedText> on C<google.ai.generativelanguage.v1alpha.TextService>.

Request: L<Google::Ai::Generativelanguage::V1alpha::TextService::BatchEmbedTextRequest>

Returns: L<Google::Ai::Generativelanguage::V1alpha::TextService::BatchEmbedTextResponse>

Parameters:

=over 4

=item * C<model> - C<string>

=item * C<texts> - ArrayRef of C<string>

=item * C<requests> - ArrayRef of L<Google::Ai::Generativelanguage::V1alpha::TextService::EmbedTextRequest>

=back

=item * B<count_text_tokens>

    my $response = $client->count_text_tokens(
        model                    => $model,
        prompt                   => $prompt,
    );

Calls the RPC method C<CountTextTokens> on C<google.ai.generativelanguage.v1alpha.TextService>.

Request: L<Google::Ai::Generativelanguage::V1alpha::TextService::CountTextTokensRequest>

Returns: L<Google::Ai::Generativelanguage::V1alpha::TextService::CountTextTokensResponse>

Parameters:

=over 4

=item * C<model> - C<string>

=item * C<prompt> - L<Google::Ai::Generativelanguage::V1alpha::TextService::TextPrompt>

=back

=back



=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
