#!perl
use Test::More tests => 4;

BEGIN { require 't/mocks.pl' }

BEGIN { use_ok( 'Log::Dispatch::Desktop::Notify' ) }

subtest 'simple notification' => sub {
    # given
    my $obj = Log::Dispatch::Desktop::Notify->new( min_level => 'warning' );

    # when
    $obj->log( level => 'warning', message => 'TEST');

    # then
    is( $notify_mock->metrics->{create}, 1, 'create notification' );
    is( $notification_mock->metrics->{show}, 1, 'show notification' );
    is( $last_notification->summary, 'TEST', 'notification message' );
};

subtest 'default timeout' => sub {
    # given
    my $obj = Log::Dispatch::Desktop::Notify->new( min_level => 'warning' );

    # when
    $obj->log( level => 'warning', message => 'TEST');

    # then
    is( $last_notification->timeout, -1, 'timeout' );
};

subtest 'given timeout' => sub {
    # given
    my $obj = Log::Dispatch::Desktop::Notify->new( min_level => 'warning', timeout => 5000 );

    # when
    $obj->log( level => 'warning', message => 'TEST');

    # then
    is( $last_notification->timeout, 5000, 'timeout' );
};
