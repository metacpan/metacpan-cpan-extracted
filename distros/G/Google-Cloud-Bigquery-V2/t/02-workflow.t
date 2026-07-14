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
use strict;
use warnings;
use Google::Cloud::Bigquery::V2;
use Google::Cloud::Bigquery::V2::DatasetReference;
use Google::Cloud::Bigquery::V2::Dataset;
use Google::Cloud::Bigquery::V2::TableReference;
use Google::Cloud::Bigquery::V2::Table;
use Google::Cloud::Bigquery::V2::TableSchema;
use Google::Cloud::Bigquery::V2::Job;
use Google::Protobuf::Wrappers;
use Google::Protobuf::Struct;

my $project_id = 'perl-cloud-ci';
my $dataset_id = 'cjac_perl_test_dataset_123';
my $table_id   = 'cjac_perl_test_table';

# Helper function to extract the active value from a Google::Protobuf::Struct::Value object
sub get_raw_value {
    my ($val) = @_;
    return undef if !$val;
    my $kind = $val->kind();
    if ($kind eq 'number_value') {
        return $val->number_value();
    } elsif ($kind eq 'string_value') {
        return $val->string_value();
    } elsif ($kind eq 'bool_value') {
        return $val->bool_value();
    } elsif ($kind eq 'null_value') {
        return undef;
    } elsif ($kind eq 'struct_value') {
        return $val->struct_value();
    } elsif ($kind eq 'list_value') {
        return $val->list_value();
    }
    return undef;
}

# Helper function to parse BigQuery cell value from nested { v => value } Struct structure
sub get_cell_value {
    my ($cell_val) = @_;
    my $raw_cell = get_raw_value($cell_val);
    if ($raw_cell && $raw_cell->can('fields')) {
        my $fields = $raw_cell->fields();
        if ($fields && $fields->{v}) {
            return get_raw_value($fields->{v});
        }
    }
    return undef;
}

# Initialize the client
my $bq = Google::Cloud::Bigquery::V2->new( credentials => 'dummy' );
ok($bq, 'Instantiated BigQuery client');

# Step 1: Create Dataset
subtest 'Step 1: Create Dataset' => sub {
    $bq->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.bigquery.v2.DatasetService', 'Correct service path');
        is($args->{method}, 'InsertDataset', 'Correct RPC method');
        is($args->{request}->project_id(), $project_id, 'Correct project_id');
        
        my $dataset = $args->{request}->dataset();
        ok($dataset, 'Dataset object present in request');
        is($dataset->dataset_reference()->dataset_id(), $dataset_id, 'Correct dataset_id in reference');
        
        # Return mock dataset response
        return 'Google::Cloud::Bigquery::V2::Dataset::Dataset'->new(
            id => "$project_id:$dataset_id",
        );
    };
    
    my $dataset_ref = Google::Cloud::Bigquery::V2::DatasetReference::DatasetReference->new(
        project_id => $project_id,
        dataset_id => $dataset_id,
    );
    my $dataset = Google::Cloud::Bigquery::V2::Dataset::Dataset->new(
        dataset_reference => $dataset_ref,
        location          => 'US',
    );
    
    my $res = $bq->insert_dataset(
        project_id => $project_id,
        dataset    => $dataset,
    );
    ok($res, 'insert_dataset returned response');
    is($res->id(), "$project_id:$dataset_id", 'Correct dataset ID in response');
    done_testing();
};

# Step 2: Create Table
subtest 'Step 2: Create Table' => sub {
    $bq->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.bigquery.v2.TableService', 'Correct service path');
        is($args->{method}, 'InsertTable', 'Correct RPC method');
        is($args->{request}->project_id(), $project_id, 'Correct project_id');
        is($args->{request}->dataset_id(), $dataset_id, 'Correct dataset_id');
        
        my $table = $args->{request}->table();
        ok($table, 'Table object present in request');
        is($table->table_reference()->table_id(), $table_id, 'Correct table_id in reference');
        
        # Return mock table response
        return 'Google::Cloud::Bigquery::V2::Table::Table'->new(
            id => "$project_id:$dataset_id.$table_id",
        );
    };
    
    my $table_ref = Google::Cloud::Bigquery::V2::TableReference::TableReference->new(
        project_id => $project_id,
        dataset_id => $dataset_id,
        table_id   => $table_id,
    );
    my $field_id = Google::Cloud::Bigquery::V2::TableSchema::TableFieldSchema->new(
        name => 'id',
        type => 'INTEGER',
        mode => 'REQUIRED',
    );
    my $field_name = Google::Cloud::Bigquery::V2::TableSchema::TableFieldSchema->new(
        name => 'name',
        type => 'STRING',
        mode => 'NULLABLE',
    );
    my $schema = Google::Cloud::Bigquery::V2::TableSchema::TableSchema->new(
        fields => [ $field_id, $field_name ],
    );
    my $table = Google::Cloud::Bigquery::V2::Table::Table->new(
        table_reference => $table_ref,
        schema          => $schema,
    );
    
    my $res = $bq->insert_table(
        project_id => $project_id,
        dataset_id => $dataset_id,
        table      => $table,
    );
    ok($res, 'insert_table returned response');
    is($res->id(), "$project_id:$dataset_id.$table_id", 'Correct table ID in response');
    done_testing();
};

# Step 3: Populate Table (DML Insert)
subtest 'Step 3: Populate Table (DML)' => sub {
    $bq->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.bigquery.v2.JobService', 'Correct service path');
        is($args->{method}, 'Query', 'Correct RPC method');
        is($args->{request}->project_id(), $project_id, 'Correct project_id');
        
        my $query_req = $args->{request}->query_request();
        ok($query_req, 'QueryRequest present in request');
        like($query_req->query(), qr/INSERT INTO/i, 'Query is an INSERT statement');
        ok(!$query_req->use_legacy_sql()->value(), 'use_legacy_sql is false');
        
        # Return mock query response with affected rows wrapper
        my $affected = Google::Protobuf::Wrappers::Int64Value->new(value => 3);
        return 'Google::Cloud::Bigquery::V2::Job::QueryResponse'->new(
            num_dml_affected_rows => $affected,
        );
    };
    
    my $insert_sql = "INSERT INTO `$project_id.$dataset_id.$table_id` (id, name) VALUES "
                   . "(1, 'Alice'), (2, 'Bob'), (3, 'Charlie')";
    my $use_legacy = Google::Protobuf::Wrappers::BoolValue->new( value => 0 );
    my $query_req = Google::Cloud::Bigquery::V2::Job::QueryRequest->new(
        query          => $insert_sql,
        use_legacy_sql => $use_legacy,
    );
    
    my $res = $bq->query(
        project_id    => $project_id,
        query_request => $query_req,
    );
    ok($res, 'query returned response');
    is($res->num_dml_affected_rows()->value(), 3, 'Correct DML affected rows in response');
    done_testing();
};

# Step 4: Count Rows
subtest 'Step 4: Count Rows' => sub {
    $bq->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.bigquery.v2.JobService', 'Correct service path');
        is($args->{method}, 'Query', 'Correct RPC method');
        
        my $query_req = $args->{request}->query_request();
        like($query_req->query(), qr/SELECT COUNT/i, 'Query is a SELECT COUNT statement');
        
        # Construct mock Struct response row: [ { v => '3' } ] using WKT from_perl helper
        my $row_struct = Google::Protobuf::Struct::Struct->new()->from_perl({
            f => [ { v => '3' } ]
        });
        
        return 'Google::Cloud::Bigquery::V2::Job::QueryResponse'->new(
            rows => [$row_struct],
        );
    };
    
    my $count_sql = "SELECT COUNT(*) as cnt FROM `$project_id.$dataset_id.$table_id`";
    my $use_legacy = Google::Protobuf::Wrappers::BoolValue->new( value => 0 );
    my $query_req = Google::Cloud::Bigquery::V2::Job::QueryRequest->new(
        query          => $count_sql,
        use_legacy_sql => $use_legacy,
    );
    
    my $res = $bq->query(
        project_id    => $project_id,
        query_request => $query_req,
    );
    ok($res, 'query returned response');
    ok($res->rows() && @{$res->rows()} == 1, 'Returned exactly 1 row');
    
    # Parse count using helper functions
    my $total_rows = 0;
    my $row = $res->rows()->[0];
    my $fields = $row->fields();
    if ($fields && $fields->{f}) {
        my $list = get_raw_value($fields->{f});
        if ($list && $list->can('values')) {
            my $cells = $list->values();
            if ($cells && @$cells) {
                $total_rows = get_cell_value($cells->[0]) // 0;
            }
        }
    }
    is($total_rows, 3, 'Correctly parsed row count of 3');
    done_testing();
};

# Step 5: Select Rows
subtest 'Step 5: Select Rows' => sub {
    $bq->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.bigquery.v2.JobService', 'Correct service path');
        is($args->{method}, 'Query', 'Correct RPC method');
        
        my $query_req = $args->{request}->query_request();
        like($query_req->query(), qr/SELECT id, name/i, 'Query is a SELECT id, name statement');
        
        # Construct mock Struct response rows using WKT from_perl helper
        my $r1 = Google::Protobuf::Struct::Struct->new()->from_perl({ f => [ { v => 1 }, { v => 'Alice' } ] });
        my $r2 = Google::Protobuf::Struct::Struct->new()->from_perl({ f => [ { v => 2 }, { v => 'Bob' } ] });
        my $r3 = Google::Protobuf::Struct::Struct->new()->from_perl({ f => [ { v => 3 }, { v => 'Charlie' } ] });
        
        return 'Google::Cloud::Bigquery::V2::Job::QueryResponse'->new(
            rows => [$r1, $r2, $r3],
        );
    };
    
    my $select_sql = "SELECT id, name FROM `$project_id.$dataset_id.$table_id` ORDER BY id ASC";
    my $use_legacy = Google::Protobuf::Wrappers::BoolValue->new( value => 0 );
    my $query_req = Google::Cloud::Bigquery::V2::Job::QueryRequest->new(
        query          => $select_sql,
        use_legacy_sql => $use_legacy,
    );
    
    my $res = $bq->query(
        project_id    => $project_id,
        query_request => $query_req,
    );
    ok($res, 'query returned response');
    ok($res->rows() && @{$res->rows()} == 3, 'Returned exactly 3 rows');
    
    my @parsed;
    foreach my $row (@{$res->rows()}) {
        my $fields = $row->fields();
        if ($fields && $fields->{f}) {
            my $list = get_raw_value($fields->{f});
            if ($list && $list->can('values')) {
                my $cells = $list->values();
                if ($cells && scalar(@$cells) >= 2) {
                    my $id = get_cell_value($cells->[0]);
                    my $name = get_cell_value($cells->[1]);
                    push @parsed, { id => $id, name => $name };
                }
            }
        }
    }
    
    is_deeply(\@parsed, [
        { id => 1, name => 'Alice' },
        { id => 2, name => 'Bob' },
        { id => 3, name => 'Charlie' },
    ], 'Correctly parsed all 3 rows and cell values!');
    done_testing();
};

# Step 6: Clean Up (Delete Table and Dataset)
subtest 'Step 6: Clean Up' => sub {
    # Delete Table
    $bq->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.bigquery.v2.TableService', 'Correct service path');
        is($args->{method}, 'DeleteTable', 'Correct RPC method');
        is($args->{request}->table_id(), $table_id, 'Correct table_id');
        return 'Google::Protobuf::Empty::Empty'->new();
    };
    my $del_table_res = $bq->delete_table(
        project_id => $project_id,
        dataset_id => $dataset_id,
        table_id   => $table_id,
    );
    ok($del_table_res, 'delete_table returned response');
    
    # Delete Dataset
    $bq->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, 'google.cloud.bigquery.v2.DatasetService', 'Correct service path');
        is($args->{method}, 'DeleteDataset', 'Correct RPC method');
        is($args->{request}->dataset_id(), $dataset_id, 'Correct dataset_id');
        is($args->{request}->delete_contents(), 1, 'delete_contents is true');
        return 'Google::Protobuf::Empty::Empty'->new();
    };
    my $del_dataset_res = $bq->delete_dataset(
        project_id      => $project_id,
        dataset_id      => $dataset_id,
        delete_contents => 1,
    );
    ok($del_dataset_res, 'delete_dataset returned response');
    done_testing();
};

done_testing();
1;
