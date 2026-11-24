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
    for my $pkg (qw( Google::Cloud::Resourcemanager::V3::Folders::Folder Google::Cloud::Resourcemanager::V3::Folders::ListFoldersResponse Google::Cloud::Resourcemanager::V3::Folders::SearchFoldersResponse Google::Cloud::Resourcemanager::V3::Organizations::Organization Google::Cloud::Resourcemanager::V3::Organizations::SearchOrganizationsResponse Google::Cloud::Resourcemanager::V3::Projects::ListProjectsResponse Google::Cloud::Resourcemanager::V3::Projects::Project Google::Cloud::Resourcemanager::V3::Projects::SearchProjectsResponse Google::Cloud::Resourcemanager::V3::TagBindings::ListEffectiveTagsResponse Google::Cloud::Resourcemanager::V3::TagBindings::ListTagBindingsResponse Google::Cloud::Resourcemanager::V3::TagHolds::ListTagHoldsResponse Google::Cloud::Resourcemanager::V3::TagKeys::ListTagKeysResponse Google::Cloud::Resourcemanager::V3::TagKeys::TagKey Google::Cloud::Resourcemanager::V3::TagValues::ListTagValuesResponse Google::Cloud::Resourcemanager::V3::TagValues::TagValue Google::Iam::V1::IamPolicy::TestIamPermissionsResponse Google::Iam::V1::Policy::Policy Google::Longrunning::Operations::Operation )) {
        unless ($pkg->can('new')) {
            no strict 'refs';
            *{"${pkg}::new"} = sub { bless {}, $_[0] };
            $INC{join('/', split('::', $pkg)) . '.pm'} = 1;
        }
    }
}

# D. Main test execution
package main;
use Google::Cloud::Resourcemanager::V3;

my $client = Google::Cloud::Resourcemanager::V3->new();
ok($client, 'Instantiated generated client');
isa_ok($client->transport, 'Google::gRPC::Client', 'Client transport');

subtest 'get_folder method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.resourcemanager.v3.Folders', 'Correct service path');
        is($args->{method}, 'GetFolder', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Resourcemanager::V3::Folders::GetFolderRequest', 'Request object');
        
        my $response = 'Google::Cloud::Resourcemanager::V3::Folders::Folder'->new();
        return $response;
    };
    
    my $res = $client->get_folder();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Resourcemanager::V3::Folders::Folder', 'Response object class');
    done_testing();
};

subtest 'list_folders method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.resourcemanager.v3.Folders', 'Correct service path');
        is($args->{method}, 'ListFolders', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Resourcemanager::V3::Folders::ListFoldersRequest', 'Request object');
        
        my $response = 'Google::Cloud::Resourcemanager::V3::Folders::ListFoldersResponse'->new();
        return $response;
    };
    
    my $res = $client->list_folders();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Resourcemanager::V3::Folders::ListFoldersResponse', 'Response object class');
    done_testing();
};

subtest 'search_folders method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.resourcemanager.v3.Folders', 'Correct service path');
        is($args->{method}, 'SearchFolders', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Resourcemanager::V3::Folders::SearchFoldersRequest', 'Request object');
        
        my $response = 'Google::Cloud::Resourcemanager::V3::Folders::SearchFoldersResponse'->new();
        return $response;
    };
    
    my $res = $client->search_folders();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Resourcemanager::V3::Folders::SearchFoldersResponse', 'Response object class');
    done_testing();
};

subtest 'create_folder method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.resourcemanager.v3.Folders', 'Correct service path');
        is($args->{method}, 'CreateFolder', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Resourcemanager::V3::Folders::CreateFolderRequest', 'Request object');
        
        my $response = 'Google::Longrunning::Operations::Operation'->new();
        return $response;
    };
    
    my $res = $client->create_folder();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Longrunning::Operations::Operation', 'Response object class');
    done_testing();
};

subtest 'update_folder method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.resourcemanager.v3.Folders', 'Correct service path');
        is($args->{method}, 'UpdateFolder', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Resourcemanager::V3::Folders::UpdateFolderRequest', 'Request object');
        
        my $response = 'Google::Longrunning::Operations::Operation'->new();
        return $response;
    };
    
    my $res = $client->update_folder();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Longrunning::Operations::Operation', 'Response object class');
    done_testing();
};

subtest 'move_folder method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.resourcemanager.v3.Folders', 'Correct service path');
        is($args->{method}, 'MoveFolder', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Resourcemanager::V3::Folders::MoveFolderRequest', 'Request object');
        
        my $response = 'Google::Longrunning::Operations::Operation'->new();
        return $response;
    };
    
    my $res = $client->move_folder();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Longrunning::Operations::Operation', 'Response object class');
    done_testing();
};

subtest 'delete_folder method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.resourcemanager.v3.Folders', 'Correct service path');
        is($args->{method}, 'DeleteFolder', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Resourcemanager::V3::Folders::DeleteFolderRequest', 'Request object');
        
        my $response = 'Google::Longrunning::Operations::Operation'->new();
        return $response;
    };
    
    my $res = $client->delete_folder();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Longrunning::Operations::Operation', 'Response object class');
    done_testing();
};

subtest 'undelete_folder method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.resourcemanager.v3.Folders', 'Correct service path');
        is($args->{method}, 'UndeleteFolder', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Resourcemanager::V3::Folders::UndeleteFolderRequest', 'Request object');
        
        my $response = 'Google::Longrunning::Operations::Operation'->new();
        return $response;
    };
    
    my $res = $client->undelete_folder();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Longrunning::Operations::Operation', 'Response object class');
    done_testing();
};

subtest 'get_iam_policy method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.resourcemanager.v3.Folders', 'Correct service path');
        is($args->{method}, 'GetIamPolicy', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Iam::V1::IamPolicy::GetIamPolicyRequest', 'Request object');
        
        my $response = 'Google::Iam::V1::Policy::Policy'->new();
        return $response;
    };
    
    my $res = $client->get_iam_policy();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Iam::V1::Policy::Policy', 'Response object class');
    done_testing();
};

subtest 'set_iam_policy method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.resourcemanager.v3.Folders', 'Correct service path');
        is($args->{method}, 'SetIamPolicy', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Iam::V1::IamPolicy::SetIamPolicyRequest', 'Request object');
        
        my $response = 'Google::Iam::V1::Policy::Policy'->new();
        return $response;
    };
    
    my $res = $client->set_iam_policy();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Iam::V1::Policy::Policy', 'Response object class');
    done_testing();
};

subtest 'test_iam_permissions method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.resourcemanager.v3.Folders', 'Correct service path');
        is($args->{method}, 'TestIamPermissions', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Iam::V1::IamPolicy::TestIamPermissionsRequest', 'Request object');
        
        my $response = 'Google::Iam::V1::IamPolicy::TestIamPermissionsResponse'->new();
        return $response;
    };
    
    my $res = $client->test_iam_permissions();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Iam::V1::IamPolicy::TestIamPermissionsResponse', 'Response object class');
    done_testing();
};

subtest 'get_organization method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.resourcemanager.v3.Organizations', 'Correct service path');
        is($args->{method}, 'GetOrganization', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Resourcemanager::V3::Organizations::GetOrganizationRequest', 'Request object');
        
        my $response = 'Google::Cloud::Resourcemanager::V3::Organizations::Organization'->new();
        return $response;
    };
    
    my $res = $client->get_organization();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Resourcemanager::V3::Organizations::Organization', 'Response object class');
    done_testing();
};

subtest 'search_organizations method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.resourcemanager.v3.Organizations', 'Correct service path');
        is($args->{method}, 'SearchOrganizations', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Resourcemanager::V3::Organizations::SearchOrganizationsRequest', 'Request object');
        
        my $response = 'Google::Cloud::Resourcemanager::V3::Organizations::SearchOrganizationsResponse'->new();
        return $response;
    };
    
    my $res = $client->search_organizations();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Resourcemanager::V3::Organizations::SearchOrganizationsResponse', 'Response object class');
    done_testing();
};

subtest 'get_project method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.resourcemanager.v3.Projects', 'Correct service path');
        is($args->{method}, 'GetProject', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Resourcemanager::V3::Projects::GetProjectRequest', 'Request object');
        
        my $response = 'Google::Cloud::Resourcemanager::V3::Projects::Project'->new();
        return $response;
    };
    
    my $res = $client->get_project();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Resourcemanager::V3::Projects::Project', 'Response object class');
    done_testing();
};

subtest 'list_projects method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.resourcemanager.v3.Projects', 'Correct service path');
        is($args->{method}, 'ListProjects', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Resourcemanager::V3::Projects::ListProjectsRequest', 'Request object');
        
        my $response = 'Google::Cloud::Resourcemanager::V3::Projects::ListProjectsResponse'->new();
        return $response;
    };
    
    my $res = $client->list_projects();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Resourcemanager::V3::Projects::ListProjectsResponse', 'Response object class');
    done_testing();
};

subtest 'search_projects method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.resourcemanager.v3.Projects', 'Correct service path');
        is($args->{method}, 'SearchProjects', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Resourcemanager::V3::Projects::SearchProjectsRequest', 'Request object');
        
        my $response = 'Google::Cloud::Resourcemanager::V3::Projects::SearchProjectsResponse'->new();
        return $response;
    };
    
    my $res = $client->search_projects();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Resourcemanager::V3::Projects::SearchProjectsResponse', 'Response object class');
    done_testing();
};

subtest 'create_project method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.resourcemanager.v3.Projects', 'Correct service path');
        is($args->{method}, 'CreateProject', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Resourcemanager::V3::Projects::CreateProjectRequest', 'Request object');
        
        my $response = 'Google::Longrunning::Operations::Operation'->new();
        return $response;
    };
    
    my $res = $client->create_project();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Longrunning::Operations::Operation', 'Response object class');
    done_testing();
};

subtest 'update_project method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.resourcemanager.v3.Projects', 'Correct service path');
        is($args->{method}, 'UpdateProject', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Resourcemanager::V3::Projects::UpdateProjectRequest', 'Request object');
        
        my $response = 'Google::Longrunning::Operations::Operation'->new();
        return $response;
    };
    
    my $res = $client->update_project();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Longrunning::Operations::Operation', 'Response object class');
    done_testing();
};

subtest 'move_project method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.resourcemanager.v3.Projects', 'Correct service path');
        is($args->{method}, 'MoveProject', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Resourcemanager::V3::Projects::MoveProjectRequest', 'Request object');
        
        my $response = 'Google::Longrunning::Operations::Operation'->new();
        return $response;
    };
    
    my $res = $client->move_project();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Longrunning::Operations::Operation', 'Response object class');
    done_testing();
};

subtest 'delete_project method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.resourcemanager.v3.Projects', 'Correct service path');
        is($args->{method}, 'DeleteProject', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Resourcemanager::V3::Projects::DeleteProjectRequest', 'Request object');
        
        my $response = 'Google::Longrunning::Operations::Operation'->new();
        return $response;
    };
    
    my $res = $client->delete_project();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Longrunning::Operations::Operation', 'Response object class');
    done_testing();
};

subtest 'undelete_project method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.resourcemanager.v3.Projects', 'Correct service path');
        is($args->{method}, 'UndeleteProject', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Resourcemanager::V3::Projects::UndeleteProjectRequest', 'Request object');
        
        my $response = 'Google::Longrunning::Operations::Operation'->new();
        return $response;
    };
    
    my $res = $client->undelete_project();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Longrunning::Operations::Operation', 'Response object class');
    done_testing();
};

subtest 'list_tag_bindings method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.resourcemanager.v3.TagBindings', 'Correct service path');
        is($args->{method}, 'ListTagBindings', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Resourcemanager::V3::TagBindings::ListTagBindingsRequest', 'Request object');
        
        my $response = 'Google::Cloud::Resourcemanager::V3::TagBindings::ListTagBindingsResponse'->new();
        return $response;
    };
    
    my $res = $client->list_tag_bindings();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Resourcemanager::V3::TagBindings::ListTagBindingsResponse', 'Response object class');
    done_testing();
};

subtest 'create_tag_binding method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.resourcemanager.v3.TagBindings', 'Correct service path');
        is($args->{method}, 'CreateTagBinding', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Resourcemanager::V3::TagBindings::CreateTagBindingRequest', 'Request object');
        
        my $response = 'Google::Longrunning::Operations::Operation'->new();
        return $response;
    };
    
    my $res = $client->create_tag_binding();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Longrunning::Operations::Operation', 'Response object class');
    done_testing();
};

subtest 'delete_tag_binding method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.resourcemanager.v3.TagBindings', 'Correct service path');
        is($args->{method}, 'DeleteTagBinding', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Resourcemanager::V3::TagBindings::DeleteTagBindingRequest', 'Request object');
        
        my $response = 'Google::Longrunning::Operations::Operation'->new();
        return $response;
    };
    
    my $res = $client->delete_tag_binding();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Longrunning::Operations::Operation', 'Response object class');
    done_testing();
};

subtest 'list_effective_tags method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.resourcemanager.v3.TagBindings', 'Correct service path');
        is($args->{method}, 'ListEffectiveTags', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Resourcemanager::V3::TagBindings::ListEffectiveTagsRequest', 'Request object');
        
        my $response = 'Google::Cloud::Resourcemanager::V3::TagBindings::ListEffectiveTagsResponse'->new();
        return $response;
    };
    
    my $res = $client->list_effective_tags();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Resourcemanager::V3::TagBindings::ListEffectiveTagsResponse', 'Response object class');
    done_testing();
};

subtest 'create_tag_hold method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.resourcemanager.v3.TagHolds', 'Correct service path');
        is($args->{method}, 'CreateTagHold', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Resourcemanager::V3::TagHolds::CreateTagHoldRequest', 'Request object');
        
        my $response = 'Google::Longrunning::Operations::Operation'->new();
        return $response;
    };
    
    my $res = $client->create_tag_hold();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Longrunning::Operations::Operation', 'Response object class');
    done_testing();
};

subtest 'list_tag_holds method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.resourcemanager.v3.TagHolds', 'Correct service path');
        is($args->{method}, 'ListTagHolds', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Resourcemanager::V3::TagHolds::ListTagHoldsRequest', 'Request object');
        
        my $response = 'Google::Cloud::Resourcemanager::V3::TagHolds::ListTagHoldsResponse'->new();
        return $response;
    };
    
    my $res = $client->list_tag_holds();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Resourcemanager::V3::TagHolds::ListTagHoldsResponse', 'Response object class');
    done_testing();
};

subtest 'list_tag_keys method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.resourcemanager.v3.TagKeys', 'Correct service path');
        is($args->{method}, 'ListTagKeys', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Resourcemanager::V3::TagKeys::ListTagKeysRequest', 'Request object');
        
        my $response = 'Google::Cloud::Resourcemanager::V3::TagKeys::ListTagKeysResponse'->new();
        return $response;
    };
    
    my $res = $client->list_tag_keys();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Resourcemanager::V3::TagKeys::ListTagKeysResponse', 'Response object class');
    done_testing();
};

subtest 'get_tag_key method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.resourcemanager.v3.TagKeys', 'Correct service path');
        is($args->{method}, 'GetTagKey', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Resourcemanager::V3::TagKeys::GetTagKeyRequest', 'Request object');
        
        my $response = 'Google::Cloud::Resourcemanager::V3::TagKeys::TagKey'->new();
        return $response;
    };
    
    my $res = $client->get_tag_key();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Resourcemanager::V3::TagKeys::TagKey', 'Response object class');
    done_testing();
};

subtest 'get_namespaced_tag_key method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.resourcemanager.v3.TagKeys', 'Correct service path');
        is($args->{method}, 'GetNamespacedTagKey', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Resourcemanager::V3::TagKeys::GetNamespacedTagKeyRequest', 'Request object');
        
        my $response = 'Google::Cloud::Resourcemanager::V3::TagKeys::TagKey'->new();
        return $response;
    };
    
    my $res = $client->get_namespaced_tag_key();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Resourcemanager::V3::TagKeys::TagKey', 'Response object class');
    done_testing();
};

subtest 'create_tag_key method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.resourcemanager.v3.TagKeys', 'Correct service path');
        is($args->{method}, 'CreateTagKey', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Resourcemanager::V3::TagKeys::CreateTagKeyRequest', 'Request object');
        
        my $response = 'Google::Longrunning::Operations::Operation'->new();
        return $response;
    };
    
    my $res = $client->create_tag_key();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Longrunning::Operations::Operation', 'Response object class');
    done_testing();
};

subtest 'update_tag_key method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.resourcemanager.v3.TagKeys', 'Correct service path');
        is($args->{method}, 'UpdateTagKey', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Resourcemanager::V3::TagKeys::UpdateTagKeyRequest', 'Request object');
        
        my $response = 'Google::Longrunning::Operations::Operation'->new();
        return $response;
    };
    
    my $res = $client->update_tag_key();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Longrunning::Operations::Operation', 'Response object class');
    done_testing();
};

subtest 'delete_tag_key method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.resourcemanager.v3.TagKeys', 'Correct service path');
        is($args->{method}, 'DeleteTagKey', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Resourcemanager::V3::TagKeys::DeleteTagKeyRequest', 'Request object');
        
        my $response = 'Google::Longrunning::Operations::Operation'->new();
        return $response;
    };
    
    my $res = $client->delete_tag_key();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Longrunning::Operations::Operation', 'Response object class');
    done_testing();
};

subtest 'list_tag_values method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.resourcemanager.v3.TagValues', 'Correct service path');
        is($args->{method}, 'ListTagValues', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Resourcemanager::V3::TagValues::ListTagValuesRequest', 'Request object');
        
        my $response = 'Google::Cloud::Resourcemanager::V3::TagValues::ListTagValuesResponse'->new();
        return $response;
    };
    
    my $res = $client->list_tag_values();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Resourcemanager::V3::TagValues::ListTagValuesResponse', 'Response object class');
    done_testing();
};

subtest 'get_tag_value method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.resourcemanager.v3.TagValues', 'Correct service path');
        is($args->{method}, 'GetTagValue', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Resourcemanager::V3::TagValues::GetTagValueRequest', 'Request object');
        
        my $response = 'Google::Cloud::Resourcemanager::V3::TagValues::TagValue'->new();
        return $response;
    };
    
    my $res = $client->get_tag_value();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Resourcemanager::V3::TagValues::TagValue', 'Response object class');
    done_testing();
};

subtest 'get_namespaced_tag_value method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.resourcemanager.v3.TagValues', 'Correct service path');
        is($args->{method}, 'GetNamespacedTagValue', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Resourcemanager::V3::TagValues::GetNamespacedTagValueRequest', 'Request object');
        
        my $response = 'Google::Cloud::Resourcemanager::V3::TagValues::TagValue'->new();
        return $response;
    };
    
    my $res = $client->get_namespaced_tag_value();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Resourcemanager::V3::TagValues::TagValue', 'Response object class');
    done_testing();
};

subtest 'create_tag_value method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.resourcemanager.v3.TagValues', 'Correct service path');
        is($args->{method}, 'CreateTagValue', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Resourcemanager::V3::TagValues::CreateTagValueRequest', 'Request object');
        
        my $response = 'Google::Longrunning::Operations::Operation'->new();
        return $response;
    };
    
    my $res = $client->create_tag_value();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Longrunning::Operations::Operation', 'Response object class');
    done_testing();
};

subtest 'update_tag_value method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.resourcemanager.v3.TagValues', 'Correct service path');
        is($args->{method}, 'UpdateTagValue', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Resourcemanager::V3::TagValues::UpdateTagValueRequest', 'Request object');
        
        my $response = 'Google::Longrunning::Operations::Operation'->new();
        return $response;
    };
    
    my $res = $client->update_tag_value();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Longrunning::Operations::Operation', 'Response object class');
    done_testing();
};

subtest 'delete_tag_value method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.resourcemanager.v3.TagValues', 'Correct service path');
        is($args->{method}, 'DeleteTagValue', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Resourcemanager::V3::TagValues::DeleteTagValueRequest', 'Request object');
        
        my $response = 'Google::Longrunning::Operations::Operation'->new();
        return $response;
    };
    
    my $res = $client->delete_tag_value();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Longrunning::Operations::Operation', 'Response object class');
    done_testing();
};

done_testing();
