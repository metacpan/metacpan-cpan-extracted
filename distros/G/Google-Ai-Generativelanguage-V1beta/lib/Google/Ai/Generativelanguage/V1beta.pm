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
use Google::Ai::Generativelanguage::V1beta::Safety;
use Google::Ai::Generativelanguage::V1beta::Permission;
use Google::Ai::Generativelanguage::V1beta::Citation;
use Google::Ai::Generativelanguage::V1beta::Retriever;
use Google::Ai::Generativelanguage::V1beta::TunedModel;
use Google::Ai::Generativelanguage::V1beta::Content;
use Google::Ai::Generativelanguage::V1beta::Model;
use Google::Ai::Generativelanguage::V1beta::File;
use Google::Ai::Generativelanguage::V1beta::PredictionService;
use Google::Ai::Generativelanguage::V1beta::PermissionService;
use Google::Ai::Generativelanguage::V1beta::DiscussService;
use Google::Ai::Generativelanguage::V1beta::TextService;
use Google::Ai::Generativelanguage::V1beta::RetrieverService;
use Google::Ai::Generativelanguage::V1beta::CachedContent;
use Google::Ai::Generativelanguage::V1beta::GenerativeService;
use Google::Ai::Generativelanguage::V1beta::ModelService;
use Google::Ai::Generativelanguage::V1beta::FileService;
use Google::Ai::Generativelanguage::V1beta::CacheService;

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

=item * C<googleapis/google/ai/generativelanguage/v1beta/cache_service.proto>

=item * C<googleapis/google/ai/generativelanguage/v1beta/cached_content.proto>

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

    my $response = $client->list_cached_contents(
        page_size                => $page_size,
        page_token               => $page_token,
    );

Calls the RPC method C<ListCachedContents> on C<google.ai.generativelanguage.v1beta.CacheService>.

Request: L<Google::Ai::Generativelanguage::V1beta::CacheService::ListCachedContentsRequest>

Returns: L<Google::Ai::Generativelanguage::V1beta::CacheService::ListCachedContentsResponse>

Parameters:

=over 4

=item * C<page_size> - C<int32>

=item * C<page_token> - C<string>

=back

=item * B<create_cached_content>

    my $response = $client->create_cached_content(
        cached_content           => $cached_content,
    );

Calls the RPC method C<CreateCachedContent> on C<google.ai.generativelanguage.v1beta.CacheService>.

Request: L<Google::Ai::Generativelanguage::V1beta::CacheService::CreateCachedContentRequest>

Returns: L<Google::Ai::Generativelanguage::V1beta::CachedContent::CachedContent>

Parameters:

=over 4

=item * C<cached_content> - L<Google::Ai::Generativelanguage::V1beta::CachedContent::CachedContent>

=back

=item * B<get_cached_content>

    my $response = $client->get_cached_content(
        name                     => $name,
    );

Calls the RPC method C<GetCachedContent> on C<google.ai.generativelanguage.v1beta.CacheService>.

Request: L<Google::Ai::Generativelanguage::V1beta::CacheService::GetCachedContentRequest>

Returns: L<Google::Ai::Generativelanguage::V1beta::CachedContent::CachedContent>

Parameters:

=over 4

=item * C<name> - C<string>

=back

=item * B<update_cached_content>

    my $response = $client->update_cached_content(
        cached_content           => $cached_content,
        update_mask              => $update_mask,
    );

Calls the RPC method C<UpdateCachedContent> on C<google.ai.generativelanguage.v1beta.CacheService>.

Request: L<Google::Ai::Generativelanguage::V1beta::CacheService::UpdateCachedContentRequest>

Returns: L<Google::Ai::Generativelanguage::V1beta::CachedContent::CachedContent>

Parameters:

=over 4

=item * C<cached_content> - L<Google::Ai::Generativelanguage::V1beta::CachedContent::CachedContent>

=item * C<update_mask> - L<Google::Protobuf::FieldMask::FieldMask>

=back

=item * B<delete_cached_content>

    my $response = $client->delete_cached_content(
        name                     => $name,
    );

Calls the RPC method C<DeleteCachedContent> on C<google.ai.generativelanguage.v1beta.CacheService>.

Request: L<Google::Ai::Generativelanguage::V1beta::CacheService::DeleteCachedContentRequest>

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

Calls the RPC method C<GenerateMessage> on C<google.ai.generativelanguage.v1beta.DiscussService>.

Request: L<Google::Ai::Generativelanguage::V1beta::DiscussService::GenerateMessageRequest>

Returns: L<Google::Ai::Generativelanguage::V1beta::DiscussService::GenerateMessageResponse>

Parameters:

=over 4

=item * C<model> - C<string>

=item * C<prompt> - L<Google::Ai::Generativelanguage::V1beta::DiscussService::MessagePrompt>

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

Calls the RPC method C<CountMessageTokens> on C<google.ai.generativelanguage.v1beta.DiscussService>.

Request: L<Google::Ai::Generativelanguage::V1beta::DiscussService::CountMessageTokensRequest>

Returns: L<Google::Ai::Generativelanguage::V1beta::DiscussService::CountMessageTokensResponse>

Parameters:

=over 4

=item * C<model> - C<string>

=item * C<prompt> - L<Google::Ai::Generativelanguage::V1beta::DiscussService::MessagePrompt>

=back

=item * B<create_file>

    my $response = $client->create_file(
        file                     => $file,
    );

Calls the RPC method C<CreateFile> on C<google.ai.generativelanguage.v1beta.FileService>.

Request: L<Google::Ai::Generativelanguage::V1beta::FileService::CreateFileRequest>

Returns: L<Google::Ai::Generativelanguage::V1beta::FileService::CreateFileResponse>

Parameters:

=over 4

=item * C<file> - L<Google::Ai::Generativelanguage::V1beta::File::File>

=back

=item * B<list_files>

    my $response = $client->list_files(
        page_size                => $page_size,
        page_token               => $page_token,
    );

Calls the RPC method C<ListFiles> on C<google.ai.generativelanguage.v1beta.FileService>.

Request: L<Google::Ai::Generativelanguage::V1beta::FileService::ListFilesRequest>

Returns: L<Google::Ai::Generativelanguage::V1beta::FileService::ListFilesResponse>

Parameters:

=over 4

=item * C<page_size> - C<int32>

=item * C<page_token> - C<string>

=back

=item * B<get_file>

    my $response = $client->get_file(
        name                     => $name,
    );

Calls the RPC method C<GetFile> on C<google.ai.generativelanguage.v1beta.FileService>.

Request: L<Google::Ai::Generativelanguage::V1beta::FileService::GetFileRequest>

Returns: L<Google::Ai::Generativelanguage::V1beta::File::File>

Parameters:

=over 4

=item * C<name> - C<string>

=back

=item * B<delete_file>

    my $response = $client->delete_file(
        name                     => $name,
    );

Calls the RPC method C<DeleteFile> on C<google.ai.generativelanguage.v1beta.FileService>.

Request: L<Google::Ai::Generativelanguage::V1beta::FileService::DeleteFileRequest>

Returns: L<Google::Protobuf::Empty::Empty>

Parameters:

=over 4

=item * C<name> - C<string>

=back

=item * B<download_file>

    my $response = $client->download_file(
        name                     => $name,
    );

Calls the RPC method C<DownloadFile> on C<google.ai.generativelanguage.v1beta.FileService>.

Request: L<Google::Ai::Generativelanguage::V1beta::FileService::DownloadFileRequest>

Returns: L<Google::Ai::Generativelanguage::V1beta::FileService::DownloadFileResponse>

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

Calls the RPC method C<GenerateContent> on C<google.ai.generativelanguage.v1beta.GenerativeService>.

Request: L<Google::Ai::Generativelanguage::V1beta::GenerativeService::GenerateContentRequest>

Returns: L<Google::Ai::Generativelanguage::V1beta::GenerativeService::GenerateContentResponse>

Parameters:

=over 4

=item * C<model> - C<string>

=item * C<system_instruction> - L<Google::Ai::Generativelanguage::V1beta::Content::Content>

=item * C<contents> - ArrayRef of L<Google::Ai::Generativelanguage::V1beta::Content::Content>

=item * C<tools> - ArrayRef of L<Google::Ai::Generativelanguage::V1beta::Content::Tool>

=item * C<tool_config> - L<Google::Ai::Generativelanguage::V1beta::Content::ToolConfig>

=item * C<safety_settings> - ArrayRef of L<Google::Ai::Generativelanguage::V1beta::Safety::SafetySetting>

=item * C<generation_config> - L<Google::Ai::Generativelanguage::V1beta::GenerativeService::GenerationConfig>

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

Calls the RPC method C<GenerateAnswer> on C<google.ai.generativelanguage.v1beta.GenerativeService>.

Request: L<Google::Ai::Generativelanguage::V1beta::GenerativeService::GenerateAnswerRequest>

Returns: L<Google::Ai::Generativelanguage::V1beta::GenerativeService::GenerateAnswerResponse>

Parameters:

=over 4

=item * C<model> - C<string>

=item * C<contents> - ArrayRef of L<Google::Ai::Generativelanguage::V1beta::Content::Content>

=item * C<answer_style> - L<Google::Ai::Generativelanguage::V1beta::GenerativeService::AnswerStyle>

=item * C<safety_settings> - ArrayRef of L<Google::Ai::Generativelanguage::V1beta::Safety::SafetySetting>

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

Calls the RPC method C<StreamGenerateContent> on C<google.ai.generativelanguage.v1beta.GenerativeService>.

Request: L<Google::Ai::Generativelanguage::V1beta::GenerativeService::GenerateContentRequest>

Returns: L<Google::Ai::Generativelanguage::V1beta::GenerativeService::GenerateContentResponse>

Parameters:

=over 4

=item * C<model> - C<string>

=item * C<system_instruction> - L<Google::Ai::Generativelanguage::V1beta::Content::Content>

=item * C<contents> - ArrayRef of L<Google::Ai::Generativelanguage::V1beta::Content::Content>

=item * C<tools> - ArrayRef of L<Google::Ai::Generativelanguage::V1beta::Content::Tool>

=item * C<tool_config> - L<Google::Ai::Generativelanguage::V1beta::Content::ToolConfig>

=item * C<safety_settings> - ArrayRef of L<Google::Ai::Generativelanguage::V1beta::Safety::SafetySetting>

=item * C<generation_config> - L<Google::Ai::Generativelanguage::V1beta::GenerativeService::GenerationConfig>

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

Calls the RPC method C<EmbedContent> on C<google.ai.generativelanguage.v1beta.GenerativeService>.

Request: L<Google::Ai::Generativelanguage::V1beta::GenerativeService::EmbedContentRequest>

Returns: L<Google::Ai::Generativelanguage::V1beta::GenerativeService::EmbedContentResponse>

Parameters:

=over 4

=item * C<model> - C<string>

=item * C<content> - L<Google::Ai::Generativelanguage::V1beta::Content::Content>

=item * C<task_type> - L<Google::Ai::Generativelanguage::V1beta::GenerativeService::TaskType>

=item * C<title> - C<string>

=item * C<output_dimensionality> - C<int32>

=back

=item * B<batch_embed_contents>

    my $response = $client->batch_embed_contents(
        model                    => $model,
        requests                 => [ ... ],
    );

Calls the RPC method C<BatchEmbedContents> on C<google.ai.generativelanguage.v1beta.GenerativeService>.

Request: L<Google::Ai::Generativelanguage::V1beta::GenerativeService::BatchEmbedContentsRequest>

Returns: L<Google::Ai::Generativelanguage::V1beta::GenerativeService::BatchEmbedContentsResponse>

Parameters:

=over 4

=item * C<model> - C<string>

=item * C<requests> - ArrayRef of L<Google::Ai::Generativelanguage::V1beta::GenerativeService::EmbedContentRequest>

=back

=item * B<count_tokens>

    my $response = $client->count_tokens(
        model                    => $model,
        contents                 => [ ... ],
        generate_content_request => $generate_content_request,
    );

Calls the RPC method C<CountTokens> on C<google.ai.generativelanguage.v1beta.GenerativeService>.

Request: L<Google::Ai::Generativelanguage::V1beta::GenerativeService::CountTokensRequest>

Returns: L<Google::Ai::Generativelanguage::V1beta::GenerativeService::CountTokensResponse>

Parameters:

=over 4

=item * C<model> - C<string>

=item * C<contents> - ArrayRef of L<Google::Ai::Generativelanguage::V1beta::Content::Content>

=item * C<generate_content_request> - L<Google::Ai::Generativelanguage::V1beta::GenerativeService::GenerateContentRequest>

=back

=item * B<bidi_generate_content>

    my $response = $client->bidi_generate_content();

Calls the RPC method C<BidiGenerateContent> on C<google.ai.generativelanguage.v1beta.GenerativeService>.

Request: L<Google::Ai::Generativelanguage::V1beta::GenerativeService::BidiGenerateContentClientMessage>

Returns: L<Google::Ai::Generativelanguage::V1beta::GenerativeService::BidiGenerateContentServerMessage>

=item * B<get_model>

    my $response = $client->get_model(
        name                     => $name,
    );

Calls the RPC method C<GetModel> on C<google.ai.generativelanguage.v1beta.ModelService>.

Request: L<Google::Ai::Generativelanguage::V1beta::ModelService::GetModelRequest>

Returns: L<Google::Ai::Generativelanguage::V1beta::Model::Model>

Parameters:

=over 4

=item * C<name> - C<string>

=back

=item * B<list_models>

    my $response = $client->list_models(
        page_size                => $page_size,
        page_token               => $page_token,
    );

Calls the RPC method C<ListModels> on C<google.ai.generativelanguage.v1beta.ModelService>.

Request: L<Google::Ai::Generativelanguage::V1beta::ModelService::ListModelsRequest>

Returns: L<Google::Ai::Generativelanguage::V1beta::ModelService::ListModelsResponse>

Parameters:

=over 4

=item * C<page_size> - C<int32>

=item * C<page_token> - C<string>

=back

=item * B<get_tuned_model>

    my $response = $client->get_tuned_model(
        name                     => $name,
    );

Calls the RPC method C<GetTunedModel> on C<google.ai.generativelanguage.v1beta.ModelService>.

Request: L<Google::Ai::Generativelanguage::V1beta::ModelService::GetTunedModelRequest>

Returns: L<Google::Ai::Generativelanguage::V1beta::TunedModel::TunedModel>

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

Calls the RPC method C<ListTunedModels> on C<google.ai.generativelanguage.v1beta.ModelService>.

Request: L<Google::Ai::Generativelanguage::V1beta::ModelService::ListTunedModelsRequest>

Returns: L<Google::Ai::Generativelanguage::V1beta::ModelService::ListTunedModelsResponse>

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

Calls the RPC method C<CreateTunedModel> on C<google.ai.generativelanguage.v1beta.ModelService>.

Request: L<Google::Ai::Generativelanguage::V1beta::ModelService::CreateTunedModelRequest>

Returns: L<Google::Longrunning::Operations::Operation>

Parameters:

=over 4

=item * C<tuned_model_id> - C<string>

=item * C<tuned_model> - L<Google::Ai::Generativelanguage::V1beta::TunedModel::TunedModel>

=back

=item * B<update_tuned_model>

    my $response = $client->update_tuned_model(
        tuned_model              => $tuned_model,
        update_mask              => $update_mask,
    );

Calls the RPC method C<UpdateTunedModel> on C<google.ai.generativelanguage.v1beta.ModelService>.

Request: L<Google::Ai::Generativelanguage::V1beta::ModelService::UpdateTunedModelRequest>

Returns: L<Google::Ai::Generativelanguage::V1beta::TunedModel::TunedModel>

Parameters:

=over 4

=item * C<tuned_model> - L<Google::Ai::Generativelanguage::V1beta::TunedModel::TunedModel>

=item * C<update_mask> - L<Google::Protobuf::FieldMask::FieldMask>

=back

=item * B<delete_tuned_model>

    my $response = $client->delete_tuned_model(
        name                     => $name,
    );

Calls the RPC method C<DeleteTunedModel> on C<google.ai.generativelanguage.v1beta.ModelService>.

Request: L<Google::Ai::Generativelanguage::V1beta::ModelService::DeleteTunedModelRequest>

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

Calls the RPC method C<CreatePermission> on C<google.ai.generativelanguage.v1beta.PermissionService>.

Request: L<Google::Ai::Generativelanguage::V1beta::PermissionService::CreatePermissionRequest>

Returns: L<Google::Ai::Generativelanguage::V1beta::Permission::Permission>

Parameters:

=over 4

=item * C<parent> - C<string>

=item * C<permission> - L<Google::Ai::Generativelanguage::V1beta::Permission::Permission>

=back

=item * B<transfer_ownership>

    my $response = $client->transfer_ownership(
        name                     => $name,
        email_address            => $email_address,
    );

Calls the RPC method C<TransferOwnership> on C<google.ai.generativelanguage.v1beta.PermissionService>.

Request: L<Google::Ai::Generativelanguage::V1beta::PermissionService::TransferOwnershipRequest>

Returns: L<Google::Ai::Generativelanguage::V1beta::PermissionService::TransferOwnershipResponse>

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

Calls the RPC method C<Predict> on C<google.ai.generativelanguage.v1beta.PredictionService>.

Request: L<Google::Ai::Generativelanguage::V1beta::PredictionService::PredictRequest>

Returns: L<Google::Ai::Generativelanguage::V1beta::PredictionService::PredictResponse>

Parameters:

=over 4

=item * C<model> - C<string>

=item * C<instances> - ArrayRef of L<Google::Protobuf::Value::Value>

=item * C<parameters> - L<Google::Protobuf::Value::Value>

=back

=item * B<predict_long_running>

    my $response = $client->predict_long_running(
        model                    => $model,
        instances                => [ ... ],
        parameters               => $parameters,
    );

Calls the RPC method C<PredictLongRunning> on C<google.ai.generativelanguage.v1beta.PredictionService>.

Request: L<Google::Ai::Generativelanguage::V1beta::PredictionService::PredictLongRunningRequest>

Returns: L<Google::Longrunning::Operations::Operation>

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

Calls the RPC method C<CreateCorpus> on C<google.ai.generativelanguage.v1beta.RetrieverService>.

Request: L<Google::Ai::Generativelanguage::V1beta::RetrieverService::CreateCorpusRequest>

Returns: L<Google::Ai::Generativelanguage::V1beta::Retriever::Corpus>

Parameters:

=over 4

=item * C<corpus> - L<Google::Ai::Generativelanguage::V1beta::Retriever::Corpus>

=back

=item * B<get_corpus>

    my $response = $client->get_corpus(
        name                     => $name,
    );

Calls the RPC method C<GetCorpus> on C<google.ai.generativelanguage.v1beta.RetrieverService>.

Request: L<Google::Ai::Generativelanguage::V1beta::RetrieverService::GetCorpusRequest>

Returns: L<Google::Ai::Generativelanguage::V1beta::Retriever::Corpus>

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

Calls the RPC method C<GenerateText> on C<google.ai.generativelanguage.v1beta.TextService>.

Request: L<Google::Ai::Generativelanguage::V1beta::TextService::GenerateTextRequest>

Returns: L<Google::Ai::Generativelanguage::V1beta::TextService::GenerateTextResponse>

Parameters:

=over 4

=item * C<model> - C<string>

=item * C<prompt> - L<Google::Ai::Generativelanguage::V1beta::TextService::TextPrompt>

=item * C<temperature> - C<float>

=item * C<candidate_count> - C<int32>

=item * C<max_output_tokens> - C<int32>

=item * C<top_p> - C<float>

=item * C<top_k> - C<int32>

=item * C<safety_settings> - ArrayRef of L<Google::Ai::Generativelanguage::V1beta::Safety::SafetySetting>

=item * C<stop_sequences> - ArrayRef of C<string>

=back

=item * B<embed_text>

    my $response = $client->embed_text(
        model                    => $model,
        text                     => $text,
    );

Calls the RPC method C<EmbedText> on C<google.ai.generativelanguage.v1beta.TextService>.

Request: L<Google::Ai::Generativelanguage::V1beta::TextService::EmbedTextRequest>

Returns: L<Google::Ai::Generativelanguage::V1beta::TextService::EmbedTextResponse>

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

Calls the RPC method C<BatchEmbedText> on C<google.ai.generativelanguage.v1beta.TextService>.

Request: L<Google::Ai::Generativelanguage::V1beta::TextService::BatchEmbedTextRequest>

Returns: L<Google::Ai::Generativelanguage::V1beta::TextService::BatchEmbedTextResponse>

Parameters:

=over 4

=item * C<model> - C<string>

=item * C<texts> - ArrayRef of C<string>

=item * C<requests> - ArrayRef of L<Google::Ai::Generativelanguage::V1beta::TextService::EmbedTextRequest>

=back

=item * B<count_text_tokens>

    my $response = $client->count_text_tokens(
        model                    => $model,
        prompt                   => $prompt,
    );

Calls the RPC method C<CountTextTokens> on C<google.ai.generativelanguage.v1beta.TextService>.

Request: L<Google::Ai::Generativelanguage::V1beta::TextService::CountTextTokensRequest>

Returns: L<Google::Ai::Generativelanguage::V1beta::TextService::CountTextTokensResponse>

Parameters:

=over 4

=item * C<model> - C<string>

=item * C<prompt> - L<Google::Ai::Generativelanguage::V1beta::TextService::TextPrompt>

=back

=back



=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
