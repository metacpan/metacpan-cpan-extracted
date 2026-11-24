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
    for my $pkg (qw( Google::Cloud::Resourcemanager::V3::Projects::ListProjectsResponse Google::Cloud::Resourcemanager::V3::Projects::Project Google::Cloud::Resourcemanager::V3::Projects::SearchProjectsResponse Google::Iam::V1::IamPolicy::TestIamPermissionsResponse Google::Iam::V1::Policy::Policy Google::Longrunning::Operations::Operation )) {
        unless ($pkg->can('new')) {
            no strict 'refs';
            *{"${pkg}::new"} = sub { bless {}, $_[0] };
            $INC{join('/', split('::', $pkg)) . '.pm'} = 1;
        }
    }
}

# D. Main test execution
package main;
use Google::Cloud::Resourcemanager::V3::ProjectsClient;

my $client = Google::Cloud::Resourcemanager::V3::ProjectsClient->new();
ok($client, 'Instantiated generated client');
isa_ok($client->transport, 'Google::gRPC::Client', 'Client transport');

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

subtest 'get_iam_policy method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.resourcemanager.v3.Projects', 'Correct service path');
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
        is($args->{service}, 'google.cloud.resourcemanager.v3.Projects', 'Correct service path');
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
        is($args->{service}, 'google.cloud.resourcemanager.v3.Projects', 'Correct service path');
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

done_testing();
