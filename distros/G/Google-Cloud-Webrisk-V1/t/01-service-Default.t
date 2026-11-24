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
    for my $pkg (qw( Google::Cloud::Webrisk::V1::Webrisk::ComputeThreatListDiffResponse Google::Cloud::Webrisk::V1::Webrisk::SearchHashesResponse Google::Cloud::Webrisk::V1::Webrisk::SearchUrisResponse Google::Cloud::Webrisk::V1::Webrisk::Submission Google::Longrunning::Operations::Operation )) {
        unless ($pkg->can('new')) {
            no strict 'refs';
            *{"${pkg}::new"} = sub { bless {}, $_[0] };
            $INC{join('/', split('::', $pkg)) . '.pm'} = 1;
        }
    }
}

# D. Main test execution
package main;
use Google::Cloud::Webrisk::V1;

my $client = Google::Cloud::Webrisk::V1->new();
ok($client, 'Instantiated generated client');
isa_ok($client->transport, 'Google::gRPC::Client', 'Client transport');

subtest 'compute_threat_list_diff method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.webrisk.v1.WebRiskService', 'Correct service path');
        is($args->{method}, 'ComputeThreatListDiff', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Webrisk::V1::Webrisk::ComputeThreatListDiffRequest', 'Request object');
        
        my $response = 'Google::Cloud::Webrisk::V1::Webrisk::ComputeThreatListDiffResponse'->new();
        return $response;
    };
    
    my $res = $client->compute_threat_list_diff();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Webrisk::V1::Webrisk::ComputeThreatListDiffResponse', 'Response object class');
    done_testing();
};

subtest 'search_uris method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.webrisk.v1.WebRiskService', 'Correct service path');
        is($args->{method}, 'SearchUris', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Webrisk::V1::Webrisk::SearchUrisRequest', 'Request object');
        
        my $response = 'Google::Cloud::Webrisk::V1::Webrisk::SearchUrisResponse'->new();
        return $response;
    };
    
    my $res = $client->search_uris();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Webrisk::V1::Webrisk::SearchUrisResponse', 'Response object class');
    done_testing();
};

subtest 'search_hashes method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.webrisk.v1.WebRiskService', 'Correct service path');
        is($args->{method}, 'SearchHashes', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Webrisk::V1::Webrisk::SearchHashesRequest', 'Request object');
        
        my $response = 'Google::Cloud::Webrisk::V1::Webrisk::SearchHashesResponse'->new();
        return $response;
    };
    
    my $res = $client->search_hashes();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Webrisk::V1::Webrisk::SearchHashesResponse', 'Response object class');
    done_testing();
};

subtest 'create_submission method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.webrisk.v1.WebRiskService', 'Correct service path');
        is($args->{method}, 'CreateSubmission', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Webrisk::V1::Webrisk::CreateSubmissionRequest', 'Request object');
        
        my $response = 'Google::Cloud::Webrisk::V1::Webrisk::Submission'->new();
        return $response;
    };
    
    my $res = $client->create_submission();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Webrisk::V1::Webrisk::Submission', 'Response object class');
    done_testing();
};

subtest 'submit_uri method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.webrisk.v1.WebRiskService', 'Correct service path');
        is($args->{method}, 'SubmitUri', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Webrisk::V1::Webrisk::SubmitUriRequest', 'Request object');
        
        my $response = 'Google::Longrunning::Operations::Operation'->new();
        return $response;
    };
    
    my $res = $client->submit_uri();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Longrunning::Operations::Operation', 'Response object class');
    done_testing();
};

done_testing();
