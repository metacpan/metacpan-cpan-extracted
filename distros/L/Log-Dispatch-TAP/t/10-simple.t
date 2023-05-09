use v5.14;
use warnings;

use Test::More;

use Log::Dispatch;
use Log::Dispatch::TAP;

use Test2::API qw/ intercept /;

subtest "instantiation" => sub {

    my $output = Log::Dispatch::TAP->new(
        name      => 'test',
        min_level => 'debug',
    );
    isa_ok $output, 'Log::Dispatch::TAP';

};

subtest "instantiation via Log::Dispatch" => sub {

    my $logger = Log::Dispatch->new(
        outputs => [ [ 'TAP', min_level => 'info', method => 'diag' ], ], );

    my $events = intercept {

        $logger->info("info gets logged");
        $logger->debug("debug does not");
        $logger->warning("warning gets logged");

    };

    my @messages = map { $_->message } @$events;

    is_deeply \@messages, [ "info gets logged", "warning gets logged" ],
      "messages";

};

done_testing;
