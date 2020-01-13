use strict;
use warnings;
use Test::More tests => 12;
use Log::Any;
use Log::Any::Adapter::Util qw(cmp_deeply);

BEGIN { 
    $Log::Any::OverrideDefaultProxyClass = 'Log::Any::Proxy::Test';
}

{

    package Foo;
    use Log::Any qw($log);

    sub log_debug {
        my ( $class, $text ) = @_;
        $log->debug($text) if $log->is_debug();
    }
}
{

    package Bar;
    use Log::Any qw($log);

    sub log_info {
        my ( $class, $text ) = @_;
        $log->info($text) if $log->is_info();
    }
}

require Log::Any::Adapter;

my $main_log = Log::Any->get_logger();
my $foo_log = $Foo::log;

# redirect to array
{
    Log::Any::Adapter->set( { lexically => \my $scope }, Capture => to => \my @array );
    $main_log->info('Test');
    is_deeply( shift @array, [ 'info', 'main', 'Test' ], 'main logged to arrayref' );
    $main_log->info('Test', 'Test2', { val => 42 });
    is_deeply( shift @array, [ 'info', 'main', 'Test Test2 {val => 42}' ], 'main logged flattened arguments' );
    $foo_log->trace('Test2');
    is_deeply( shift @array, [ 'trace', 'Foo', 'Test2' ], 'Foo logged to arrayref' );
}

# redirect_to_coderef
{
    my @last;
    Log::Any::Adapter->set( { lexically => \my $scope }, Capture => to => sub { @last= @_ } );
    $main_log->info('Test');
    is_deeply( \@last, [ 'info', 'main', 'Test' ], 'main logged to coderef' );
    $foo_log->trace('Test2');
    is_deeply( \@last, [ 'trace', 'Foo', 'Test2' ], 'Foo logged to coderef' );
}

# redirect text only
{
    Log::Any::Adapter->set(
        { lexically => \my $scope },
        Capture => ( text => \my @array, log_level => 'info' )
    );
    $main_log->info('Test');
    is_deeply( shift @array, 'Test', 'main logged text-only to arrayref' );
    $main_log->info('Test', 'Test2', { val => 42 });
    is_deeply( shift @array, 'Test Test2 {val => 42}', 'main logged flattened arguments' );
    $foo_log->trace('Test2');
    is_deeply( shift @array, undef, 'Foo ->trace was ignored' );
}

# redirect structured
{
    {
        Log::Any::Adapter->set(
            { lexically => \my $scope },
            Capture => ( structured => \my @array )
        );
        $main_log->info('Test', 'Test2', { blah => 1 });
        is_deeply( shift @array, [ 'info', 'main', 'Test', 'Test2', { blah => 1 } ], 'main logged full data' );
        local $main_log->context->{val} = 42;
        $main_log->info('Test', 'Test2', { blah => 1 });
        is_deeply( shift @array, [ 'info', 'main', 'Test', 'Test2', { blah => 1, val => 42 } ], 'main logged combined context' );
    }
    {
        Log::Any::Adapter->set(
            { lexically => \my $scope },
            Capture => ( format => 'structured', to => \my @array )
        );
        $foo_log->trace('Test3', ['Test4']);
        is_deeply( shift @array, [ 'trace', 'Foo', 'Test3', ['Test4'] ], 'Foo logged full data' );
        local $foo_log->context->{val} = 42;
        $foo_log->trace('Test3', ['Test4']);
        is_deeply( shift @array, [ 'trace', 'Foo', 'Test3', ['Test4'], { val => 42 } ], 'Foo logged combined context' );
    }
}
