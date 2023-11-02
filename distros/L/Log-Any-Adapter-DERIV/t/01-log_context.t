use strict;
use warnings;

use Test::More;

use Log::Any qw($log);
use Log::Any::Adapter;
use Path::Tiny;
use JSON::MaybeUTF8 qw(:v1);
use Test::Exception;
use Test::MockModule;

my $file_log_message;
# create a temporary file to store the log message
my $json_log_file = Path::Tiny->tempfile();

# log message in file and check set_context and clear_context works fine with the log message
sub do_context_text {
    my %args = @_;

    $file_log_message = '';
    $json_log_file->remove;
    Log::Any::Adapter->import('DERIV', $args{import_args}->%*);
    $log->adapter->set_context($args{context});
    $log->warn("This is a warn log");
    $file_log_message = $json_log_file->exists ? $json_log_file->slurp : '';
    chomp($file_log_message);
    lives_ok { $file_log_message = decode_json_text($file_log_message) }
    'log message is a valid json';

    # test to verify that correlation_id is present in the log message after set_context
    is($file_log_message->{correlation_id}, '1241421662', "context ok");
    $log->adapter->clear_context();

    # Create a new log message after clearing the context
    $log->warn("This is a new warn log");
    $file_log_message = $json_log_file->exists ? $json_log_file->slurp : '';
    chomp($file_log_message);
    lives_ok {
        $file_log_message = eval { decode_json_text($file_log_message) }
    }
    'new log message is a valid JSON';

    # this added to debug log message after clear context
    if ($@) {
        diag("Error decoding new log message: $@");
        diag("New log message content: $file_log_message");
    }

    # test to verify that correlation_id is not present in the new log message after clear_context
    is($file_log_message->{correlation_id}, undef, "correlation_id not present in new log message");
}

do_context_text(
    stderr_is_tty  => 0,
    in_container   => 0,
    import_args    => {json_log_file => "$json_log_file"},
    test_json_file => 1,
    context        => {correlation_id => "1241421662"},
);
done_testing();
