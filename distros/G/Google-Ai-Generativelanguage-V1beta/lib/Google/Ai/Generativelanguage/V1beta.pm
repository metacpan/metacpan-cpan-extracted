package Google::Ai::Generativelanguage::V1beta;

use strict;
use warnings;
use Moo;
use Google::gRPC::Client;
use Google::Cloud::REST::Client;
use Google::Auth;
use Carp qw(croak);

use Protobuf;
use Google::Api::Common;
use Google::Ai::Generativelanguage::V1beta::Citation;
use Google::Ai::Generativelanguage::V1beta::Safety;
use Google::Ai::Generativelanguage::V1beta::Content;
use Google::Ai::Generativelanguage::V1beta::Permission;
use Google::Ai::Generativelanguage::V1beta::TunedModel;
use Google::Ai::Generativelanguage::V1beta::Retriever;
use Google::Ai::Generativelanguage::V1beta::Model;
use Google::Ai::Generativelanguage::V1beta::File;
use Google::Ai::Generativelanguage::V1beta::PredictionService;
use Google::Ai::Generativelanguage::V1beta::TextService;
use Google::Ai::Generativelanguage::V1beta::DiscussService;
use Google::Ai::Generativelanguage::V1beta::CachedContent;
use Google::Ai::Generativelanguage::V1beta::PermissionService;
use Google::Ai::Generativelanguage::V1beta::RetrieverService;
use Google::Ai::Generativelanguage::V1beta::GenerativeService;
use Google::Ai::Generativelanguage::V1beta::ModelService;
use Google::Ai::Generativelanguage::V1beta::FileService;
use Google::Ai::Generativelanguage::V1beta::CacheService;

our $VERSION = '0.02';

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

    my $request_class = 'Google::Ai::Generativelanguage::V1beta::CacheService::ListCachedContentsRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Ai::Generativelanguage::V1beta::CacheService::ListCachedContentsResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.ai.generativelanguage.v1beta.CacheService/ListCachedContents',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.ai.generativelanguage.v1beta.CacheService',
        method         => 'ListCachedContents',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub create_cached_content {
    my ($self, %params) = @_;

    my $request_class = 'Google::Ai::Generativelanguage::V1beta::CacheService::CreateCachedContentRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Ai::Generativelanguage::V1beta::CachedContent::CachedContent';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.ai.generativelanguage.v1beta.CacheService/CreateCachedContent',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.ai.generativelanguage.v1beta.CacheService',
        method         => 'CreateCachedContent',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub get_cached_content {
    my ($self, %params) = @_;

    my $request_class = 'Google::Ai::Generativelanguage::V1beta::CacheService::GetCachedContentRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Ai::Generativelanguage::V1beta::CachedContent::CachedContent';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.ai.generativelanguage.v1beta.CacheService/GetCachedContent',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.ai.generativelanguage.v1beta.CacheService',
        method         => 'GetCachedContent',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub update_cached_content {
    my ($self, %params) = @_;

    my $request_class = 'Google::Ai::Generativelanguage::V1beta::CacheService::UpdateCachedContentRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Ai::Generativelanguage::V1beta::CachedContent::CachedContent';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.ai.generativelanguage.v1beta.CacheService/UpdateCachedContent',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.ai.generativelanguage.v1beta.CacheService',
        method         => 'UpdateCachedContent',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub delete_cached_content {
    my ($self, %params) = @_;

    my $request_class = 'Google::Ai::Generativelanguage::V1beta::CacheService::DeleteCachedContentRequest';
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
            path           => '/google.ai.generativelanguage.v1beta.CacheService/DeleteCachedContent',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.ai.generativelanguage.v1beta.CacheService',
        method         => 'DeleteCachedContent',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub generate_message {
    my ($self, %params) = @_;

    my $request_class = 'Google::Ai::Generativelanguage::V1beta::DiscussService::GenerateMessageRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Ai::Generativelanguage::V1beta::DiscussService::GenerateMessageResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.ai.generativelanguage.v1beta.DiscussService/GenerateMessage',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.ai.generativelanguage.v1beta.DiscussService',
        method         => 'GenerateMessage',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub count_message_tokens {
    my ($self, %params) = @_;

    my $request_class = 'Google::Ai::Generativelanguage::V1beta::DiscussService::CountMessageTokensRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Ai::Generativelanguage::V1beta::DiscussService::CountMessageTokensResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.ai.generativelanguage.v1beta.DiscussService/CountMessageTokens',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.ai.generativelanguage.v1beta.DiscussService',
        method         => 'CountMessageTokens',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub create_file {
    my ($self, %params) = @_;

    my $request_class = 'Google::Ai::Generativelanguage::V1beta::FileService::CreateFileRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Ai::Generativelanguage::V1beta::FileService::CreateFileResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.ai.generativelanguage.v1beta.FileService/CreateFile',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.ai.generativelanguage.v1beta.FileService',
        method         => 'CreateFile',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub list_files {
    my ($self, %params) = @_;

    my $request_class = 'Google::Ai::Generativelanguage::V1beta::FileService::ListFilesRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Ai::Generativelanguage::V1beta::FileService::ListFilesResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.ai.generativelanguage.v1beta.FileService/ListFiles',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.ai.generativelanguage.v1beta.FileService',
        method         => 'ListFiles',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub get_file {
    my ($self, %params) = @_;

    my $request_class = 'Google::Ai::Generativelanguage::V1beta::FileService::GetFileRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Ai::Generativelanguage::V1beta::File::File';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.ai.generativelanguage.v1beta.FileService/GetFile',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.ai.generativelanguage.v1beta.FileService',
        method         => 'GetFile',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub delete_file {
    my ($self, %params) = @_;

    my $request_class = 'Google::Ai::Generativelanguage::V1beta::FileService::DeleteFileRequest';
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
            path           => '/google.ai.generativelanguage.v1beta.FileService/DeleteFile',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.ai.generativelanguage.v1beta.FileService',
        method         => 'DeleteFile',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub download_file {
    my ($self, %params) = @_;

    my $request_class = 'Google::Ai::Generativelanguage::V1beta::FileService::DownloadFileRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Ai::Generativelanguage::V1beta::FileService::DownloadFileResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.ai.generativelanguage.v1beta.FileService/DownloadFile',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.ai.generativelanguage.v1beta.FileService',
        method         => 'DownloadFile',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub generate_content {
    my ($self, %params) = @_;

    my $request_class = 'Google::Ai::Generativelanguage::V1beta::GenerativeService::GenerateContentRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Ai::Generativelanguage::V1beta::GenerativeService::GenerateContentResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.ai.generativelanguage.v1beta.GenerativeService/GenerateContent',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.ai.generativelanguage.v1beta.GenerativeService',
        method         => 'GenerateContent',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub generate_answer {
    my ($self, %params) = @_;

    my $request_class = 'Google::Ai::Generativelanguage::V1beta::GenerativeService::GenerateAnswerRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Ai::Generativelanguage::V1beta::GenerativeService::GenerateAnswerResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.ai.generativelanguage.v1beta.GenerativeService/GenerateAnswer',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.ai.generativelanguage.v1beta.GenerativeService',
        method         => 'GenerateAnswer',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub stream_generate_content {
    my ($self, %params) = @_;

    my $request_class = 'Google::Ai::Generativelanguage::V1beta::GenerativeService::GenerateContentRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Ai::Generativelanguage::V1beta::GenerativeService::GenerateContentResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.ai.generativelanguage.v1beta.GenerativeService/StreamGenerateContent',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.ai.generativelanguage.v1beta.GenerativeService',
        method         => 'StreamGenerateContent',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub embed_content {
    my ($self, %params) = @_;

    my $request_class = 'Google::Ai::Generativelanguage::V1beta::GenerativeService::EmbedContentRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Ai::Generativelanguage::V1beta::GenerativeService::EmbedContentResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.ai.generativelanguage.v1beta.GenerativeService/EmbedContent',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.ai.generativelanguage.v1beta.GenerativeService',
        method         => 'EmbedContent',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub batch_embed_contents {
    my ($self, %params) = @_;

    my $request_class = 'Google::Ai::Generativelanguage::V1beta::GenerativeService::BatchEmbedContentsRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Ai::Generativelanguage::V1beta::GenerativeService::BatchEmbedContentsResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.ai.generativelanguage.v1beta.GenerativeService/BatchEmbedContents',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.ai.generativelanguage.v1beta.GenerativeService',
        method         => 'BatchEmbedContents',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub count_tokens {
    my ($self, %params) = @_;

    my $request_class = 'Google::Ai::Generativelanguage::V1beta::GenerativeService::CountTokensRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Ai::Generativelanguage::V1beta::GenerativeService::CountTokensResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.ai.generativelanguage.v1beta.GenerativeService/CountTokens',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.ai.generativelanguage.v1beta.GenerativeService',
        method         => 'CountTokens',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub bidi_generate_content {
    my ($self, %params) = @_;

    my $request_class = 'Google::Ai::Generativelanguage::V1beta::GenerativeService::BidiGenerateContentClientMessage';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Ai::Generativelanguage::V1beta::GenerativeService::BidiGenerateContentServerMessage';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.ai.generativelanguage.v1beta.GenerativeService/BidiGenerateContent',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.ai.generativelanguage.v1beta.GenerativeService',
        method         => 'BidiGenerateContent',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub get_model {
    my ($self, %params) = @_;

    my $request_class = 'Google::Ai::Generativelanguage::V1beta::ModelService::GetModelRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Ai::Generativelanguage::V1beta::Model::Model';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.ai.generativelanguage.v1beta.ModelService/GetModel',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.ai.generativelanguage.v1beta.ModelService',
        method         => 'GetModel',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub list_models {
    my ($self, %params) = @_;

    my $request_class = 'Google::Ai::Generativelanguage::V1beta::ModelService::ListModelsRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Ai::Generativelanguage::V1beta::ModelService::ListModelsResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.ai.generativelanguage.v1beta.ModelService/ListModels',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.ai.generativelanguage.v1beta.ModelService',
        method         => 'ListModels',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub get_tuned_model {
    my ($self, %params) = @_;

    my $request_class = 'Google::Ai::Generativelanguage::V1beta::ModelService::GetTunedModelRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Ai::Generativelanguage::V1beta::TunedModel::TunedModel';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.ai.generativelanguage.v1beta.ModelService/GetTunedModel',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.ai.generativelanguage.v1beta.ModelService',
        method         => 'GetTunedModel',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub list_tuned_models {
    my ($self, %params) = @_;

    my $request_class = 'Google::Ai::Generativelanguage::V1beta::ModelService::ListTunedModelsRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Ai::Generativelanguage::V1beta::ModelService::ListTunedModelsResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.ai.generativelanguage.v1beta.ModelService/ListTunedModels',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.ai.generativelanguage.v1beta.ModelService',
        method         => 'ListTunedModels',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub create_tuned_model {
    my ($self, %params) = @_;

    my $request_class = 'Google::Ai::Generativelanguage::V1beta::ModelService::CreateTunedModelRequest';
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
            path           => '/google.ai.generativelanguage.v1beta.ModelService/CreateTunedModel',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.ai.generativelanguage.v1beta.ModelService',
        method         => 'CreateTunedModel',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub update_tuned_model {
    my ($self, %params) = @_;

    my $request_class = 'Google::Ai::Generativelanguage::V1beta::ModelService::UpdateTunedModelRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Ai::Generativelanguage::V1beta::TunedModel::TunedModel';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.ai.generativelanguage.v1beta.ModelService/UpdateTunedModel',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.ai.generativelanguage.v1beta.ModelService',
        method         => 'UpdateTunedModel',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub delete_tuned_model {
    my ($self, %params) = @_;

    my $request_class = 'Google::Ai::Generativelanguage::V1beta::ModelService::DeleteTunedModelRequest';
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
            path           => '/google.ai.generativelanguage.v1beta.ModelService/DeleteTunedModel',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.ai.generativelanguage.v1beta.ModelService',
        method         => 'DeleteTunedModel',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub create_permission {
    my ($self, %params) = @_;

    my $request_class = 'Google::Ai::Generativelanguage::V1beta::PermissionService::CreatePermissionRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Ai::Generativelanguage::V1beta::Permission::Permission';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.ai.generativelanguage.v1beta.PermissionService/CreatePermission',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.ai.generativelanguage.v1beta.PermissionService',
        method         => 'CreatePermission',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub transfer_ownership {
    my ($self, %params) = @_;

    my $request_class = 'Google::Ai::Generativelanguage::V1beta::PermissionService::TransferOwnershipRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Ai::Generativelanguage::V1beta::PermissionService::TransferOwnershipResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.ai.generativelanguage.v1beta.PermissionService/TransferOwnership',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.ai.generativelanguage.v1beta.PermissionService',
        method         => 'TransferOwnership',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub predict {
    my ($self, %params) = @_;

    my $request_class = 'Google::Ai::Generativelanguage::V1beta::PredictionService::PredictRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Ai::Generativelanguage::V1beta::PredictionService::PredictResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.ai.generativelanguage.v1beta.PredictionService/Predict',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.ai.generativelanguage.v1beta.PredictionService',
        method         => 'Predict',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub predict_long_running {
    my ($self, %params) = @_;

    my $request_class = 'Google::Ai::Generativelanguage::V1beta::PredictionService::PredictLongRunningRequest';
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
            path           => '/google.ai.generativelanguage.v1beta.PredictionService/PredictLongRunning',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.ai.generativelanguage.v1beta.PredictionService',
        method         => 'PredictLongRunning',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub create_corpus {
    my ($self, %params) = @_;

    my $request_class = 'Google::Ai::Generativelanguage::V1beta::RetrieverService::CreateCorpusRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Ai::Generativelanguage::V1beta::Retriever::Corpus';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.ai.generativelanguage.v1beta.RetrieverService/CreateCorpus',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.ai.generativelanguage.v1beta.RetrieverService',
        method         => 'CreateCorpus',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub get_corpus {
    my ($self, %params) = @_;

    my $request_class = 'Google::Ai::Generativelanguage::V1beta::RetrieverService::GetCorpusRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Ai::Generativelanguage::V1beta::Retriever::Corpus';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.ai.generativelanguage.v1beta.RetrieverService/GetCorpus',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.ai.generativelanguage.v1beta.RetrieverService',
        method         => 'GetCorpus',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub generate_text {
    my ($self, %params) = @_;

    my $request_class = 'Google::Ai::Generativelanguage::V1beta::TextService::GenerateTextRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Ai::Generativelanguage::V1beta::TextService::GenerateTextResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.ai.generativelanguage.v1beta.TextService/GenerateText',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.ai.generativelanguage.v1beta.TextService',
        method         => 'GenerateText',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub embed_text {
    my ($self, %params) = @_;

    my $request_class = 'Google::Ai::Generativelanguage::V1beta::TextService::EmbedTextRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Ai::Generativelanguage::V1beta::TextService::EmbedTextResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.ai.generativelanguage.v1beta.TextService/EmbedText',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.ai.generativelanguage.v1beta.TextService',
        method         => 'EmbedText',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub batch_embed_text {
    my ($self, %params) = @_;

    my $request_class = 'Google::Ai::Generativelanguage::V1beta::TextService::BatchEmbedTextRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Ai::Generativelanguage::V1beta::TextService::BatchEmbedTextResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.ai.generativelanguage.v1beta.TextService/BatchEmbedText',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.ai.generativelanguage.v1beta.TextService',
        method         => 'BatchEmbedText',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub count_text_tokens {
    my ($self, %params) = @_;

    my $request_class = 'Google::Ai::Generativelanguage::V1beta::TextService::CountTextTokensRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Ai::Generativelanguage::V1beta::TextService::CountTextTokensResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.ai.generativelanguage.v1beta.TextService/CountTextTokens',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.ai.generativelanguage.v1beta.TextService',
        method         => 'CountTextTokens',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}
1; # End of Google::Ai::Generativelanguage::V1beta

__END__

=head1 NAME

Google::Ai::Generativelanguage::V1beta - Client library for Google Cloud Services

=head1 SYNOPSIS

    use Google::Ai::Generativelanguage::V1beta;
    use Google::Auth;

    my $auth = Google::Auth->default();

    # 1. High-performance gRPC Transport (Default)
    my $grpc_client = Google::Ai::Generativelanguage::V1beta->new(
        credentials => $auth,
        transport   => 'grpc', # Optional: 'grpc' is default
    );

    # 2. HTTP/REST Transport
    my $rest_client = Google::Ai::Generativelanguage::V1beta->new(
        credentials => $auth,
        transport   => 'rest',
    );

    # Execute service methods
    my $res = $grpc_client->some_method( %params );

=head1 DESCRIPTION

C<Google::Ai::Generativelanguage::V1beta> is an auto-generated client library for Google Cloud Services.

It provides a unified client interface supporting both high-performance HTTP/2 gRPC and HTTP/REST transports, with automatic Google Cloud Application Default Credentials (ADC) resolution and typed Protocol Buffers message handling.

=head1 SOURCE

Generated from the following Protocol Buffers schemas:

=over 4

=item * C<googleapis/google/ai/generativelanguage/v1beta/cached_content.proto>

=item * C<googleapis/google/ai/generativelanguage/v1beta/cache_service.proto>

=item * C<googleapis/google/ai/generativelanguage/v1beta/citation.proto>

=item * C<googleapis/google/ai/generativelanguage/v1beta/content.proto>

=item * C<googleapis/google/ai/generativelanguage/v1beta/discuss_service.proto>

=item * C<googleapis/google/ai/generativelanguage/v1beta/file.proto>

=item * C<googleapis/google/ai/generativelanguage/v1beta/file_service.proto>

=item * C<googleapis/google/ai/generativelanguage/v1beta/generative_service.proto>

=item * C<googleapis/google/ai/generativelanguage/v1beta/model.proto>

=item * C<googleapis/google/ai/generativelanguage/v1beta/model_service.proto>

=item * C<googleapis/google/ai/generativelanguage/v1beta/permission.proto>

=item * C<googleapis/google/ai/generativelanguage/v1beta/permission_service.proto>

=item * C<googleapis/google/ai/generativelanguage/v1beta/prediction_service.proto>

=item * C<googleapis/google/ai/generativelanguage/v1beta/retriever.proto>

=item * C<googleapis/google/ai/generativelanguage/v1beta/retriever_service.proto>

=item * C<googleapis/google/ai/generativelanguage/v1beta/safety.proto>

=item * C<googleapis/google/ai/generativelanguage/v1beta/text_service.proto>

=item * C<googleapis/google/ai/generativelanguage/v1beta/tuned_model.proto>



=back

=head1 CONSTRUCTOR

=head2 new

    my $client = Google::Ai::Generativelanguage::V1beta->new(
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

Calls the RPC method C<ListCachedContents> on the service. Takes a hash of parameters representing the request.

=item * B<create_cached_content>

Calls the RPC method C<CreateCachedContent> on the service. Takes a hash of parameters representing the request.

=item * B<get_cached_content>

Calls the RPC method C<GetCachedContent> on the service. Takes a hash of parameters representing the request.

=item * B<update_cached_content>

Calls the RPC method C<UpdateCachedContent> on the service. Takes a hash of parameters representing the request.

=item * B<delete_cached_content>

Calls the RPC method C<DeleteCachedContent> on the service. Takes a hash of parameters representing the request.

=item * B<generate_message>

Calls the RPC method C<GenerateMessage> on the service. Takes a hash of parameters representing the request.

=item * B<count_message_tokens>

Calls the RPC method C<CountMessageTokens> on the service. Takes a hash of parameters representing the request.

=item * B<create_file>

Calls the RPC method C<CreateFile> on the service. Takes a hash of parameters representing the request.

=item * B<list_files>

Calls the RPC method C<ListFiles> on the service. Takes a hash of parameters representing the request.

=item * B<get_file>

Calls the RPC method C<GetFile> on the service. Takes a hash of parameters representing the request.

=item * B<delete_file>

Calls the RPC method C<DeleteFile> on the service. Takes a hash of parameters representing the request.

=item * B<download_file>

Calls the RPC method C<DownloadFile> on the service. Takes a hash of parameters representing the request.

=item * B<generate_content>

Calls the RPC method C<GenerateContent> on the service. Takes a hash of parameters representing the request.

=item * B<generate_answer>

Calls the RPC method C<GenerateAnswer> on the service. Takes a hash of parameters representing the request.

=item * B<stream_generate_content>

Calls the RPC method C<StreamGenerateContent> on the service. Takes a hash of parameters representing the request.

=item * B<embed_content>

Calls the RPC method C<EmbedContent> on the service. Takes a hash of parameters representing the request.

=item * B<batch_embed_contents>

Calls the RPC method C<BatchEmbedContents> on the service. Takes a hash of parameters representing the request.

=item * B<count_tokens>

Calls the RPC method C<CountTokens> on the service. Takes a hash of parameters representing the request.

=item * B<bidi_generate_content>

Calls the RPC method C<BidiGenerateContent> on the service. Takes a hash of parameters representing the request.

=item * B<get_model>

Calls the RPC method C<GetModel> on the service. Takes a hash of parameters representing the request.

=item * B<list_models>

Calls the RPC method C<ListModels> on the service. Takes a hash of parameters representing the request.

=item * B<get_tuned_model>

Calls the RPC method C<GetTunedModel> on the service. Takes a hash of parameters representing the request.

=item * B<list_tuned_models>

Calls the RPC method C<ListTunedModels> on the service. Takes a hash of parameters representing the request.

=item * B<create_tuned_model>

Calls the RPC method C<CreateTunedModel> on the service. Takes a hash of parameters representing the request.

=item * B<update_tuned_model>

Calls the RPC method C<UpdateTunedModel> on the service. Takes a hash of parameters representing the request.

=item * B<delete_tuned_model>

Calls the RPC method C<DeleteTunedModel> on the service. Takes a hash of parameters representing the request.

=item * B<create_permission>

Calls the RPC method C<CreatePermission> on the service. Takes a hash of parameters representing the request.

=item * B<transfer_ownership>

Calls the RPC method C<TransferOwnership> on the service. Takes a hash of parameters representing the request.

=item * B<predict>

Calls the RPC method C<Predict> on the service. Takes a hash of parameters representing the request.

=item * B<predict_long_running>

Calls the RPC method C<PredictLongRunning> on the service. Takes a hash of parameters representing the request.

=item * B<create_corpus>

Calls the RPC method C<CreateCorpus> on the service. Takes a hash of parameters representing the request.

=item * B<get_corpus>

Calls the RPC method C<GetCorpus> on the service. Takes a hash of parameters representing the request.

=item * B<generate_text>

Calls the RPC method C<GenerateText> on the service. Takes a hash of parameters representing the request.

=item * B<embed_text>

Calls the RPC method C<EmbedText> on the service. Takes a hash of parameters representing the request.

=item * B<batch_embed_text>

Calls the RPC method C<BatchEmbedText> on the service. Takes a hash of parameters representing the request.

=item * B<count_text_tokens>

Calls the RPC method C<CountTextTokens> on the service. Takes a hash of parameters representing the request.

=back



=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
