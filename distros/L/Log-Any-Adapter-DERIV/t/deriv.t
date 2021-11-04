use strict;
use warnings;

use Test::More;

use Test::MockTime::HiRes qw(set_fixed_time);
use Log::Any qw($log);
use Log::Any::Adapter;
use Path::Tiny;
use JSON::MaybeUTF8 qw(:v1);
use Test::Exception;
use Sys::Hostname;
use Test::MockModule;
use Term::ANSIColor qw(colored);
set_fixed_time(1623247131);

my $mocked_deriv = Test::MockModule->new('Log::Any::Adapter::DERIV');
my $stderr_is_tty;
my $stdout_is_tty;
$mocked_deriv->mock(
    '_fh_is_tty',
    sub {
        my $fh = shift;
        if($fh eq \*STDERR){
            return $stderr_is_tty;
        }
        else{
            return $stdout_is_tty;
        }
    }
);

my $in_container;
$mocked_deriv->mock(
    '_in_container',
    sub {
        return $in_container;
    }
);

sub test_json {
    my $log_message = shift;
    chomp($log_message);
    lives_ok { $log_message = decode_json_text($log_message) }
    'log message is a valid json';
    is_deeply( [ sort keys %$log_message ],
        [ sort qw(pid stack severity host epoch message) ] );
    is( $log_message->{host},     hostname(),           "host name ok" );
    is( $log_message->{pid},      $$,                   "pid ok" );
    is( $log_message->{message},  'This is a warn log', "message ok" );
    is( $log_message->{severity}, 'warning',            "severity ok" );
}

sub test_color_text {
    my $log_message = shift;
    chomp($log_message);
    my $expected_message = join " ",
      colored( '2021-06-09T13:58:51', 'bright_blue' ),
      colored( 'W',                   'bright_yellow' ),
      colored( '[main->do_test]',     'grey10' ),
      colored( 'This is a warn log',  'bright_yellow' );
    is( $log_message, $expected_message, "colored text ok" );
}

sub test_text {
    my $log_message = shift;
    chomp($log_message);
    my $expected_message = join " ", '2021-06-09T13:58:51', 'W',
      '[main->do_test]', 'This is a warn log';
    is( $log_message, $expected_message, "text message ok" );
}
my $stderr_log_message;
my $stdout_log_message;
my $file_log_message;
my $json_log_file = Path::Tiny->tempfile();

sub call_log {
    my $import_args = shift;

    local *STDERR;
    local *STDOUT;
    $stderr_log_message = '';
    $file_log_message   = '';
    $json_log_file->remove;
    open STDERR, '>', \$stderr_log_message;
    open STDOUT, '>', \$stdout_log_message;
    Log::Any::Adapter->import( 'DERIV', $import_args->%* );
    $log->warn("This is a warn log");
    $file_log_message = $json_log_file->exists ? $json_log_file->slurp : '';
}

sub do_test {
    my %args = @_;
    subtest encode_json_text( \%args ) => sub {
        $stdout_is_tty = $args{stdout_is_tty};
        $stderr_is_tty = $args{stderr_is_tty};
        $in_container  = $args{in_container};
        if($args{test_stderr} || $args{test_stdout}){
            # redirecting STDERR to a scalar will cause fcntl lock to error,
            # here skip that lock function to avoid the error
            $mocked_deriv->noop('_lock', '_unlock');
        }
        call_log( $args{import_args} );
        if ( $args{test_json_file} ) {
            ok( $file_log_message, 'json file has logs' );
            test_json($file_log_message);
        }
        if($args{test_stderr}){
            ok( $stderr_log_message, "STDERR has logs" );
            if ( $args{test_stderr} eq 'json' ) {
                test_json($stderr_log_message);
            }
            elsif ( $args{test_stderr} eq 'color_text' ) {
                test_color_text($stderr_log_message);
            }
            else {
                test_text($stderr_log_message);
            }
        }
        if($args{test_stdout}){
            ok( $stdout_log_message, "STDOUT has logs" );
            if ( $args{test_stdout} eq 'json' ) {
                test_json($stdout_log_message);
            }
            elsif ( $args{test_stdout} eq 'color_text' ) {
                test_color_text($stdout_log_message);
            }
            else {
                test_text($stdout_log_message);
            }
        }
        $mocked_deriv->unmock('_lock', '_unlock') if $mocked_deriv->is_mocked('_lock');
    }
}

do_test(
    stderr_is_tty  => 0,
    in_container   => 0,
    import_args    => { json_log_file => "$json_log_file" },
    test_json_file => 1
);
do_test(
    stderr_is_tty  => 0,
    in_container   => 1,
    import_args    => { json_log_file => "$json_log_file" },
    test_json_file => 1
);
do_test(
    stderr_is_tty  => 1,
    in_container   => 0,
    import_args    => { json_log_file => "$json_log_file" },
    test_json_file => 1
);
do_test(
    stderr_is_tty  => 1,
    in_container   => 1,
    import_args    => { json_log_file => "$json_log_file" },
    test_json_file => 1
);
do_test(
    stderr_is_tty => 0,
    in_container  => 0,
    import_args   => { stderr => 1 },
    test_stderr   => 'text'
);
do_test(
    stderr_is_tty => 0,
    in_container  => 0,
    import_args   => {},
    test_stderr   => 'text'
);
do_test(
    stderr_is_tty => 0,
    in_container  => 0,
    import_args   => { stderr => 'text' },
    test_stderr   => 'text'
);
do_test(
    stderr_is_tty => 0,
    in_container  => 0,
    import_args   => { stderr => 'json' },
    test_stderr   => 'json'
);
do_test(
    stderr_is_tty => 0,
    in_container  => 1,
    import_args   => { stderr => 1 },
    test_stderr   => 'json'
);
do_test(
    stderr_is_tty => 0,
    in_container  => 1,
    import_args   => {},
    test_stderr   => 'json'
);
do_test(
    stderr_is_tty => 0,
    in_container  => 1,
    import_args   => { stderr => 'text' },
    test_stderr   => 'text'
);
do_test(
    stderr_is_tty => 0,
    in_container  => 1,
    import_args   => { stderr => 'json' },
    test_stderr   => 'json'
);
do_test(
    stderr_is_tty => 1,
    in_container  => 0,
    import_args   => { stderr => 1 },
    test_stderr   => 'color_text'
);
do_test(
    stderr_is_tty => 1,
    in_container  => 0,
    import_args   => {},
    test_stderr   => 'color_text'
);
do_test(
    stderr_is_tty => 1,
    in_container  => 0,
    import_args   => { stderr => 'text' },
    test_stderr   => 'color_text'
);
do_test(
    stderr_is_tty => 1,
    in_container  => 0,
    import_args   => { stderr => 'json' },
    test_stderr   => 'json'
);
do_test(
    stderr_is_tty => 1,
    in_container  => 1,
    import_args   => {},
    test_stderr   => 'json'
);
do_test(
    stderr_is_tty => 1,
    in_container  => 1,
    import_args   => { stderr => 1 },
    test_stderr   => 'json'
);
do_test(
    stderr_is_tty => 1,
    in_container  => 1,
    import_args   => { stderr => 'text' },
    test_stderr   => 'color_text'
);
do_test(
    stderr_is_tty => 1,
    in_container  => 1,
    import_args   => { stderr => 'json' },
    test_stderr   => 'json'
);
do_test(
    stderr_is_tty => 1,
    in_container  => 1,
    import_args   => { json_log_file => "$json_log_file",stderr => 'json' },
    test_stderr   => 'json',
    test_json_file => 1,
);

do_test(
    stdout_is_tty => 0,
    in_container  => 0,
    import_args   => { stdout => 1 },
    test_stdout   => 'text'
);
do_test(
    stdout_is_tty => 0,
    in_container  => 0,
    import_args   => { stdout => 'text' },
    test_stdout   => 'text'
);
do_test(
    stdout_is_tty => 0,
    in_container  => 0,
    import_args   => { stdout => 'json' },
    test_stdout   => 'json'
);
do_test(
    stdout_is_tty => 0,
    in_container  => 1,
    import_args   => { stdout => 1 },
    test_stdout   => 'json'
);
do_test(
    stdout_is_tty => 0,
    in_container  => 1,
    import_args   => { stdout => 'text' },
    test_stdout   => 'text'
);
do_test(
    stdout_is_tty => 0,
    in_container  => 1,
    import_args   => { stdout => 'json' },
    test_stdout   => 'json'
);
do_test(
    stdout_is_tty => 1,
    in_container  => 0,
    import_args   => { stdout => 1 },
    test_stdout   => 'color_text'
);
do_test(
    stdout_is_tty => 1,
    in_container  => 0,
    import_args   => { stdout => 'text' },
    test_stdout   => 'color_text'
);
do_test(
    stdout_is_tty => 1,
    in_container  => 0,
    import_args   => { stdout => 'json' },
    test_stdout   => 'json'
);
do_test(
    stdout_is_tty => 1,
    in_container  => 1,
    import_args   => { stdout => 1 },
    test_stdout   => 'json'
);
do_test(
    stdout_is_tty => 1,
    in_container  => 1,
    import_args   => { stdout => 'text' },
    test_stdout   => 'color_text'
);
do_test(
    stdout_is_tty => 1,
    in_container  => 1,
    import_args   => { stdout => 'json' },
    test_stdout   => 'json'
);
do_test(
    stdout_is_tty => 1,
    in_container  => 1,
    import_args   => { json_log_file => "$json_log_file",stdout => 'json' },
    test_stdout   => 'json',
    test_json_file => 1,
);

done_testing();
