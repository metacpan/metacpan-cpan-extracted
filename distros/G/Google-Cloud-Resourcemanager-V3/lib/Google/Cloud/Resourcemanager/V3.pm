package Google::Cloud::Resourcemanager::V3;

use strict;
use warnings;
use Moo;
use Google::gRPC::Client;
use Google::Cloud::REST::Client;
use Google::Auth;
use Carp qw(croak);

use Protobuf;
use Google::Api::Common;
use Google::Cloud::Resourcemanager::V3::TagBindings;
use Google::Cloud::Resourcemanager::V3::TagHolds;
use Google::Cloud::Resourcemanager::V3::TagKeys;
use Google::Cloud::Resourcemanager::V3::Organizations;
use Google::Cloud::Resourcemanager::V3::Projects;
use Google::Cloud::Resourcemanager::V3::Folders;
use Google::Cloud::Resourcemanager::V3::TagValues;

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

    my $target = 'cloudresourcemanager.googleapis.com:443';
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

sub get_folder {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Resourcemanager::V3::Folders::GetFolderRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Resourcemanager::V3::Folders::Folder';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.resourcemanager.v3.Folders/GetFolder',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.resourcemanager.v3.Folders',
        method         => 'GetFolder',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub list_folders {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Resourcemanager::V3::Folders::ListFoldersRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Resourcemanager::V3::Folders::ListFoldersResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.resourcemanager.v3.Folders/ListFolders',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.resourcemanager.v3.Folders',
        method         => 'ListFolders',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub search_folders {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Resourcemanager::V3::Folders::SearchFoldersRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Resourcemanager::V3::Folders::SearchFoldersResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.resourcemanager.v3.Folders/SearchFolders',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.resourcemanager.v3.Folders',
        method         => 'SearchFolders',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub create_folder {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Resourcemanager::V3::Folders::CreateFolderRequest';
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
            path           => '/google.cloud.resourcemanager.v3.Folders/CreateFolder',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.resourcemanager.v3.Folders',
        method         => 'CreateFolder',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub update_folder {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Resourcemanager::V3::Folders::UpdateFolderRequest';
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
            path           => '/google.cloud.resourcemanager.v3.Folders/UpdateFolder',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.resourcemanager.v3.Folders',
        method         => 'UpdateFolder',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub move_folder {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Resourcemanager::V3::Folders::MoveFolderRequest';
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
            path           => '/google.cloud.resourcemanager.v3.Folders/MoveFolder',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.resourcemanager.v3.Folders',
        method         => 'MoveFolder',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub delete_folder {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Resourcemanager::V3::Folders::DeleteFolderRequest';
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
            path           => '/google.cloud.resourcemanager.v3.Folders/DeleteFolder',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.resourcemanager.v3.Folders',
        method         => 'DeleteFolder',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub undelete_folder {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Resourcemanager::V3::Folders::UndeleteFolderRequest';
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
            path           => '/google.cloud.resourcemanager.v3.Folders/UndeleteFolder',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.resourcemanager.v3.Folders',
        method         => 'UndeleteFolder',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub get_iam_policy {
    my ($self, %params) = @_;

    my $request_class = 'Google::Iam::V1::IamPolicy::GetIamPolicyRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Iam::V1::Policy::Policy';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.resourcemanager.v3.Folders/GetIamPolicy',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.resourcemanager.v3.Folders',
        method         => 'GetIamPolicy',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub set_iam_policy {
    my ($self, %params) = @_;

    my $request_class = 'Google::Iam::V1::IamPolicy::SetIamPolicyRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Iam::V1::Policy::Policy';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.resourcemanager.v3.Folders/SetIamPolicy',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.resourcemanager.v3.Folders',
        method         => 'SetIamPolicy',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub test_iam_permissions {
    my ($self, %params) = @_;

    my $request_class = 'Google::Iam::V1::IamPolicy::TestIamPermissionsRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Iam::V1::IamPolicy::TestIamPermissionsResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.resourcemanager.v3.Folders/TestIamPermissions',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.resourcemanager.v3.Folders',
        method         => 'TestIamPermissions',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub get_organization {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Resourcemanager::V3::Organizations::GetOrganizationRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Resourcemanager::V3::Organizations::Organization';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.resourcemanager.v3.Organizations/GetOrganization',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.resourcemanager.v3.Organizations',
        method         => 'GetOrganization',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub search_organizations {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Resourcemanager::V3::Organizations::SearchOrganizationsRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Resourcemanager::V3::Organizations::SearchOrganizationsResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.resourcemanager.v3.Organizations/SearchOrganizations',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.resourcemanager.v3.Organizations',
        method         => 'SearchOrganizations',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub get_project {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Resourcemanager::V3::Projects::GetProjectRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Resourcemanager::V3::Projects::Project';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.resourcemanager.v3.Projects/GetProject',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.resourcemanager.v3.Projects',
        method         => 'GetProject',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub list_projects {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Resourcemanager::V3::Projects::ListProjectsRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Resourcemanager::V3::Projects::ListProjectsResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.resourcemanager.v3.Projects/ListProjects',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.resourcemanager.v3.Projects',
        method         => 'ListProjects',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub search_projects {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Resourcemanager::V3::Projects::SearchProjectsRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Resourcemanager::V3::Projects::SearchProjectsResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.resourcemanager.v3.Projects/SearchProjects',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.resourcemanager.v3.Projects',
        method         => 'SearchProjects',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub create_project {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Resourcemanager::V3::Projects::CreateProjectRequest';
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
            path           => '/google.cloud.resourcemanager.v3.Projects/CreateProject',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.resourcemanager.v3.Projects',
        method         => 'CreateProject',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub update_project {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Resourcemanager::V3::Projects::UpdateProjectRequest';
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
            path           => '/google.cloud.resourcemanager.v3.Projects/UpdateProject',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.resourcemanager.v3.Projects',
        method         => 'UpdateProject',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub move_project {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Resourcemanager::V3::Projects::MoveProjectRequest';
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
            path           => '/google.cloud.resourcemanager.v3.Projects/MoveProject',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.resourcemanager.v3.Projects',
        method         => 'MoveProject',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub delete_project {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Resourcemanager::V3::Projects::DeleteProjectRequest';
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
            path           => '/google.cloud.resourcemanager.v3.Projects/DeleteProject',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.resourcemanager.v3.Projects',
        method         => 'DeleteProject',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub undelete_project {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Resourcemanager::V3::Projects::UndeleteProjectRequest';
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
            path           => '/google.cloud.resourcemanager.v3.Projects/UndeleteProject',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.resourcemanager.v3.Projects',
        method         => 'UndeleteProject',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub list_tag_bindings {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Resourcemanager::V3::TagBindings::ListTagBindingsRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Resourcemanager::V3::TagBindings::ListTagBindingsResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.resourcemanager.v3.TagBindings/ListTagBindings',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.resourcemanager.v3.TagBindings',
        method         => 'ListTagBindings',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub create_tag_binding {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Resourcemanager::V3::TagBindings::CreateTagBindingRequest';
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
            path           => '/google.cloud.resourcemanager.v3.TagBindings/CreateTagBinding',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.resourcemanager.v3.TagBindings',
        method         => 'CreateTagBinding',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub delete_tag_binding {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Resourcemanager::V3::TagBindings::DeleteTagBindingRequest';
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
            path           => '/google.cloud.resourcemanager.v3.TagBindings/DeleteTagBinding',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.resourcemanager.v3.TagBindings',
        method         => 'DeleteTagBinding',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub list_effective_tags {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Resourcemanager::V3::TagBindings::ListEffectiveTagsRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Resourcemanager::V3::TagBindings::ListEffectiveTagsResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.resourcemanager.v3.TagBindings/ListEffectiveTags',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.resourcemanager.v3.TagBindings',
        method         => 'ListEffectiveTags',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub create_tag_hold {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Resourcemanager::V3::TagHolds::CreateTagHoldRequest';
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
            path           => '/google.cloud.resourcemanager.v3.TagHolds/CreateTagHold',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.resourcemanager.v3.TagHolds',
        method         => 'CreateTagHold',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub list_tag_holds {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Resourcemanager::V3::TagHolds::ListTagHoldsRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Resourcemanager::V3::TagHolds::ListTagHoldsResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.resourcemanager.v3.TagHolds/ListTagHolds',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.resourcemanager.v3.TagHolds',
        method         => 'ListTagHolds',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub list_tag_keys {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Resourcemanager::V3::TagKeys::ListTagKeysRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Resourcemanager::V3::TagKeys::ListTagKeysResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.resourcemanager.v3.TagKeys/ListTagKeys',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.resourcemanager.v3.TagKeys',
        method         => 'ListTagKeys',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub get_tag_key {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Resourcemanager::V3::TagKeys::GetTagKeyRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Resourcemanager::V3::TagKeys::TagKey';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.resourcemanager.v3.TagKeys/GetTagKey',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.resourcemanager.v3.TagKeys',
        method         => 'GetTagKey',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub get_namespaced_tag_key {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Resourcemanager::V3::TagKeys::GetNamespacedTagKeyRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Resourcemanager::V3::TagKeys::TagKey';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.resourcemanager.v3.TagKeys/GetNamespacedTagKey',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.resourcemanager.v3.TagKeys',
        method         => 'GetNamespacedTagKey',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub create_tag_key {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Resourcemanager::V3::TagKeys::CreateTagKeyRequest';
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
            path           => '/google.cloud.resourcemanager.v3.TagKeys/CreateTagKey',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.resourcemanager.v3.TagKeys',
        method         => 'CreateTagKey',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub update_tag_key {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Resourcemanager::V3::TagKeys::UpdateTagKeyRequest';
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
            path           => '/google.cloud.resourcemanager.v3.TagKeys/UpdateTagKey',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.resourcemanager.v3.TagKeys',
        method         => 'UpdateTagKey',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub delete_tag_key {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Resourcemanager::V3::TagKeys::DeleteTagKeyRequest';
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
            path           => '/google.cloud.resourcemanager.v3.TagKeys/DeleteTagKey',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.resourcemanager.v3.TagKeys',
        method         => 'DeleteTagKey',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub list_tag_values {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Resourcemanager::V3::TagValues::ListTagValuesRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Resourcemanager::V3::TagValues::ListTagValuesResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.resourcemanager.v3.TagValues/ListTagValues',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.resourcemanager.v3.TagValues',
        method         => 'ListTagValues',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub get_tag_value {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Resourcemanager::V3::TagValues::GetTagValueRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Resourcemanager::V3::TagValues::TagValue';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.resourcemanager.v3.TagValues/GetTagValue',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.resourcemanager.v3.TagValues',
        method         => 'GetTagValue',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub get_namespaced_tag_value {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Resourcemanager::V3::TagValues::GetNamespacedTagValueRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Resourcemanager::V3::TagValues::TagValue';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.resourcemanager.v3.TagValues/GetNamespacedTagValue',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.resourcemanager.v3.TagValues',
        method         => 'GetNamespacedTagValue',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub create_tag_value {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Resourcemanager::V3::TagValues::CreateTagValueRequest';
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
            path           => '/google.cloud.resourcemanager.v3.TagValues/CreateTagValue',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.resourcemanager.v3.TagValues',
        method         => 'CreateTagValue',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub update_tag_value {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Resourcemanager::V3::TagValues::UpdateTagValueRequest';
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
            path           => '/google.cloud.resourcemanager.v3.TagValues/UpdateTagValue',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.resourcemanager.v3.TagValues',
        method         => 'UpdateTagValue',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub delete_tag_value {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Resourcemanager::V3::TagValues::DeleteTagValueRequest';
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
            path           => '/google.cloud.resourcemanager.v3.TagValues/DeleteTagValue',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.resourcemanager.v3.TagValues',
        method         => 'DeleteTagValue',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}
1; # End of Google::Cloud::Resourcemanager::V3

__END__

=head1 NAME

Google::Cloud::Resourcemanager::V3 - Client library for Google Cloud Services

=head1 SYNOPSIS

    use Google::Cloud::Resourcemanager::V3;
    use Google::Auth;

    my $auth = Google::Auth->default();

    # 1. High-performance gRPC Transport (Default)
    my $grpc_client = Google::Cloud::Resourcemanager::V3->new(
        credentials => $auth,
        transport   => 'grpc', # Optional: 'grpc' is default
    );

    # 2. HTTP/REST Transport
    my $rest_client = Google::Cloud::Resourcemanager::V3->new(
        credentials => $auth,
        transport   => 'rest',
    );

    # Execute service methods
    my $res = $grpc_client->some_method( %params );

=head1 DESCRIPTION

C<Google::Cloud::Resourcemanager::V3> is an auto-generated client library for Google Cloud Services.

It provides a unified client interface supporting both high-performance HTTP/2 gRPC and HTTP/REST transports, with automatic Google Cloud Application Default Credentials (ADC) resolution and typed Protocol Buffers message handling.

=head1 SOURCE

Generated from the following Protocol Buffers schemas:

=over 4

=item * C<googleapis/google/cloud/resourcemanager/v3/folders.proto>

=item * C<googleapis/google/cloud/resourcemanager/v3/organizations.proto>

=item * C<googleapis/google/cloud/resourcemanager/v3/projects.proto>

=item * C<googleapis/google/cloud/resourcemanager/v3/tag_bindings.proto>

=item * C<googleapis/google/cloud/resourcemanager/v3/tag_holds.proto>

=item * C<googleapis/google/cloud/resourcemanager/v3/tag_keys.proto>

=item * C<googleapis/google/cloud/resourcemanager/v3/tag_values.proto>



=back

=head1 CONSTRUCTOR

=head2 new

    my $client = Google::Cloud::Resourcemanager::V3->new(
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

=item * B<get_folder>

    my $response = $client->get_folder(
        name                     => $name,
    );

Calls the RPC method C<GetFolder> on C<google.cloud.resourcemanager.v3.Folders>.

Request: L<Google::Cloud::Resourcemanager::V3::Folders::GetFolderRequest>

Returns: L<Google::Cloud::Resourcemanager::V3::Folders::Folder>

Parameters:

=over 4

=item * C<name> - C<string>

=back

=item * B<list_folders>

    my $response = $client->list_folders(
        parent                   => $parent,
        page_size                => $page_size,
        page_token               => $page_token,
        show_deleted             => $show_deleted,
    );

Calls the RPC method C<ListFolders> on C<google.cloud.resourcemanager.v3.Folders>.

Request: L<Google::Cloud::Resourcemanager::V3::Folders::ListFoldersRequest>

Returns: L<Google::Cloud::Resourcemanager::V3::Folders::ListFoldersResponse>

Parameters:

=over 4

=item * C<parent> - C<string>

=item * C<page_size> - C<int32>

=item * C<page_token> - C<string>

=item * C<show_deleted> - C<bool>

=back

=item * B<search_folders>

    my $response = $client->search_folders(
        page_size                => $page_size,
        page_token               => $page_token,
        query                    => $query,
    );

Calls the RPC method C<SearchFolders> on C<google.cloud.resourcemanager.v3.Folders>.

Request: L<Google::Cloud::Resourcemanager::V3::Folders::SearchFoldersRequest>

Returns: L<Google::Cloud::Resourcemanager::V3::Folders::SearchFoldersResponse>

Parameters:

=over 4

=item * C<page_size> - C<int32>

=item * C<page_token> - C<string>

=item * C<query> - C<string>

=back

=item * B<create_folder>

    my $response = $client->create_folder(
        folder                   => $folder,
    );

Calls the RPC method C<CreateFolder> on C<google.cloud.resourcemanager.v3.Folders>.

Request: L<Google::Cloud::Resourcemanager::V3::Folders::CreateFolderRequest>

Returns: L<Google::Longrunning::Operations::Operation>

Parameters:

=over 4

=item * C<folder> - L<Google::Cloud::Resourcemanager::V3::Folders::Folder>

=back

=item * B<update_folder>

    my $response = $client->update_folder(
        folder                   => $folder,
        update_mask              => $update_mask,
    );

Calls the RPC method C<UpdateFolder> on C<google.cloud.resourcemanager.v3.Folders>.

Request: L<Google::Cloud::Resourcemanager::V3::Folders::UpdateFolderRequest>

Returns: L<Google::Longrunning::Operations::Operation>

Parameters:

=over 4

=item * C<folder> - L<Google::Cloud::Resourcemanager::V3::Folders::Folder>

=item * C<update_mask> - L<Google::Protobuf::FieldMask::FieldMask>

=back

=item * B<move_folder>

    my $response = $client->move_folder(
        name                     => $name,
        destination_parent       => $destination_parent,
    );

Calls the RPC method C<MoveFolder> on C<google.cloud.resourcemanager.v3.Folders>.

Request: L<Google::Cloud::Resourcemanager::V3::Folders::MoveFolderRequest>

Returns: L<Google::Longrunning::Operations::Operation>

Parameters:

=over 4

=item * C<name> - C<string>

=item * C<destination_parent> - C<string>

=back

=item * B<delete_folder>

    my $response = $client->delete_folder(
        name                     => $name,
    );

Calls the RPC method C<DeleteFolder> on C<google.cloud.resourcemanager.v3.Folders>.

Request: L<Google::Cloud::Resourcemanager::V3::Folders::DeleteFolderRequest>

Returns: L<Google::Longrunning::Operations::Operation>

Parameters:

=over 4

=item * C<name> - C<string>

=back

=item * B<undelete_folder>

    my $response = $client->undelete_folder(
        name                     => $name,
    );

Calls the RPC method C<UndeleteFolder> on C<google.cloud.resourcemanager.v3.Folders>.

Request: L<Google::Cloud::Resourcemanager::V3::Folders::UndeleteFolderRequest>

Returns: L<Google::Longrunning::Operations::Operation>

Parameters:

=over 4

=item * C<name> - C<string>

=back

=item * B<get_iam_policy>

    my $response = $client->get_iam_policy();

Calls the RPC method C<GetIamPolicy> on C<google.cloud.resourcemanager.v3.Folders>.

Request: L<Google::Iam::V1::IamPolicy::GetIamPolicyRequest>

Returns: L<Google::Iam::V1::Policy::Policy>

=item * B<set_iam_policy>

    my $response = $client->set_iam_policy();

Calls the RPC method C<SetIamPolicy> on C<google.cloud.resourcemanager.v3.Folders>.

Request: L<Google::Iam::V1::IamPolicy::SetIamPolicyRequest>

Returns: L<Google::Iam::V1::Policy::Policy>

=item * B<test_iam_permissions>

    my $response = $client->test_iam_permissions();

Calls the RPC method C<TestIamPermissions> on C<google.cloud.resourcemanager.v3.Folders>.

Request: L<Google::Iam::V1::IamPolicy::TestIamPermissionsRequest>

Returns: L<Google::Iam::V1::IamPolicy::TestIamPermissionsResponse>

=item * B<get_organization>

    my $response = $client->get_organization(
        name                     => $name,
    );

Calls the RPC method C<GetOrganization> on C<google.cloud.resourcemanager.v3.Organizations>.

Request: L<Google::Cloud::Resourcemanager::V3::Organizations::GetOrganizationRequest>

Returns: L<Google::Cloud::Resourcemanager::V3::Organizations::Organization>

Parameters:

=over 4

=item * C<name> - C<string>

=back

=item * B<search_organizations>

    my $response = $client->search_organizations(
        page_size                => $page_size,
        page_token               => $page_token,
        query                    => $query,
    );

Calls the RPC method C<SearchOrganizations> on C<google.cloud.resourcemanager.v3.Organizations>.

Request: L<Google::Cloud::Resourcemanager::V3::Organizations::SearchOrganizationsRequest>

Returns: L<Google::Cloud::Resourcemanager::V3::Organizations::SearchOrganizationsResponse>

Parameters:

=over 4

=item * C<page_size> - C<int32>

=item * C<page_token> - C<string>

=item * C<query> - C<string>

=back

=item * B<get_project>

    my $response = $client->get_project(
        name                     => $name,
    );

Calls the RPC method C<GetProject> on C<google.cloud.resourcemanager.v3.Projects>.

Request: L<Google::Cloud::Resourcemanager::V3::Projects::GetProjectRequest>

Returns: L<Google::Cloud::Resourcemanager::V3::Projects::Project>

Parameters:

=over 4

=item * C<name> - C<string>

=back

=item * B<list_projects>

    my $response = $client->list_projects(
        parent                   => $parent,
        page_token               => $page_token,
        page_size                => $page_size,
        show_deleted             => $show_deleted,
    );

Calls the RPC method C<ListProjects> on C<google.cloud.resourcemanager.v3.Projects>.

Request: L<Google::Cloud::Resourcemanager::V3::Projects::ListProjectsRequest>

Returns: L<Google::Cloud::Resourcemanager::V3::Projects::ListProjectsResponse>

Parameters:

=over 4

=item * C<parent> - C<string>

=item * C<page_token> - C<string>

=item * C<page_size> - C<int32>

=item * C<show_deleted> - C<bool>

=back

=item * B<search_projects>

    my $response = $client->search_projects(
        query                    => $query,
        page_token               => $page_token,
        page_size                => $page_size,
    );

Calls the RPC method C<SearchProjects> on C<google.cloud.resourcemanager.v3.Projects>.

Request: L<Google::Cloud::Resourcemanager::V3::Projects::SearchProjectsRequest>

Returns: L<Google::Cloud::Resourcemanager::V3::Projects::SearchProjectsResponse>

Parameters:

=over 4

=item * C<query> - C<string>

=item * C<page_token> - C<string>

=item * C<page_size> - C<int32>

=back

=item * B<create_project>

    my $response = $client->create_project(
        project                  => $project,
    );

Calls the RPC method C<CreateProject> on C<google.cloud.resourcemanager.v3.Projects>.

Request: L<Google::Cloud::Resourcemanager::V3::Projects::CreateProjectRequest>

Returns: L<Google::Longrunning::Operations::Operation>

Parameters:

=over 4

=item * C<project> - L<Google::Cloud::Resourcemanager::V3::Projects::Project>

=back

=item * B<update_project>

    my $response = $client->update_project(
        project                  => $project,
        update_mask              => $update_mask,
    );

Calls the RPC method C<UpdateProject> on C<google.cloud.resourcemanager.v3.Projects>.

Request: L<Google::Cloud::Resourcemanager::V3::Projects::UpdateProjectRequest>

Returns: L<Google::Longrunning::Operations::Operation>

Parameters:

=over 4

=item * C<project> - L<Google::Cloud::Resourcemanager::V3::Projects::Project>

=item * C<update_mask> - L<Google::Protobuf::FieldMask::FieldMask>

=back

=item * B<move_project>

    my $response = $client->move_project(
        name                     => $name,
        destination_parent       => $destination_parent,
    );

Calls the RPC method C<MoveProject> on C<google.cloud.resourcemanager.v3.Projects>.

Request: L<Google::Cloud::Resourcemanager::V3::Projects::MoveProjectRequest>

Returns: L<Google::Longrunning::Operations::Operation>

Parameters:

=over 4

=item * C<name> - C<string>

=item * C<destination_parent> - C<string>

=back

=item * B<delete_project>

    my $response = $client->delete_project(
        name                     => $name,
    );

Calls the RPC method C<DeleteProject> on C<google.cloud.resourcemanager.v3.Projects>.

Request: L<Google::Cloud::Resourcemanager::V3::Projects::DeleteProjectRequest>

Returns: L<Google::Longrunning::Operations::Operation>

Parameters:

=over 4

=item * C<name> - C<string>

=back

=item * B<undelete_project>

    my $response = $client->undelete_project(
        name                     => $name,
    );

Calls the RPC method C<UndeleteProject> on C<google.cloud.resourcemanager.v3.Projects>.

Request: L<Google::Cloud::Resourcemanager::V3::Projects::UndeleteProjectRequest>

Returns: L<Google::Longrunning::Operations::Operation>

Parameters:

=over 4

=item * C<name> - C<string>

=back

=item * B<list_tag_bindings>

    my $response = $client->list_tag_bindings(
        parent                   => $parent,
        page_size                => $page_size,
        page_token               => $page_token,
    );

Calls the RPC method C<ListTagBindings> on C<google.cloud.resourcemanager.v3.TagBindings>.

Request: L<Google::Cloud::Resourcemanager::V3::TagBindings::ListTagBindingsRequest>

Returns: L<Google::Cloud::Resourcemanager::V3::TagBindings::ListTagBindingsResponse>

Parameters:

=over 4

=item * C<parent> - C<string>

=item * C<page_size> - C<int32>

=item * C<page_token> - C<string>

=back

=item * B<create_tag_binding>

    my $response = $client->create_tag_binding(
        tag_binding              => $tag_binding,
        validate_only            => $validate_only,
    );

Calls the RPC method C<CreateTagBinding> on C<google.cloud.resourcemanager.v3.TagBindings>.

Request: L<Google::Cloud::Resourcemanager::V3::TagBindings::CreateTagBindingRequest>

Returns: L<Google::Longrunning::Operations::Operation>

Parameters:

=over 4

=item * C<tag_binding> - L<Google::Cloud::Resourcemanager::V3::TagBindings::TagBinding>

=item * C<validate_only> - C<bool>

=back

=item * B<delete_tag_binding>

    my $response = $client->delete_tag_binding(
        name                     => $name,
    );

Calls the RPC method C<DeleteTagBinding> on C<google.cloud.resourcemanager.v3.TagBindings>.

Request: L<Google::Cloud::Resourcemanager::V3::TagBindings::DeleteTagBindingRequest>

Returns: L<Google::Longrunning::Operations::Operation>

Parameters:

=over 4

=item * C<name> - C<string>

=back

=item * B<list_effective_tags>

    my $response = $client->list_effective_tags(
        parent                   => $parent,
        page_size                => $page_size,
        page_token               => $page_token,
    );

Calls the RPC method C<ListEffectiveTags> on C<google.cloud.resourcemanager.v3.TagBindings>.

Request: L<Google::Cloud::Resourcemanager::V3::TagBindings::ListEffectiveTagsRequest>

Returns: L<Google::Cloud::Resourcemanager::V3::TagBindings::ListEffectiveTagsResponse>

Parameters:

=over 4

=item * C<parent> - C<string>

=item * C<page_size> - C<int32>

=item * C<page_token> - C<string>

=back

=item * B<create_tag_hold>

    my $response = $client->create_tag_hold(
        parent                   => $parent,
        tag_hold                 => $tag_hold,
        validate_only            => $validate_only,
    );

Calls the RPC method C<CreateTagHold> on C<google.cloud.resourcemanager.v3.TagHolds>.

Request: L<Google::Cloud::Resourcemanager::V3::TagHolds::CreateTagHoldRequest>

Returns: L<Google::Longrunning::Operations::Operation>

Parameters:

=over 4

=item * C<parent> - C<string>

=item * C<tag_hold> - L<Google::Cloud::Resourcemanager::V3::TagHolds::TagHold>

=item * C<validate_only> - C<bool>

=back

=item * B<list_tag_holds>

    my $response = $client->list_tag_holds(
        parent                   => $parent,
        page_size                => $page_size,
        page_token               => $page_token,
        filter                   => $filter,
    );

Calls the RPC method C<ListTagHolds> on C<google.cloud.resourcemanager.v3.TagHolds>.

Request: L<Google::Cloud::Resourcemanager::V3::TagHolds::ListTagHoldsRequest>

Returns: L<Google::Cloud::Resourcemanager::V3::TagHolds::ListTagHoldsResponse>

Parameters:

=over 4

=item * C<parent> - C<string>

=item * C<page_size> - C<int32>

=item * C<page_token> - C<string>

=item * C<filter> - C<string>

=back

=item * B<list_tag_keys>

    my $response = $client->list_tag_keys(
        parent                   => $parent,
        page_size                => $page_size,
        page_token               => $page_token,
    );

Calls the RPC method C<ListTagKeys> on C<google.cloud.resourcemanager.v3.TagKeys>.

Request: L<Google::Cloud::Resourcemanager::V3::TagKeys::ListTagKeysRequest>

Returns: L<Google::Cloud::Resourcemanager::V3::TagKeys::ListTagKeysResponse>

Parameters:

=over 4

=item * C<parent> - C<string>

=item * C<page_size> - C<int32>

=item * C<page_token> - C<string>

=back

=item * B<get_tag_key>

    my $response = $client->get_tag_key(
        name                     => $name,
    );

Calls the RPC method C<GetTagKey> on C<google.cloud.resourcemanager.v3.TagKeys>.

Request: L<Google::Cloud::Resourcemanager::V3::TagKeys::GetTagKeyRequest>

Returns: L<Google::Cloud::Resourcemanager::V3::TagKeys::TagKey>

Parameters:

=over 4

=item * C<name> - C<string>

=back

=item * B<get_namespaced_tag_key>

    my $response = $client->get_namespaced_tag_key(
        name                     => $name,
    );

Calls the RPC method C<GetNamespacedTagKey> on C<google.cloud.resourcemanager.v3.TagKeys>.

Request: L<Google::Cloud::Resourcemanager::V3::TagKeys::GetNamespacedTagKeyRequest>

Returns: L<Google::Cloud::Resourcemanager::V3::TagKeys::TagKey>

Parameters:

=over 4

=item * C<name> - C<string>

=back

=item * B<create_tag_key>

    my $response = $client->create_tag_key(
        tag_key                  => $tag_key,
        validate_only            => $validate_only,
    );

Calls the RPC method C<CreateTagKey> on C<google.cloud.resourcemanager.v3.TagKeys>.

Request: L<Google::Cloud::Resourcemanager::V3::TagKeys::CreateTagKeyRequest>

Returns: L<Google::Longrunning::Operations::Operation>

Parameters:

=over 4

=item * C<tag_key> - L<Google::Cloud::Resourcemanager::V3::TagKeys::TagKey>

=item * C<validate_only> - C<bool>

=back

=item * B<update_tag_key>

    my $response = $client->update_tag_key(
        tag_key                  => $tag_key,
        update_mask              => $update_mask,
        validate_only            => $validate_only,
    );

Calls the RPC method C<UpdateTagKey> on C<google.cloud.resourcemanager.v3.TagKeys>.

Request: L<Google::Cloud::Resourcemanager::V3::TagKeys::UpdateTagKeyRequest>

Returns: L<Google::Longrunning::Operations::Operation>

Parameters:

=over 4

=item * C<tag_key> - L<Google::Cloud::Resourcemanager::V3::TagKeys::TagKey>

=item * C<update_mask> - L<Google::Protobuf::FieldMask::FieldMask>

=item * C<validate_only> - C<bool>

=back

=item * B<delete_tag_key>

    my $response = $client->delete_tag_key(
        name                     => $name,
        validate_only            => $validate_only,
        etag                     => $etag,
    );

Calls the RPC method C<DeleteTagKey> on C<google.cloud.resourcemanager.v3.TagKeys>.

Request: L<Google::Cloud::Resourcemanager::V3::TagKeys::DeleteTagKeyRequest>

Returns: L<Google::Longrunning::Operations::Operation>

Parameters:

=over 4

=item * C<name> - C<string>

=item * C<validate_only> - C<bool>

=item * C<etag> - C<string>

=back

=item * B<list_tag_values>

    my $response = $client->list_tag_values(
        parent                   => $parent,
        page_size                => $page_size,
        page_token               => $page_token,
    );

Calls the RPC method C<ListTagValues> on C<google.cloud.resourcemanager.v3.TagValues>.

Request: L<Google::Cloud::Resourcemanager::V3::TagValues::ListTagValuesRequest>

Returns: L<Google::Cloud::Resourcemanager::V3::TagValues::ListTagValuesResponse>

Parameters:

=over 4

=item * C<parent> - C<string>

=item * C<page_size> - C<int32>

=item * C<page_token> - C<string>

=back

=item * B<get_tag_value>

    my $response = $client->get_tag_value(
        name                     => $name,
    );

Calls the RPC method C<GetTagValue> on C<google.cloud.resourcemanager.v3.TagValues>.

Request: L<Google::Cloud::Resourcemanager::V3::TagValues::GetTagValueRequest>

Returns: L<Google::Cloud::Resourcemanager::V3::TagValues::TagValue>

Parameters:

=over 4

=item * C<name> - C<string>

=back

=item * B<get_namespaced_tag_value>

    my $response = $client->get_namespaced_tag_value(
        name                     => $name,
    );

Calls the RPC method C<GetNamespacedTagValue> on C<google.cloud.resourcemanager.v3.TagValues>.

Request: L<Google::Cloud::Resourcemanager::V3::TagValues::GetNamespacedTagValueRequest>

Returns: L<Google::Cloud::Resourcemanager::V3::TagValues::TagValue>

Parameters:

=over 4

=item * C<name> - C<string>

=back

=item * B<create_tag_value>

    my $response = $client->create_tag_value(
        tag_value                => $tag_value,
        validate_only            => $validate_only,
    );

Calls the RPC method C<CreateTagValue> on C<google.cloud.resourcemanager.v3.TagValues>.

Request: L<Google::Cloud::Resourcemanager::V3::TagValues::CreateTagValueRequest>

Returns: L<Google::Longrunning::Operations::Operation>

Parameters:

=over 4

=item * C<tag_value> - L<Google::Cloud::Resourcemanager::V3::TagValues::TagValue>

=item * C<validate_only> - C<bool>

=back

=item * B<update_tag_value>

    my $response = $client->update_tag_value(
        tag_value                => $tag_value,
        update_mask              => $update_mask,
        validate_only            => $validate_only,
    );

Calls the RPC method C<UpdateTagValue> on C<google.cloud.resourcemanager.v3.TagValues>.

Request: L<Google::Cloud::Resourcemanager::V3::TagValues::UpdateTagValueRequest>

Returns: L<Google::Longrunning::Operations::Operation>

Parameters:

=over 4

=item * C<tag_value> - L<Google::Cloud::Resourcemanager::V3::TagValues::TagValue>

=item * C<update_mask> - L<Google::Protobuf::FieldMask::FieldMask>

=item * C<validate_only> - C<bool>

=back

=item * B<delete_tag_value>

    my $response = $client->delete_tag_value(
        name                     => $name,
        validate_only            => $validate_only,
        etag                     => $etag,
    );

Calls the RPC method C<DeleteTagValue> on C<google.cloud.resourcemanager.v3.TagValues>.

Request: L<Google::Cloud::Resourcemanager::V3::TagValues::DeleteTagValueRequest>

Returns: L<Google::Longrunning::Operations::Operation>

Parameters:

=over 4

=item * C<name> - C<string>

=item * C<validate_only> - C<bool>

=item * C<etag> - C<string>

=back

=back



=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
