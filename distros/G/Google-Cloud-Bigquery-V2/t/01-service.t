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
    my ($class, %args) = @_;
    return bless \%args, $class;
}
sub call {
    my ($self, $args) = @_;
    if ($self->{mock_call}) {
        return $self->{mock_call}->($args);
    }
    die 'No mock_call handler configured in transport!';
}

# C. Main test execution
package main;
use Google::Cloud::Bigquery::V2;

my $client = Google::Cloud::Bigquery::V2->new( credentials => 'dummy' );
ok($client, 'Instantiated generated client');
isa_ok($client->transport, 'Google::gRPC::Client', 'Client transport');

subtest 'get_routine method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.bigquery.v2.RoutineService', 'Correct service path');
        is($args->{method}, 'GetRoutine', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Bigquery::V2::Routine::GetRoutineRequest', 'Request object');
        
        my $response = 'Google::Cloud::Bigquery::V2::Routine::Routine'->new();
        return $response;
    };
    
    my $res = $client->get_routine();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Bigquery::V2::Routine::Routine', 'Response object class');
    done_testing();
};

subtest 'insert_routine method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.bigquery.v2.RoutineService', 'Correct service path');
        is($args->{method}, 'InsertRoutine', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Bigquery::V2::Routine::InsertRoutineRequest', 'Request object');
        
        my $response = 'Google::Cloud::Bigquery::V2::Routine::Routine'->new();
        return $response;
    };
    
    my $res = $client->insert_routine();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Bigquery::V2::Routine::Routine', 'Response object class');
    done_testing();
};

subtest 'update_routine method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.bigquery.v2.RoutineService', 'Correct service path');
        is($args->{method}, 'UpdateRoutine', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Bigquery::V2::Routine::UpdateRoutineRequest', 'Request object');
        
        my $response = 'Google::Cloud::Bigquery::V2::Routine::Routine'->new();
        return $response;
    };
    
    my $res = $client->update_routine();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Bigquery::V2::Routine::Routine', 'Response object class');
    done_testing();
};

subtest 'patch_routine method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.bigquery.v2.RoutineService', 'Correct service path');
        is($args->{method}, 'PatchRoutine', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Bigquery::V2::Routine::PatchRoutineRequest', 'Request object');
        
        my $response = 'Google::Cloud::Bigquery::V2::Routine::Routine'->new();
        return $response;
    };
    
    my $res = $client->patch_routine();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Bigquery::V2::Routine::Routine', 'Response object class');
    done_testing();
};

subtest 'delete_routine method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.bigquery.v2.RoutineService', 'Correct service path');
        is($args->{method}, 'DeleteRoutine', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Bigquery::V2::Routine::DeleteRoutineRequest', 'Request object');
        
        my $response = 'Google::Protobuf::Empty::Empty'->new();
        return $response;
    };
    
    my $res = $client->delete_routine();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Protobuf::Empty::Empty', 'Response object class');
    done_testing();
};

subtest 'list_routines method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.bigquery.v2.RoutineService', 'Correct service path');
        is($args->{method}, 'ListRoutines', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Bigquery::V2::Routine::ListRoutinesRequest', 'Request object');
        
        my $response = 'Google::Cloud::Bigquery::V2::Routine::ListRoutinesResponse'->new();
        return $response;
    };
    
    my $res = $client->list_routines();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Bigquery::V2::Routine::ListRoutinesResponse', 'Response object class');
    done_testing();
};

subtest 'list_projects method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.bigquery.v2.ProjectService', 'Correct service path');
        is($args->{method}, 'ListProjects', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Bigquery::V2::Project::ListProjectsRequest', 'Request object');
        
        my $response = 'Google::Cloud::Bigquery::V2::Project::ProjectList'->new();
        return $response;
    };
    
    my $res = $client->list_projects();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Bigquery::V2::Project::ProjectList', 'Response object class');
    done_testing();
};

subtest 'get_service_account method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.bigquery.v2.ProjectService', 'Correct service path');
        is($args->{method}, 'GetServiceAccount', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Bigquery::V2::Project::GetServiceAccountRequest', 'Request object');
        
        my $response = 'Google::Cloud::Bigquery::V2::Project::GetServiceAccountResponse'->new();
        return $response;
    };
    
    my $res = $client->get_service_account();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Bigquery::V2::Project::GetServiceAccountResponse', 'Response object class');
    done_testing();
};

subtest 'get_model method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.bigquery.v2.ModelService', 'Correct service path');
        is($args->{method}, 'GetModel', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Bigquery::V2::Model::GetModelRequest', 'Request object');
        
        my $response = 'Google::Cloud::Bigquery::V2::Model::Model'->new();
        return $response;
    };
    
    my $res = $client->get_model();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Bigquery::V2::Model::Model', 'Response object class');
    done_testing();
};

subtest 'list_models method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.bigquery.v2.ModelService', 'Correct service path');
        is($args->{method}, 'ListModels', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Bigquery::V2::Model::ListModelsRequest', 'Request object');
        
        my $response = 'Google::Cloud::Bigquery::V2::Model::ListModelsResponse'->new();
        return $response;
    };
    
    my $res = $client->list_models();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Bigquery::V2::Model::ListModelsResponse', 'Response object class');
    done_testing();
};

subtest 'patch_model method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.bigquery.v2.ModelService', 'Correct service path');
        is($args->{method}, 'PatchModel', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Bigquery::V2::Model::PatchModelRequest', 'Request object');
        
        my $response = 'Google::Cloud::Bigquery::V2::Model::Model'->new();
        return $response;
    };
    
    my $res = $client->patch_model();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Bigquery::V2::Model::Model', 'Response object class');
    done_testing();
};

subtest 'delete_model method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.bigquery.v2.ModelService', 'Correct service path');
        is($args->{method}, 'DeleteModel', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Bigquery::V2::Model::DeleteModelRequest', 'Request object');
        
        my $response = 'Google::Protobuf::Empty::Empty'->new();
        return $response;
    };
    
    my $res = $client->delete_model();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Protobuf::Empty::Empty', 'Response object class');
    done_testing();
};

subtest 'get_table method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.bigquery.v2.TableService', 'Correct service path');
        is($args->{method}, 'GetTable', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Bigquery::V2::Table::GetTableRequest', 'Request object');
        
        my $response = 'Google::Cloud::Bigquery::V2::Table::Table'->new();
        return $response;
    };
    
    my $res = $client->get_table();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Bigquery::V2::Table::Table', 'Response object class');
    done_testing();
};

subtest 'insert_table method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.bigquery.v2.TableService', 'Correct service path');
        is($args->{method}, 'InsertTable', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Bigquery::V2::Table::InsertTableRequest', 'Request object');
        
        my $response = 'Google::Cloud::Bigquery::V2::Table::Table'->new();
        return $response;
    };
    
    my $res = $client->insert_table();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Bigquery::V2::Table::Table', 'Response object class');
    done_testing();
};

subtest 'patch_table method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.bigquery.v2.TableService', 'Correct service path');
        is($args->{method}, 'PatchTable', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Bigquery::V2::Table::UpdateOrPatchTableRequest', 'Request object');
        
        my $response = 'Google::Cloud::Bigquery::V2::Table::Table'->new();
        return $response;
    };
    
    my $res = $client->patch_table();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Bigquery::V2::Table::Table', 'Response object class');
    done_testing();
};

subtest 'update_table method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.bigquery.v2.TableService', 'Correct service path');
        is($args->{method}, 'UpdateTable', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Bigquery::V2::Table::UpdateOrPatchTableRequest', 'Request object');
        
        my $response = 'Google::Cloud::Bigquery::V2::Table::Table'->new();
        return $response;
    };
    
    my $res = $client->update_table();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Bigquery::V2::Table::Table', 'Response object class');
    done_testing();
};

subtest 'delete_table method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.bigquery.v2.TableService', 'Correct service path');
        is($args->{method}, 'DeleteTable', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Bigquery::V2::Table::DeleteTableRequest', 'Request object');
        
        my $response = 'Google::Protobuf::Empty::Empty'->new();
        return $response;
    };
    
    my $res = $client->delete_table();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Protobuf::Empty::Empty', 'Response object class');
    done_testing();
};

subtest 'list_tables method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.bigquery.v2.TableService', 'Correct service path');
        is($args->{method}, 'ListTables', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Bigquery::V2::Table::ListTablesRequest', 'Request object');
        
        my $response = 'Google::Cloud::Bigquery::V2::Table::TableList'->new();
        return $response;
    };
    
    my $res = $client->list_tables();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Bigquery::V2::Table::TableList', 'Response object class');
    done_testing();
};

subtest 'get_property_graph method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.bigquery.v2.PropertyGraphService', 'Correct service path');
        is($args->{method}, 'GetPropertyGraph', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Bigquery::V2::PropertyGraph::GetPropertyGraphRequest', 'Request object');
        
        my $response = 'Google::Cloud::Bigquery::V2::PropertyGraph::PropertyGraph'->new();
        return $response;
    };
    
    my $res = $client->get_property_graph();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Bigquery::V2::PropertyGraph::PropertyGraph', 'Response object class');
    done_testing();
};

subtest 'list_property_graphs method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.bigquery.v2.PropertyGraphService', 'Correct service path');
        is($args->{method}, 'ListPropertyGraphs', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Bigquery::V2::PropertyGraph::ListPropertyGraphsRequest', 'Request object');
        
        my $response = 'Google::Cloud::Bigquery::V2::PropertyGraph::ListPropertyGraphsResponse'->new();
        return $response;
    };
    
    my $res = $client->list_property_graphs();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Bigquery::V2::PropertyGraph::ListPropertyGraphsResponse', 'Response object class');
    done_testing();
};

subtest 'delete_property_graph method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.bigquery.v2.PropertyGraphService', 'Correct service path');
        is($args->{method}, 'DeletePropertyGraph', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Bigquery::V2::PropertyGraph::DeletePropertyGraphRequest', 'Request object');
        
        my $response = 'Google::Protobuf::Empty::Empty'->new();
        return $response;
    };
    
    my $res = $client->delete_property_graph();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Protobuf::Empty::Empty', 'Response object class');
    done_testing();
};

subtest 'cancel_job method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.bigquery.v2.JobService', 'Correct service path');
        is($args->{method}, 'CancelJob', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Bigquery::V2::Job::CancelJobRequest', 'Request object');
        
        my $response = 'Google::Cloud::Bigquery::V2::Job::JobCancelResponse'->new();
        return $response;
    };
    
    my $res = $client->cancel_job();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Bigquery::V2::Job::JobCancelResponse', 'Response object class');
    done_testing();
};

subtest 'get_job method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.bigquery.v2.JobService', 'Correct service path');
        is($args->{method}, 'GetJob', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Bigquery::V2::Job::GetJobRequest', 'Request object');
        
        my $response = 'Google::Cloud::Bigquery::V2::Job::Job'->new();
        return $response;
    };
    
    my $res = $client->get_job();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Bigquery::V2::Job::Job', 'Response object class');
    done_testing();
};

subtest 'insert_job method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.bigquery.v2.JobService', 'Correct service path');
        is($args->{method}, 'InsertJob', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Bigquery::V2::Job::InsertJobRequest', 'Request object');
        
        my $response = 'Google::Cloud::Bigquery::V2::Job::Job'->new();
        return $response;
    };
    
    my $res = $client->insert_job();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Bigquery::V2::Job::Job', 'Response object class');
    done_testing();
};

subtest 'update_job method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.bigquery.v2.JobService', 'Correct service path');
        is($args->{method}, 'UpdateJob', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Bigquery::V2::Job::UpdateJobRequest', 'Request object');
        
        my $response = 'Google::Cloud::Bigquery::V2::Job::Job'->new();
        return $response;
    };
    
    my $res = $client->update_job();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Bigquery::V2::Job::Job', 'Response object class');
    done_testing();
};

subtest 'delete_job method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.bigquery.v2.JobService', 'Correct service path');
        is($args->{method}, 'DeleteJob', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Bigquery::V2::Job::DeleteJobRequest', 'Request object');
        
        my $response = 'Google::Protobuf::Empty::Empty'->new();
        return $response;
    };
    
    my $res = $client->delete_job();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Protobuf::Empty::Empty', 'Response object class');
    done_testing();
};

subtest 'list_jobs method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.bigquery.v2.JobService', 'Correct service path');
        is($args->{method}, 'ListJobs', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Bigquery::V2::Job::ListJobsRequest', 'Request object');
        
        my $response = 'Google::Cloud::Bigquery::V2::Job::JobList'->new();
        return $response;
    };
    
    my $res = $client->list_jobs();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Bigquery::V2::Job::JobList', 'Response object class');
    done_testing();
};

subtest 'get_query_results method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.bigquery.v2.JobService', 'Correct service path');
        is($args->{method}, 'GetQueryResults', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Bigquery::V2::Job::GetQueryResultsRequest', 'Request object');
        
        my $response = 'Google::Cloud::Bigquery::V2::Job::GetQueryResultsResponse'->new();
        return $response;
    };
    
    my $res = $client->get_query_results();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Bigquery::V2::Job::GetQueryResultsResponse', 'Response object class');
    done_testing();
};

subtest 'query method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.bigquery.v2.JobService', 'Correct service path');
        is($args->{method}, 'Query', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Bigquery::V2::Job::PostQueryRequest', 'Request object');
        
        my $response = 'Google::Cloud::Bigquery::V2::Job::QueryResponse'->new();
        return $response;
    };
    
    my $res = $client->query();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Bigquery::V2::Job::QueryResponse', 'Response object class');
    done_testing();
};

subtest 'insert_all method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.bigquery.v2.TableDataService', 'Correct service path');
        is($args->{method}, 'InsertAll', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Bigquery::V2::Tabledata::TableDataInsertAllRequest', 'Request object');
        
        my $response = 'Google::Cloud::Bigquery::V2::Tabledata::TableDataInsertAllResponse'->new();
        return $response;
    };
    
    my $res = $client->insert_all();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Bigquery::V2::Tabledata::TableDataInsertAllResponse', 'Response object class');
    done_testing();
};

subtest 'list method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.bigquery.v2.TableDataService', 'Correct service path');
        is($args->{method}, 'List', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Bigquery::V2::Tabledata::TableDataListRequest', 'Request object');
        
        my $response = 'Google::Cloud::Bigquery::V2::Tabledata::TableDataList'->new();
        return $response;
    };
    
    my $res = $client->list();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Bigquery::V2::Tabledata::TableDataList', 'Response object class');
    done_testing();
};

subtest 'get_dataset method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.bigquery.v2.DatasetService', 'Correct service path');
        is($args->{method}, 'GetDataset', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Bigquery::V2::Dataset::GetDatasetRequest', 'Request object');
        
        my $response = 'Google::Cloud::Bigquery::V2::Dataset::Dataset'->new();
        return $response;
    };
    
    my $res = $client->get_dataset();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Bigquery::V2::Dataset::Dataset', 'Response object class');
    done_testing();
};

subtest 'insert_dataset method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.bigquery.v2.DatasetService', 'Correct service path');
        is($args->{method}, 'InsertDataset', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Bigquery::V2::Dataset::InsertDatasetRequest', 'Request object');
        
        my $response = 'Google::Cloud::Bigquery::V2::Dataset::Dataset'->new();
        return $response;
    };
    
    my $res = $client->insert_dataset();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Bigquery::V2::Dataset::Dataset', 'Response object class');
    done_testing();
};

subtest 'patch_dataset method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.bigquery.v2.DatasetService', 'Correct service path');
        is($args->{method}, 'PatchDataset', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Bigquery::V2::Dataset::UpdateOrPatchDatasetRequest', 'Request object');
        
        my $response = 'Google::Cloud::Bigquery::V2::Dataset::Dataset'->new();
        return $response;
    };
    
    my $res = $client->patch_dataset();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Bigquery::V2::Dataset::Dataset', 'Response object class');
    done_testing();
};

subtest 'update_dataset method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.bigquery.v2.DatasetService', 'Correct service path');
        is($args->{method}, 'UpdateDataset', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Bigquery::V2::Dataset::UpdateOrPatchDatasetRequest', 'Request object');
        
        my $response = 'Google::Cloud::Bigquery::V2::Dataset::Dataset'->new();
        return $response;
    };
    
    my $res = $client->update_dataset();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Bigquery::V2::Dataset::Dataset', 'Response object class');
    done_testing();
};

subtest 'delete_dataset method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.bigquery.v2.DatasetService', 'Correct service path');
        is($args->{method}, 'DeleteDataset', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Bigquery::V2::Dataset::DeleteDatasetRequest', 'Request object');
        
        my $response = 'Google::Protobuf::Empty::Empty'->new();
        return $response;
    };
    
    my $res = $client->delete_dataset();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Protobuf::Empty::Empty', 'Response object class');
    done_testing();
};

subtest 'list_datasets method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.bigquery.v2.DatasetService', 'Correct service path');
        is($args->{method}, 'ListDatasets', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Bigquery::V2::Dataset::ListDatasetsRequest', 'Request object');
        
        my $response = 'Google::Cloud::Bigquery::V2::Dataset::DatasetList'->new();
        return $response;
    };
    
    my $res = $client->list_datasets();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Bigquery::V2::Dataset::DatasetList', 'Response object class');
    done_testing();
};

subtest 'undelete_dataset method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.bigquery.v2.DatasetService', 'Correct service path');
        is($args->{method}, 'UndeleteDataset', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Bigquery::V2::Dataset::UndeleteDatasetRequest', 'Request object');
        
        my $response = 'Google::Cloud::Bigquery::V2::Dataset::Dataset'->new();
        return $response;
    };
    
    my $res = $client->undelete_dataset();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Bigquery::V2::Dataset::Dataset', 'Response object class');
    done_testing();
};

subtest 'list_row_access_policies method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.bigquery.v2.RowAccessPolicyService', 'Correct service path');
        is($args->{method}, 'ListRowAccessPolicies', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Bigquery::V2::RowAccessPolicy::ListRowAccessPoliciesRequest', 'Request object');
        
        my $response = 'Google::Cloud::Bigquery::V2::RowAccessPolicy::ListRowAccessPoliciesResponse'->new();
        return $response;
    };
    
    my $res = $client->list_row_access_policies();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Bigquery::V2::RowAccessPolicy::ListRowAccessPoliciesResponse', 'Response object class');
    done_testing();
};

subtest 'get_row_access_policy method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.bigquery.v2.RowAccessPolicyService', 'Correct service path');
        is($args->{method}, 'GetRowAccessPolicy', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Bigquery::V2::RowAccessPolicy::GetRowAccessPolicyRequest', 'Request object');
        
        my $response = 'Google::Cloud::Bigquery::V2::RowAccessPolicy::RowAccessPolicy'->new();
        return $response;
    };
    
    my $res = $client->get_row_access_policy();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Bigquery::V2::RowAccessPolicy::RowAccessPolicy', 'Response object class');
    done_testing();
};

subtest 'create_row_access_policy method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.bigquery.v2.RowAccessPolicyService', 'Correct service path');
        is($args->{method}, 'CreateRowAccessPolicy', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Bigquery::V2::RowAccessPolicy::CreateRowAccessPolicyRequest', 'Request object');
        
        my $response = 'Google::Cloud::Bigquery::V2::RowAccessPolicy::RowAccessPolicy'->new();
        return $response;
    };
    
    my $res = $client->create_row_access_policy();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Bigquery::V2::RowAccessPolicy::RowAccessPolicy', 'Response object class');
    done_testing();
};

subtest 'update_row_access_policy method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.bigquery.v2.RowAccessPolicyService', 'Correct service path');
        is($args->{method}, 'UpdateRowAccessPolicy', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Bigquery::V2::RowAccessPolicy::UpdateRowAccessPolicyRequest', 'Request object');
        
        my $response = 'Google::Cloud::Bigquery::V2::RowAccessPolicy::RowAccessPolicy'->new();
        return $response;
    };
    
    my $res = $client->update_row_access_policy();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Cloud::Bigquery::V2::RowAccessPolicy::RowAccessPolicy', 'Response object class');
    done_testing();
};

subtest 'delete_row_access_policy method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.bigquery.v2.RowAccessPolicyService', 'Correct service path');
        is($args->{method}, 'DeleteRowAccessPolicy', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Bigquery::V2::RowAccessPolicy::DeleteRowAccessPolicyRequest', 'Request object');
        
        my $response = 'Google::Protobuf::Empty::Empty'->new();
        return $response;
    };
    
    my $res = $client->delete_row_access_policy();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Protobuf::Empty::Empty', 'Response object class');
    done_testing();
};

subtest 'batch_delete_row_access_policies method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.bigquery.v2.RowAccessPolicyService', 'Correct service path');
        is($args->{method}, 'BatchDeleteRowAccessPolicies', 'Correct RPC method');
        isa_ok($args->{request}, 'Google::Cloud::Bigquery::V2::RowAccessPolicy::BatchDeleteRowAccessPoliciesRequest', 'Request object');
        
        my $response = 'Google::Protobuf::Empty::Empty'->new();
        return $response;
    };
    
    my $res = $client->batch_delete_row_access_policies();
    ok($res, 'Method returned a response');
    isa_ok($res, 'Google::Protobuf::Empty::Empty', 'Response object class');
    done_testing();
};

done_testing();
