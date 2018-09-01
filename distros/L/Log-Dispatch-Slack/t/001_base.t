use strict;
use warnings;

use Test::More;

use Test::MockModule;
use Test::MockObject;

use Test::Exception;

my $DIE_DIE_DIE = 0;


use_ok 'Log::Dispatch::Slack';

my $mock = Test::MockModule->new('Log::Dispatch::Slack');
$mock->mock('_make_handle', sub {
    my $self = shift;

    # mock Webservice::Slack::WebApi first
    my $swapi = Test::MockObject->new();
    $swapi->mock('chat', sub {

        # now mock Webservice::Slack::WebApi::Chat
        my $chat = Test::MockObject->new();
        my $post = $chat->mock('post_message', sub {
            if ($DIE_DIE_DIE) {
                return {
                    'ok' => 0,
                    'error' => 'some_slack_error',
                }
            }

            return {
                ok => 1,
            }
        })
    });
    $self->{client} = $swapi;
    return;
});

my $slack = Log::Dispatch::Slack->new( token => 'aaaa', channel => '#dr-strange', min_level => 1);
lives_ok {
    $slack->log_message(message=>"lalala");
} 'Successfully "sent message" via our mockery';

$DIE_DIE_DIE = 1;

throws_ok {
    $slack->log_message(message=>"lalala");
} qr/\QFailed to send message to channel (#dr-strange): some_slack_error\E/, "Now it dies as it is supposed to";

lives_ok {
    my $slack = Log::Dispatch::Slack->new( token => 'aaaa', channel => '#dr-strange', die_on_error => 0, min_level => 1);
    $slack->log_message(message=>"lalala");
} "And now it lives again!";

done_testing();
__END__
