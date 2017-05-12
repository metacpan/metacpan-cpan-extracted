#!perl
use Test::More tests => 4;

BEGIN { require 't/mocks.pl' }

BEGIN { use_ok( 'Log::Dispatch::Desktop::Notify' ) }

subtest 'Desktop::Notify instance' => sub {
    my $obj = Log::Dispatch::Desktop::Notify->new( min_level => 'warning' );
    isa_ok( $obj->{_notify}, 'Desktop::Notify' );
};

subtest 'default name' => sub {
    # given
    my $obj = Log::Dispatch::Desktop::Notify->new( min_level => 'warning' );

    # when
    $obj->log( level => 'warning', message => 'TEST');

    # then
    is( $obj->{_notify}->app_name, $0, 'name' );
};

subtest 'given name' => sub {
    # given
    my $obj = Log::Dispatch::Desktop::Notify->new( min_level => 'warning', app_name => 'TEST_APP' );

    # when
    $obj->log( level => 'warning', message => 'TEST');

    # then
    is( $obj->{_notify}->app_name, 'TEST_APP', 'name' );
};
