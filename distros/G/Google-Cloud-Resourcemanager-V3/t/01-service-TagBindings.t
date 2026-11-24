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
    for my $pkg (qw( Google::Cloud::Resourcemanager::V3::TagBindings::ListEffectiveTagsResponse Google::Cloud::Resourcemanager::V3::TagBindings::ListTagBindingsResponse Google::Longrunning::Operations::Operation )) {
        unless ($pkg->can('new')) {
            no strict 'refs';
            *{"${pkg}::new"} = sub { bless {}, $_[0] };
            $INC{join('/', split('::', $pkg)) . '.pm'} = 1;
        }
    }
}

# D. Main test execution
package main;
use Google::Cloud::Resourcemanager::V3::TagBindingsClient;

my $client = Google::Cloud::Resourcemanager::V3::TagBindingsClient->new();
ok($client, 'Instantiated generated client');
isa_ok($client->transport, 'Google::gRPC::Client', 'Client transport');

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

done_testing();
