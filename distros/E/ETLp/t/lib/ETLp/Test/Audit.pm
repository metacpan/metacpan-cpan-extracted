package ETLp::Test::Audit;

use Test::More;
use Data::Dumper;
use base 'ETLp::Test::DBBase';

use ETLp::Audit::Job;
use ETLp::Config;
use DateTime;

sub _get_oracle_session_id {
    my $self = shift;

    my ($session_id) =
      $self->dbh->selectrow_array(q{select sid from v$mystat where rownum = 1});

    return $session_id;
}

sub _app_config {
    return {config => {filename_format => '(test\.csv)(?:\.gz)?'}};
}

sub job : Tests(14) {
    my $self = shift;

    my $etl_job = ETLp::Audit::Job->new(
        name    => 'test_config',
        section => 'test_section',
        config  => _app_config()
    );

    my $config = ETLp::Config->schema->resultset('EtlpConfiguration')->find(1);
    is($config->config_name, 'test_config', 'Configuration created');
    isa_ok($config->date_created, 'DateTime', 'Configuration date_created');
    isa_ok($config->date_updated, 'DateTime', 'Configuration date_updated');

    my $section = ETLp::Config->schema->resultset('EtlpSection')->find(1);
    is($section->section_name, 'test_section', 'Section created');
    isa_ok($section->date_created, 'DateTime', 'Section date_created');
    isa_ok($section->date_updated, 'DateTime', 'Section date_updated');

    my $job          = ETLp::Config->schema->resultset('EtlpJob')->find(1);
    my $date_updated = $job->date_created;
    is($job->process_id, $$,    'Saved OS Process');
    is($job->message,    undef, 'No message');
    isa_ok($job->date_created, 'DateTime', 'Job date_created');
    isa_ok($job->date_updated, 'DateTime', 'Job date_updated');
    is($job->status->status_name, 'running', 'Job is running');
    sleep 1;

    $etl_job->update_message('Message updated');
    $job = ETLp::Config->schema->resultset('EtlpJob')->find(1);
    is($job->message, 'Message updated', 'Job message updated');
    is(DateTime->compare($date_updated, $job->date_updated),
        -1, 'Audit date updated set');

    $etl_job->update_status('succeeded');
    $job = ETLp::Config->schema->resultset('EtlpJob')->find(1);
    is($job->status->status_name, 'succeeded', 'Job Status updated');

}

sub item : Tests(11) {
    my $self = shift;

    my $etl_job =
      ETLp::Audit::Job->new(name => 'test_config', section => 'test_section', 
        config  => _app_config());

    my $etl_item = $etl_job->create_item(
        name  => 'test_item',
        type  => 'test_type',
        phase => 'pre_process',
    );
    isa_ok($etl_item, 'ETLp::Audit::Item');
    is($etl_job->item, $etl_item, 'Get current item');

    my $item = ETLp::Config->schema->resultset('EtlpItem')->find(1);
    is($item->item_name,           'test_item',   "Item name set");
    is($item->status->status_name, 'running',     "Item status set");
    is($item->phase->phase_name,   'pre_process', "Item phase set");

    my $etl_item2 = $etl_job->create_item(
        name  => 'test_item',
        type  => 'test_type',
        phase => 'pre_process'
    );
    isnt($etl_item, $etl_item2, 'New current item');

    sleep 1;
    my $date_updated = $item->date_created;
    $etl_item->update_message('Item updated');
    $item = ETLp::Config->schema->resultset('EtlpItem')->find($etl_item->id);
    is($item->message, 'Item updated', 'Item message updated');
    is(DateTime->compare($date_updated, $item->date_updated),
        -1, 'Audit date updated set');

    my $job = ETLp::Config->schema->resultset('EtlpJob')->find($etl_job->id);
    is(DateTime->compare($job->date_updated, $item->date_updated),
        0, 'Parent Job date updated after message update');

    $etl_item->update_status('succeeded');
    $item = ETLp::Config->schema->resultset('EtlpItem')->find($etl_item->id);
    is($item->status->status_name, 'succeeded', 'Item status updated');
    $job = ETLp::Config->schema->resultset('EtlpJob')->find($etl_job->id);
    is(DateTime->compare($job->date_updated, $item->date_updated),
        0, 'Parent Job date updated after status update');
}

sub file_processing : Tests(7) {
    my $self = shift;

    my $etl_job =
      ETLp::Audit::Job->new(name => 'test_config', section => 'test_section',
        config  => _app_config());

    my $etl_item = $etl_job->create_item(
        name  => 'test_item',
        type  => 'test_type',
        phase => 'pre_process'
    );

    my $etl_file = $etl_item->create_file_process('test.csv.gz');
    isa_ok($etl_file, 'ETLp::Audit::FileProcess');

    my $file_process =
      ETLp::Config->schema->resultset('EtlpFileProcess')->find($etl_file->id);
    is($file_process->filename, 'test.csv.gz', 'File process recorded');
    is($file_process->file->canonical_filename,
        'test.csv', 'Determined canonical filename');

    sleep 1;

    $etl_file->update_message('File process updated');
    $file_process =
      ETLp::Config->schema->resultset('EtlpFileProcess')->find($etl_file->id);
    my $item = $file_process->item;
    my $job  = $item->job;

    is($file_process->message, 'File process updated', 'Message updated');
    is(
        DateTime->compare(
            $file_process->date_created, $file_process->date_updated
        ),
        -1,
        'File process date updated'
    );
    is(DateTime->compare($item->date_updated, $file_process->date_updated),
        0, 'Item date updated');
    is(DateTime->compare($job->date_updated, $file_process->date_updated),
        0, 'Job date updated');
}

1;
