use strict;
use warnings;
use Test::More tests => 16;

use Log::Any;
use Log::Any::Adapter;

{
    package _My::Structured::Adapter;
    use base 'Log::Any::Adapter::Base';
    use Log::Any::Adapter::Util qw(make_method);

    our $instance;
    our $is_logging      = 0;
    our @structured_args = ();

    sub init { $instance = shift }

    sub structured { @structured_args = @_ }
    foreach my $method ( Log::Any->detection_methods() ) {
        make_method( $method, sub { $is_logging } );
    }
}

{
    package _My::Unstructured::Adapter;
    use base 'Log::Any::Adapter::Base';
    use Log::Any::Adapter::Util qw(make_method);

    our $instance;
    our $is_logging        = 0;
    our %unstructured_args = ();

    sub init { $instance = shift }

    # Log what we called at each severity
    foreach my $method ( Log::Any->logging_methods() ) {
        make_method( $method, sub { $unstructured_args{$method} = [@_] } );
    }

    foreach my $method ( Log::Any->detection_methods() ) {
        make_method( $method, sub { $is_logging } );
    }
}

require_ok('Log::Any::Adapter::Multiplex');

# basic_arg_validation
{
    # helpful for making sure init() is called on each set() below
    my $log = Log::Any->get_logger;

    eval { Log::Any::Adapter->set( 'Multiplex' ) };
    ok $@, 'adapters are required';

    eval {
        Log::Any::Adapter->set(
            'Multiplex',
            adapters => 'Stdout'
        )
    };
    ok $@, 'adapters must be a hash';

    eval {
        Log::Any::Adapter->set(
            'Multiplex',
            adapters => 'Stdout'
        )
    };
    ok $@, 'adapters must be a hash';

    eval {
        Log::Any::Adapter->set(
            'Multiplex',
            adapters => {
                Stdout => {}
            }
        )
    };
    ok $@, 'adapters values must be arrays';

    eval {
        Log::Any::Adapter->set(
            'Multiplex',
            adapters => {
                Stdout => [ log_level => 'info' ],
                Stderr => [],
            }
        )
    };
    ok !$@, "Multiplex set up as expected"
        or diag $@;
}

# multiplex_implementation
{
    my %random_args = ( log_level => 'scream' );

    my $entry = Log::Any::Adapter->set(
        'Multiplex',
        adapters => {
            '+_My::Structured::Adapter'   => [ %random_args ],
            '+_My::Unstructured::Adapter' => [ %random_args ],
        }
    );

    my $log = Log::Any->get_logger();
    ok !$log->is_info, "multiplex logging off for both destinations";

    $_My::Structured::Adapter::is_logging   = 1;
    $_My::Unstructured::Adapter::is_logging = 0;
    ok $log->is_info, "multiplex logging on for one destination";

    $_My::Structured::Adapter::is_logging   = 0;
    $_My::Unstructured::Adapter::is_logging = 1;
    ok $log->is_info, "multiplex logging on for other destination";

    $_My::Structured::Adapter::is_logging   = 1;
    $_My::Unstructured::Adapter::is_logging = 1;
    ok $log->is_info, "multiplex logging on for both destinations";

    my $structured_adapter   = $_My::Structured::Adapter::instance;
    my $unstructured_adapter = $_My::Unstructured::Adapter::instance;

    is $structured_adapter->{log_level},
       $random_args{log_level},
       "Arguments passed to structured adapter";
    is $unstructured_adapter->{log_level},
       $random_args{log_level},
       "Arguments passed to unstructured adapter";

    my $message = "In a bottle";
    my $level   = 'info';
    my $cat     = __PACKAGE__;
    $log->context->{foo} = 'bar';
    my $ctx_str = '{foo => "bar"}';
    $log->$level($message);

    is_deeply [ @_My::Structured::Adapter::structured_args ],
              [ $structured_adapter, $level, $cat, $message, $log->context ],
              "Passed appropriate structured args";
    is_deeply $_My::Unstructured::Adapter::unstructured_args{$level},
              [ $unstructured_adapter, $message, $ctx_str ],
              "Passed appropriate unstructured args";

    @_My::Structured::Adapter::structured_args = ();
    $_My::Structured::Adapter::is_logging = 0;
    $log->$level($message);
    is_deeply [ @_My::Structured::Adapter::structured_args ],
              [ ],
              "structured adapter not called when not logging";

    $_My::Structured::Adapter::is_logging = 1;
    %_My::Unstructured::Adapter::unstructured_args = ();
    $_My::Unstructured::Adapter::is_logging = 0;
    $log->$level($message);
    is_deeply { %_My::Unstructured::Adapter::unstructured_args },
              { },
              "unstructured adapter not called when not logging";
}
