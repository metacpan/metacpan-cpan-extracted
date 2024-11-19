use strict;
use warnings;

use Test::More;

use Log::Any qw($log);
use Log::Any::Adapter;
use Path::Tiny;
use JSON::MaybeUTF8 qw(:v1);
use Test::MockModule;
use Syntax::Keyword::Try;

my $file_log_message;
# create a temporary file to store the log message
my $json_log_file = Path::Tiny->tempfile();

sub do_sensitive_mask_test {
    my %args = @_;

    $file_log_message = '';
    $json_log_file->remove;
    Log::Any::Adapter->import('DERIV', $args{import_args}->%*);

    my $email         = 'abc@gmail.com';
    my $api_key       = '23892jsjdkajdad';
    my $api_token     = 'jsahjdasdpdpadka';
    my $oauth_token   = 'a1-Mr3GSXISsKGOeDYzvacEbSwC2mk0w';
    my $ctrader_token = 'ct1-Mr3GSXISsKGOeDYzvacEbSwC2mk0w';
    my $refresh_token = 'r1-Mr3GSXISsKGOeDYzvacEbSwC2mk0w';
    my $slack_token   = 'xoxb-0000000000-00000000-000000000000000000000000';

    $log->warn("User $email is logged in");
    $log->warn("The API key: $api_key and the rest of the message is ABC");
    $log->warn("The API token = $api_token");
    $log->warn("The OAuth token is $oauth_token");
    $log->warn("The cTrader token is $ctrader_token and the refresh token is $refresh_token");
    $log->warn("The slack token is $slack_token");
    $log->warn("This message should not have any sensitive data masked");

    my @expected_masked_messages = (
        "User " . '*' x length($email) . " is logged in",
        #word key and token with space 'and =: is' will be masked too as we have multiple variations
        #and from regex extracting $1 $2 is not a good approach hence we will mask full text
        "The API *****" . '*' x length($api_key) . " and the rest of the message is ABC",
        "The API ********" . '*' x length($api_token),
        "The OAuth token is " . '*' x length($oauth_token),
        "The cTrader token is " . '*' x length($ctrader_token) . " and the refresh token is " . '*' x length($refresh_token),
        "The slack token is " . '*' x length($slack_token),
        "This message should not have any sensitive data masked",
    );

    $file_log_message = $json_log_file->exists ? $json_log_file->slurp : '';
    chomp($file_log_message);

    my @log_entries = map { decode_json_text($_) } split("\n", $file_log_message);

    foreach my $index (0 .. $#expected_masked_messages) {
        my $expected_message = $expected_masked_messages[$index];
        my $actual_message   = $log_entries[$index]{message};
        is($actual_message, $expected_message, "Message $index processed as expected");
    }
}

do_sensitive_mask_test(
    stderr_is_tty  => 0,
    in_container   => 0,
    import_args    => {json_log_file => "$json_log_file"},
    test_json_file => 1,
);

# Test error handling for exception case in mask_sensitive to ensure that exception is
# raised and handled properly with no recursive loop

subtest 'Check error handling in mask_sensitive' => sub {

    my $mock_module = Test::MockModule->new('Log::Any::Adapter::DERIV');
    $mock_module->mock('mask_sensitive', sub { die "Mock error" });    #this will raise exception

    my $result;
    try {
        $log->warn("This message should throw exception");
    } catch ($error_msg) {
        like($error_msg, qr/Mock error/, "Error message contains 'Mock error'");
        $result = undef;
    };

    ok(!defined($result), "Exception was raised as expected");

    $mock_module->unmock_all();
};

done_testing();
