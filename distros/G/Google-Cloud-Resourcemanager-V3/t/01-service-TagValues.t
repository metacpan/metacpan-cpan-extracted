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
    for my $pkg (qw( Google::Cloud::Resourcemanager::V3::TagValues::ListTagValuesResponse Google::Cloud::Resourcemanager::V3::TagValues::TagValue Google::Iam::V1::IamPolicy::TestIamPermissionsResponse Google::Iam::V1::Policy::Policy Google::Longrunning::Operations::Operation )) {
        unless ($pkg->can('new')) {
            no strict 'refs';
            *{"${pkg}::new"} = sub { bless {}, $_[0] };
            $INC{join('/', split('::', $pkg)) . '.pm'} = 1;
        }
    }
}

# D. Main test execution
package main;
use Google::Cloud::Resourcemanager::V3::TagValuesClient;

my $client = Google::Cloud::Resourcemanager::V3::TagValuesClient->new();
ok($client, 'Instantiated generated client');
isa_ok($client->transport, 'Google::gRPC::Client', 'Client transport');

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

subtest 'get_iam_policy method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.resourcemanager.v3.TagValues', 'Correct service path');
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
        is($args->{service}, 'google.cloud.resourcemanager.v3.TagValues', 'Correct service path');
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
        is($args->{service}, 'google.cloud.resourcemanager.v3.TagValues', 'Correct service path');
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
