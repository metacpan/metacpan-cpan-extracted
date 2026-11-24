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
    for my $pkg (qw( Google::Iam::Admin::V1::Iam::LintPolicyResponse Google::Iam::Admin::V1::Iam::ListServiceAccountsResponse Google::Iam::Admin::V1::Iam::QueryAuditableServicesResponse Google::Iam::Admin::V1::Iam::QueryTestablePermissionsResponse )) {
        unless ($pkg->can('new')) {
            no strict 'refs';
            *{"${pkg}::new"} = sub { bless {}, $_[0] };
            $INC{join('/', split('::', $pkg)) . '.pm'} = 1;
        }
    }
}

# D. Main test execution
package main;
use Google::Cloud::Iam::Admin::V1;

my $client = Google::Cloud::Iam::Admin::V1->new();
ok($client, 'Instantiated generated client');
isa_ok($client->transport, 'Google::gRPC::Client', 'Client transport');

subtest 'list_service_accounts method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.iam.admin.v1.IAM', 'Correct service path');
        is($args->{method}, 'ListServiceAccounts', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Iam::Admin::V1::Iam::ListServiceAccountsRequest', 'Request object');
        
        my $response = 'Google::Iam::Admin::V1::Iam::ListServiceAccountsResponse'->new();
        return $response;
    };
    
    my $res = $client->list_service_accounts();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Iam::Admin::V1::Iam::ListServiceAccountsResponse', 'Response object class');
    done_testing();
};

subtest 'query_testable_permissions method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.iam.admin.v1.IAM', 'Correct service path');
        is($args->{method}, 'QueryTestablePermissions', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Iam::Admin::V1::Iam::QueryTestablePermissionsRequest', 'Request object');
        
        my $response = 'Google::Iam::Admin::V1::Iam::QueryTestablePermissionsResponse'->new();
        return $response;
    };
    
    my $res = $client->query_testable_permissions();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Iam::Admin::V1::Iam::QueryTestablePermissionsResponse', 'Response object class');
    done_testing();
};

subtest 'query_auditable_services method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.iam.admin.v1.IAM', 'Correct service path');
        is($args->{method}, 'QueryAuditableServices', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Iam::Admin::V1::Iam::QueryAuditableServicesRequest', 'Request object');
        
        my $response = 'Google::Iam::Admin::V1::Iam::QueryAuditableServicesResponse'->new();
        return $response;
    };
    
    my $res = $client->query_auditable_services();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Iam::Admin::V1::Iam::QueryAuditableServicesResponse', 'Response object class');
    done_testing();
};

subtest 'lint_policy method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.iam.admin.v1.IAM', 'Correct service path');
        is($args->{method}, 'LintPolicy', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Iam::Admin::V1::Iam::LintPolicyRequest', 'Request object');
        
        my $response = 'Google::Iam::Admin::V1::Iam::LintPolicyResponse'->new();
        return $response;
    };
    
    my $res = $client->lint_policy();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Iam::Admin::V1::Iam::LintPolicyResponse', 'Response object class');
    done_testing();
};

done_testing();
