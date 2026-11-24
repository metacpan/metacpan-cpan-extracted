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
    for my $pkg (qw( Google::Cloud::Identitytoolkit::V2::AccountManagementService::FinalizeMfaEnrollmentResponse Google::Cloud::Identitytoolkit::V2::AccountManagementService::StartMfaEnrollmentResponse Google::Cloud::Identitytoolkit::V2::AccountManagementService::WithdrawMfaResponse Google::Cloud::Identitytoolkit::V2::AuthenticationService::FinalizeMfaSignInResponse Google::Cloud::Identitytoolkit::V2::AuthenticationService::StartMfaSignInResponse )) {
        unless ($pkg->can('new')) {
            no strict 'refs';
            *{"${pkg}::new"} = sub { bless {}, $_[0] };
            $INC{join('/', split('::', $pkg)) . '.pm'} = 1;
        }
    }
}

# D. Main test execution
package main;
use Google::Cloud::Identitytoolkit::V2;

my $client = Google::Cloud::Identitytoolkit::V2->new();
ok($client, 'Instantiated generated client');
isa_ok($client->transport, 'Google::gRPC::Client', 'Client transport');

subtest 'finalize_mfa_enrollment method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.identitytoolkit.v2.AccountManagementService', 'Correct service path');
        is($args->{method}, 'FinalizeMfaEnrollment', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Identitytoolkit::V2::AccountManagementService::FinalizeMfaEnrollmentRequest', 'Request object');
        
        my $response = 'Google::Cloud::Identitytoolkit::V2::AccountManagementService::FinalizeMfaEnrollmentResponse'->new();
        return $response;
    };
    
    my $res = $client->finalize_mfa_enrollment();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Identitytoolkit::V2::AccountManagementService::FinalizeMfaEnrollmentResponse', 'Response object class');
    done_testing();
};

subtest 'start_mfa_enrollment method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.identitytoolkit.v2.AccountManagementService', 'Correct service path');
        is($args->{method}, 'StartMfaEnrollment', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Identitytoolkit::V2::AccountManagementService::StartMfaEnrollmentRequest', 'Request object');
        
        my $response = 'Google::Cloud::Identitytoolkit::V2::AccountManagementService::StartMfaEnrollmentResponse'->new();
        return $response;
    };
    
    my $res = $client->start_mfa_enrollment();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Identitytoolkit::V2::AccountManagementService::StartMfaEnrollmentResponse', 'Response object class');
    done_testing();
};

subtest 'withdraw_mfa method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.identitytoolkit.v2.AccountManagementService', 'Correct service path');
        is($args->{method}, 'WithdrawMfa', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Identitytoolkit::V2::AccountManagementService::WithdrawMfaRequest', 'Request object');
        
        my $response = 'Google::Cloud::Identitytoolkit::V2::AccountManagementService::WithdrawMfaResponse'->new();
        return $response;
    };
    
    my $res = $client->withdraw_mfa();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Identitytoolkit::V2::AccountManagementService::WithdrawMfaResponse', 'Response object class');
    done_testing();
};

subtest 'finalize_mfa_sign_in method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.identitytoolkit.v2.AuthenticationService', 'Correct service path');
        is($args->{method}, 'FinalizeMfaSignIn', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Identitytoolkit::V2::AuthenticationService::FinalizeMfaSignInRequest', 'Request object');
        
        my $response = 'Google::Cloud::Identitytoolkit::V2::AuthenticationService::FinalizeMfaSignInResponse'->new();
        return $response;
    };
    
    my $res = $client->finalize_mfa_sign_in();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Identitytoolkit::V2::AuthenticationService::FinalizeMfaSignInResponse', 'Response object class');
    done_testing();
};

subtest 'start_mfa_sign_in method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.identitytoolkit.v2.AuthenticationService', 'Correct service path');
        is($args->{method}, 'StartMfaSignIn', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Identitytoolkit::V2::AuthenticationService::StartMfaSignInRequest', 'Request object');
        
        my $response = 'Google::Cloud::Identitytoolkit::V2::AuthenticationService::StartMfaSignInResponse'->new();
        return $response;
    };
    
    my $res = $client->start_mfa_sign_in();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Identitytoolkit::V2::AuthenticationService::StartMfaSignInResponse', 'Response object class');
    done_testing();
};

done_testing();
