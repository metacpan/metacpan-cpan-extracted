use strict;
use Test::More;
use Test::Exception;

use Log::Dispatch;
use JSON;

my $LAST_LOG_MSG;

my $log = Log::Dispatch->new(
    outputs => [ [
        'Gelf',
        min_level         => 'debug',
        additional_fields => { facility => __FILE__ },
        send_sub          => sub { $LAST_LOG_MSG = $_[0] },
    ] ],
);

$log->info("It works\nMore details.");

note "formatted message: $LAST_LOG_MSG";

my $msg = decode_json($LAST_LOG_MSG);
is($msg->{level}, 6, 'correct level info');
is($msg->{short_message}, 'It works', 'short_message correct');
is($msg->{full_message}, "It works\nMore details.", 'full_message correct');
is($msg->{_facility}, __FILE__, 'facility correct');
ok($msg->{host}, 'host is there');
ok($msg->{timestamp}, 'timestamp is there');
ok($msg->{version}, 'version is there');

dies_ok {
    $log->log(
        level             => 'info',
        message           => "It works\nMore details.",
        additional_fields => 'not a hashref'
    );
}
'additional_fields wrong type';

$log->log(
    level             => 'info',
    message           => "It works\nMore details.",
    additional_fields => { additional => 1 }
);

note "formatted message: $LAST_LOG_MSG";

$msg = decode_json($LAST_LOG_MSG);
is($msg->{level}, 6, 'correct level info');
is($msg->{short_message}, 'It works', 'short_message correct');
is($msg->{full_message}, "It works\nMore details.", 'full_message correct');
is($msg->{_facility}, __FILE__, 'facility correct');
is($msg->{_additional}, 1, 'additional log field correct');
ok($msg->{host}, 'host is there');
ok($msg->{timestamp}, 'timestamp is there');
ok($msg->{version}, 'version is there');

$log->log(
    level             => 'info',
    message           => "It works\nMore details.",
    additional_fields => { facility => 'override' }
);

note "formatted message: $LAST_LOG_MSG";

$msg = decode_json($LAST_LOG_MSG);
is($msg->{_facility}, 'override', 'facility overridden correctly');

$log->log(
    level   => 'info',
    message => "It works\nMore details.",
);

note "formatted message: $LAST_LOG_MSG";

$msg = decode_json($LAST_LOG_MSG);
is($msg->{_facility}, __FILE__, 'override is temporary');

done_testing(18);
