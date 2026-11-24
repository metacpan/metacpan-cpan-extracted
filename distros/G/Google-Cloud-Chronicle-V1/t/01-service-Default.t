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
    for my $pkg (qw( Google::Cloud::Chronicle::V1::BigQueryExport::BigQueryExport Google::Cloud::Chronicle::V1::DashboardChart::DashboardChart Google::Cloud::Chronicle::V1::DashboardQuery::DashboardQuery Google::Cloud::Chronicle::V1::DataAccessControl::DataAccessLabel Google::Cloud::Chronicle::V1::DataTable::DataTable Google::Cloud::Chronicle::V1::Entity::Watchlist Google::Cloud::Chronicle::V1::FeaturedContentNativeDashboard::FeaturedContentNativeDashboard Google::Cloud::Chronicle::V1::FeaturedContentNativeDashboard::InstallFeaturedContentNativeDashboardResponse Google::Cloud::Chronicle::V1::Feed::FeedServiceAccount Google::Cloud::Chronicle::V1::FindingsRefinement::FindingsRefinement Google::Cloud::Chronicle::V1::Instance::Instance Google::Cloud::Chronicle::V1::NativeDashboard::NativeDashboard Google::Cloud::Chronicle::V1::ReferenceList::ReferenceList Google::Cloud::Chronicle::V1::Rule::Rule Google::Cloud::Chronicle::V1::RuleExecutionError::ListRuleExecutionErrorsResponse Google::Longrunning::Operations::Operation )) {
        unless ($pkg->can('new')) {
            no strict 'refs';
            *{"${pkg}::new"} = sub { bless {}, $_[0] };
            $INC{join('/', split('::', $pkg)) . '.pm'} = 1;
        }
    }
}

# D. Main test execution
package main;
use Google::Cloud::Chronicle::V1;

my $client = Google::Cloud::Chronicle::V1->new();
ok($client, 'Instantiated generated client');
isa_ok($client->transport, 'Google::gRPC::Client', 'Client transport');

subtest 'get_big_query_export method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.chronicle.v1.BigQueryExportService', 'Correct service path');
        is($args->{method}, 'GetBigQueryExport', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Chronicle::V1::BigQueryExport::GetBigQueryExportRequest', 'Request object');
        
        my $response = 'Google::Cloud::Chronicle::V1::BigQueryExport::BigQueryExport'->new();
        return $response;
    };
    
    my $res = $client->get_big_query_export();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Chronicle::V1::BigQueryExport::BigQueryExport', 'Response object class');
    done_testing();
};

subtest 'provision_big_query_export method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.chronicle.v1.BigQueryExportService', 'Correct service path');
        is($args->{method}, 'ProvisionBigQueryExport', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Chronicle::V1::BigQueryExport::ProvisionBigQueryExportRequest', 'Request object');
        
        my $response = 'Google::Cloud::Chronicle::V1::BigQueryExport::BigQueryExport'->new();
        return $response;
    };
    
    my $res = $client->provision_big_query_export();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Chronicle::V1::BigQueryExport::BigQueryExport', 'Response object class');
    done_testing();
};

subtest 'get_dashboard_chart method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.chronicle.v1.DashboardChartService', 'Correct service path');
        is($args->{method}, 'GetDashboardChart', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Chronicle::V1::DashboardChart::GetDashboardChartRequest', 'Request object');
        
        my $response = 'Google::Cloud::Chronicle::V1::DashboardChart::DashboardChart'->new();
        return $response;
    };
    
    my $res = $client->get_dashboard_chart();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Chronicle::V1::DashboardChart::DashboardChart', 'Response object class');
    done_testing();
};

subtest 'get_dashboard_query method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.chronicle.v1.DashboardQueryService', 'Correct service path');
        is($args->{method}, 'GetDashboardQuery', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Chronicle::V1::DashboardQuery::GetDashboardQueryRequest', 'Request object');
        
        my $response = 'Google::Cloud::Chronicle::V1::DashboardQuery::DashboardQuery'->new();
        return $response;
    };
    
    my $res = $client->get_dashboard_query();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Chronicle::V1::DashboardQuery::DashboardQuery', 'Response object class');
    done_testing();
};

subtest 'create_data_access_label method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.chronicle.v1.DataAccessControlService', 'Correct service path');
        is($args->{method}, 'CreateDataAccessLabel', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Chronicle::V1::DataAccessControl::CreateDataAccessLabelRequest', 'Request object');
        
        my $response = 'Google::Cloud::Chronicle::V1::DataAccessControl::DataAccessLabel'->new();
        return $response;
    };
    
    my $res = $client->create_data_access_label();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Chronicle::V1::DataAccessControl::DataAccessLabel', 'Response object class');
    done_testing();
};

subtest 'create_data_table method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.chronicle.v1.DataTableService', 'Correct service path');
        is($args->{method}, 'CreateDataTable', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Chronicle::V1::DataTable::CreateDataTableRequest', 'Request object');
        
        my $response = 'Google::Cloud::Chronicle::V1::DataTable::DataTable'->new();
        return $response;
    };
    
    my $res = $client->create_data_table();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Chronicle::V1::DataTable::DataTable', 'Response object class');
    done_testing();
};

subtest 'get_watchlist method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.chronicle.v1.EntityService', 'Correct service path');
        is($args->{method}, 'GetWatchlist', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Chronicle::V1::Entity::GetWatchlistRequest', 'Request object');
        
        my $response = 'Google::Cloud::Chronicle::V1::Entity::Watchlist'->new();
        return $response;
    };
    
    my $res = $client->get_watchlist();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Chronicle::V1::Entity::Watchlist', 'Response object class');
    done_testing();
};

subtest 'get_featured_content_native_dashboard method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.chronicle.v1.FeaturedContentNativeDashboardService', 'Correct service path');
        is($args->{method}, 'GetFeaturedContentNativeDashboard', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Chronicle::V1::FeaturedContentNativeDashboard::GetFeaturedContentNativeDashboardRequest', 'Request object');
        
        my $response = 'Google::Cloud::Chronicle::V1::FeaturedContentNativeDashboard::FeaturedContentNativeDashboard'->new();
        return $response;
    };
    
    my $res = $client->get_featured_content_native_dashboard();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Chronicle::V1::FeaturedContentNativeDashboard::FeaturedContentNativeDashboard', 'Response object class');
    done_testing();
};

subtest 'install_featured_content_native_dashboard method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.chronicle.v1.FeaturedContentNativeDashboardService', 'Correct service path');
        is($args->{method}, 'InstallFeaturedContentNativeDashboard', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Chronicle::V1::FeaturedContentNativeDashboard::InstallFeaturedContentNativeDashboardRequest', 'Request object');
        
        my $response = 'Google::Cloud::Chronicle::V1::FeaturedContentNativeDashboard::InstallFeaturedContentNativeDashboardResponse'->new();
        return $response;
    };
    
    my $res = $client->install_featured_content_native_dashboard();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Chronicle::V1::FeaturedContentNativeDashboard::InstallFeaturedContentNativeDashboardResponse', 'Response object class');
    done_testing();
};

subtest 'fetch_service_account_for_customer method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.chronicle.v1.FeedsService', 'Correct service path');
        is($args->{method}, 'FetchServiceAccountForCustomer', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Chronicle::V1::Feed::FetchServiceAccountForCustomerRequest', 'Request object');
        
        my $response = 'Google::Cloud::Chronicle::V1::Feed::FeedServiceAccount'->new();
        return $response;
    };
    
    my $res = $client->fetch_service_account_for_customer();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Chronicle::V1::Feed::FeedServiceAccount', 'Response object class');
    done_testing();
};

subtest 'get_findings_refinement method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.chronicle.v1.FindingsRefinementService', 'Correct service path');
        is($args->{method}, 'GetFindingsRefinement', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Chronicle::V1::FindingsRefinement::GetFindingsRefinementRequest', 'Request object');
        
        my $response = 'Google::Cloud::Chronicle::V1::FindingsRefinement::FindingsRefinement'->new();
        return $response;
    };
    
    my $res = $client->get_findings_refinement();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Chronicle::V1::FindingsRefinement::FindingsRefinement', 'Response object class');
    done_testing();
};

subtest 'get_instance method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.chronicle.v1.InstanceService', 'Correct service path');
        is($args->{method}, 'GetInstance', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Chronicle::V1::Instance::GetInstanceRequest', 'Request object');
        
        my $response = 'Google::Cloud::Chronicle::V1::Instance::Instance'->new();
        return $response;
    };
    
    my $res = $client->get_instance();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Chronicle::V1::Instance::Instance', 'Response object class');
    done_testing();
};

subtest 'create_native_dashboard method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.chronicle.v1.NativeDashboardService', 'Correct service path');
        is($args->{method}, 'CreateNativeDashboard', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Chronicle::V1::NativeDashboard::CreateNativeDashboardRequest', 'Request object');
        
        my $response = 'Google::Cloud::Chronicle::V1::NativeDashboard::NativeDashboard'->new();
        return $response;
    };
    
    my $res = $client->create_native_dashboard();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Chronicle::V1::NativeDashboard::NativeDashboard', 'Response object class');
    done_testing();
};

subtest 'get_reference_list method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.chronicle.v1.ReferenceListService', 'Correct service path');
        is($args->{method}, 'GetReferenceList', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Chronicle::V1::ReferenceList::GetReferenceListRequest', 'Request object');
        
        my $response = 'Google::Cloud::Chronicle::V1::ReferenceList::ReferenceList'->new();
        return $response;
    };
    
    my $res = $client->get_reference_list();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Chronicle::V1::ReferenceList::ReferenceList', 'Response object class');
    done_testing();
};

subtest 'create_rule method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.chronicle.v1.RuleService', 'Correct service path');
        is($args->{method}, 'CreateRule', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Chronicle::V1::Rule::CreateRuleRequest', 'Request object');
        
        my $response = 'Google::Cloud::Chronicle::V1::Rule::Rule'->new();
        return $response;
    };
    
    my $res = $client->create_rule();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Chronicle::V1::Rule::Rule', 'Response object class');
    done_testing();
};

subtest 'list_rule_execution_errors method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.chronicle.v1.RuleExecutionErrorService', 'Correct service path');
        is($args->{method}, 'ListRuleExecutionErrors', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Chronicle::V1::RuleExecutionError::ListRuleExecutionErrorsRequest', 'Request object');
        
        my $response = 'Google::Cloud::Chronicle::V1::RuleExecutionError::ListRuleExecutionErrorsResponse'->new();
        return $response;
    };
    
    my $res = $client->list_rule_execution_errors();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Chronicle::V1::RuleExecutionError::ListRuleExecutionErrorsResponse', 'Response object class');
    done_testing();
};

subtest 'search method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.chronicle.v1.SearchService', 'Correct service path');
        is($args->{method}, 'Search', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Chronicle::V1::Search::SearchRequest', 'Request object');
        
        my $response = 'Google::Longrunning::Operations::Operation'->new();
        return $response;
    };
    
    my $res = $client->search();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Longrunning::Operations::Operation', 'Response object class');
    done_testing();
};

done_testing();
