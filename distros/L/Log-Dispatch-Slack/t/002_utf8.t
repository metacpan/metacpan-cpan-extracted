use strict;
use utf8;
use warnings;
use Log::Dispatch::Slack;
use Test::Mock::Guard;
use Test::More;

subtest 'Test with utf8 => 1' => sub {
    my $guard = mock_guard(
        'WebService::Slack::WebApi::Chat' => {
            post_message => sub {
                my ($chat, %args) = @_;

                no utf8;
                is $args{text}, 'あああ';

                { ok => 1 };
            },
        },
    );

    my $slack = Log::Dispatch::Slack->new(
        min_level => 'info',
        channel   => 'foo',
        token     => '12345',
        username  => 'bar',
        icon      => 'buz',
        utf8      => 1,
    );

    $slack->log_message(level => 'warn', message => 'あああ');
};

subtest 'Test without utf8' => sub {
    my $guard = mock_guard(
        'WebService::Slack::WebApi::Chat' => {
            post_message => sub {
                my ($chat, %args) = @_;

                is $args{text}, 'あああ';

                { ok => 1 };
            },
        },
    );

    my $slack = Log::Dispatch::Slack->new(
        min_level => 'info',
        channel   => 'foo',
        token     => '12345',
        username  => 'bar',
        icon      => 'buz',
    );

    $slack->log_message(level => 'warn', message => 'あああ');
};

done_testing;
