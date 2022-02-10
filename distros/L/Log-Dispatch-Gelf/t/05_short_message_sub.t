use strict;
use Test::More;
use Test::Exception;

use Log::Dispatch;
use JSON::MaybeXS;

my $LAST_LOG_MSG;

my $log = Log::Dispatch->new(
    outputs => [ [
        'Gelf',
        min_level         => 'debug',
        additional_fields => { facility => __FILE__ },
        send_sub          => sub { $LAST_LOG_MSG = $_[0] },
        short_message_sub => sub { substr($_[0], 0, 14) }
    ] ],
);

$log->info("Short message. Details.");

note "formatted message: $LAST_LOG_MSG";

my $msg = decode_json($LAST_LOG_MSG);
is($msg->{level}, 6, 'correct level info');
is($msg->{short_message}, 'Short message.', 'short_message correct');
is($msg->{full_message}, "Short message. Details.", 'full_message correct');
is($msg->{_facility}, __FILE__, 'facility correct');
ok($msg->{host}, 'host is there');
ok($msg->{timestamp}, 'timestamp is there');
ok($msg->{version}, 'version is there');

dies_ok {
  Log::Dispatch->new(
    outputs => [ [
        'Gelf',
        min_level         => 'debug',
        additional_fields => { facility => __FILE__ },
        send_sub          => sub { $LAST_LOG_MSG = $_[0] },
        short_message_sub => 'Not a coderef'
    ] ],
); }, 'Short message sub is not a CODEREF';

done_testing();
