BEGIN {
  unless (defined $ENV{CLIENT_EMAIL} && defined $ENV{PRIVATE_KEY_FILE} && $ENV{PROJECT_ID}) {
    require Test::More;
    Test::More::plan(skip_all => 'This test needs $ENV{CLIENT_EMAIL}, $ENV{PRIVATE_KEY_FILE} and $ENV{PROJECT_ID}.');
  }
}

use strict;
use Test::More 0.98;
use Test::Exception;
use JSON qw(decode_json encode_json);
use Data::Dumper;
use FindBin '$Bin';

use Google::BigQuery;

my $client_email = $ENV{CLIENT_EMAIL};
my $private_key_file = $ENV{PRIVATE_KEY_FILE};
my $project_id = $ENV{PROJECT_ID};
my ${dataset_id} = 'sample_dataset_' . time;
my $table_id = 'sample_table_' . time;
my $ret;

my $bq = Google::BigQuery::create(client_email=>$client_email, private_key_file=>$private_key_file);

is($bq->create_dataset(project_id=>$project_id,dataset_id=>$dataset_id),1,'create_dataset: ok');

# create table
is($bq->create_table(),0,'create_table: no project');
is($bq->create_table(project_id=>$project_id),0,'create_table: no dataset');
is($bq->create_table(project_id=>$project_id,dataset_id=>$dataset_id),0,'create_table: no table');
is($bq->create_table(project_id=>$project_id,dataset_id=>$dataset_id,table_id=>$table_id),1,'create_table: ok');
is($bq->create_table(project_id=>$project_id,dataset_id=>$dataset_id,table_id=>$table_id),0,'create_table: already exists');

# drop table
is($bq->drop_table(),0,'drop_table: no project');
is($bq->drop_table(project_id=>$project_id),0,'drop_table: no dataset');
is($bq->drop_table(project_id=>$project_id,dataset_id=>$dataset_id),0,'drop_table: no table');
is($bq->drop_table(project_id=>$project_id,dataset_id=>$dataset_id,table_id=>"${table_id}x"),0,'drop_table: not found table');
is($bq->drop_table(project_id=>$project_id,dataset_id=>$dataset_id,table_id=>"${table_id}"),1,'drop_table: ok');

# show tables
is($bq->show_tables(),undef,'show_tables: no project');
is($bq->show_tables(project_id=>$project_id),undef,'show_tables: no dataset');
is($bq->show_tables(project_id=>$project_id,dataset_id=>"${dataset_id}x"),undef,'show_tables: not found dataset');
is($bq->show_tables(project_id=>$project_id,dataset_id=>"${dataset_id}"),0,'show_tables: ok');
is($bq->create_table(project_id=>$project_id,dataset_id=>$dataset_id,table_id=>$table_id),1,'create_table: ok');
is($bq->show_tables(project_id=>$project_id,dataset_id=>"${dataset_id}"),1,'show_tables: ok');
is($bq->drop_table(project_id=>$project_id,dataset_id=>$dataset_id,table_id=>"${table_id}"),1,'drop_table: ok');

# schema
my $schema = [ { name => 'id', type => 'INTEGER', mode => 'REQUIRED' } ];
my $invalid_type_schema = [ { name => 'id', type => 'INTEGERx', mode => 'REQUIRED' } ];
my $invalid_mode_schema = [ { name => 'id', type => 'INTEGER', mode => 'REQUIREDx' } ];
my $invalid_ref_schema = { name => 'id', type => 'INTEGER', mode => 'REQUIRED' };

$bq->use_project($project_id);
$bq->use_dataset($dataset_id);
is($bq->create_table(table_id=>$table_id,schema=>$schema),1,'create table schema: ok');
is($bq->drop_table(table_id=>$table_id),1,'drop table: ok');
is($bq->create_table(table_id=>$table_id,schema=>$invalid_type_schema),0,'create table schema: invalid type');
is($bq->create_table(table_id=>$table_id,schema=>$invalid_mode_schema),0,'create table schema: invalid mode');
is($bq->create_table(table_id=>$table_id,schema=>$invalid_ref_schema),0,'create table schema: invalid ref');

done_testing;
