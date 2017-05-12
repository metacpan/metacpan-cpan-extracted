#!perl
use Test::More tests => 3;

BEGIN { require 't/mocks.pl' }

BEGIN { use_ok( 'Log::Dispatch::Desktop::Notify' ) }

subtest 'instance' => sub {
    my $obj = Log::Dispatch::Desktop::Notify->new( min_level => 'warning' );
    isa_ok( $obj, 'Log::Dispatch::Desktop::Notify' );
};

subtest 'inheritance' => sub {
    my $obj = Log::Dispatch::Desktop::Notify->new( min_level => 'warning' );
    isa_ok( $obj, 'Log::Dispatch::Output' );
};

