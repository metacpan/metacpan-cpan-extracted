#!perl
## no critic (ValuesAndExpressions::ProhibitMagicNumbers)
use strict;
use warnings;

our $VERSION = 0.001;

use utf8;
use Test2::V0;
set_encoding('utf8');

use JSON       qw( decode_json );
use Path::Tiny qw( path );

# Test log level filtering
# According to Log::Any documentation, log levels are (from lowest to highest):
# trace (0), debug (1), info (2), notice (3), warn (4), error (5), critical (6), alert (7), emergency (8)

subtest 'log level filtering - warn level' => sub {
    my $tempfile      = Path::Tiny->tempfile;
    my $tempfile_path = q{} . $tempfile->path;

    # Clear the file
    $tempfile->spew(q{});

    # Set up adapter with warn level
    require Log::Any::Adapter;
    Log::Any::Adapter->set(
        'JSONLines',
        file      => $tempfile_path,
        log_level => 'warn'
    );

    require Log::Any;
    my $log = Log::Any->get_logger();

    # Log messages at different levels
    $log->trace('trace message');    # Should NOT be logged (level 0 < warn)
    $log->debug('debug message');    # Should NOT be logged (level 1 < warn)
    $log->info('info message');      # Should NOT be logged (level 2 < warn)
    $log->warn('warn message');      # Should be logged (level 4 >= warn)
    $log->error('error message');    # Should be logged (level 5 >= warn)

    my @lines = $tempfile->lines_utf8( { chomp => 1 } );

    is( scalar(@lines), 2, 'Only 2 messages logged (warn and error)' );

    my $warn_entry = decode_json( $lines[0] );
    is( $warn_entry->{message}, 'warn message', 'warn message logged' );

    my $error_entry = decode_json( $lines[1] );
    is( $error_entry->{message}, 'error message', 'error message logged' );
};

subtest 'log level filtering - info level' => sub {
    my $tempfile      = Path::Tiny->tempfile;
    my $tempfile_path = q{} . $tempfile->path;

    # Clear the file
    $tempfile->spew(q{});

    # Set up adapter with info level
    require Log::Any::Adapter;
    Log::Any::Adapter->set(
        'JSONLines',
        file      => $tempfile_path,
        log_level => 'info'
    );

    require Log::Any;
    my $log = Log::Any->get_logger();

    # Log messages at different levels
    $log->trace('trace message');    # Should NOT be logged
    $log->debug('debug message');    # Should NOT be logged
    $log->info('info message');      # Should be logged
    $log->warn('warn message');      # Should be logged
    $log->error('error message');    # Should be logged

    my @lines = $tempfile->lines_utf8( { chomp => 1 } );

    is( scalar(@lines), 3, 'Only 3 messages logged (info, warn, and error)' );

    my $info_entry = decode_json( $lines[0] );
    is( $info_entry->{message}, 'info message', 'info message logged' );

    my $warn_entry = decode_json( $lines[1] );
    is( $warn_entry->{message}, 'warn message', 'warn message logged' );

    my $error_entry = decode_json( $lines[2] );
    is( $error_entry->{message}, 'error message', 'error message logged' );
};

subtest 'log level filtering - numeric level' => sub {
    my $tempfile      = Path::Tiny->tempfile;
    my $tempfile_path = q{} . $tempfile->path;

    # Clear the file
    $tempfile->spew(q{});

    # Set up adapter with numeric level 4 (warning)
    require Log::Any::Adapter;
    Log::Any::Adapter->set(
        'JSONLines',
        file      => $tempfile_path,
        log_level => 4                 # warning level
    );

    require Log::Any;
    my $log = Log::Any->get_logger();

    # Log messages at different levels
    $log->debug('debug message');    # Should NOT be logged (level 1 < 4)
    $log->info('info message');      # Should NOT be logged (level 2 < 4)
    $log->warn('warn message');      # Should be logged (level 4 >= 4)
    $log->error('error message');    # Should be logged (level 5 >= 4)

    my @lines = $tempfile->lines_utf8( { chomp => 1 } );

    is( scalar(@lines), 2, 'Only 2 messages logged with numeric level' );

    my $warn_entry = decode_json( $lines[0] );
    is( $warn_entry->{message}, 'warn message', 'warn message logged with numeric level' );

    my $error_entry = decode_json( $lines[1] );
    is( $error_entry->{message}, 'error message', 'error message logged with numeric level' );
};

subtest 'log level filtering - trace level (all messages)' => sub {
    my $tempfile      = Path::Tiny->tempfile;
    my $tempfile_path = q{} . $tempfile->path;

    # Clear the file
    $tempfile->spew(q{});

    # Set up adapter with trace level (lowest level, all messages should be logged)
    require Log::Any::Adapter;
    Log::Any::Adapter->set(
        'JSONLines',
        file      => $tempfile_path,
        log_level => 'trace'
    );

    require Log::Any;
    my $log = Log::Any->get_logger();

    # Log messages at different levels
    $log->trace('trace message');
    $log->debug('debug message');
    $log->info('info message');
    $log->warn('warn message');
    $log->error('error message');

    my @lines = $tempfile->lines_utf8( { chomp => 1 } );

    is( scalar(@lines), 5, 'All 5 messages logged with trace level' );
};

subtest 'log level filtering - emergency level (only emergency)' => sub {
    my $tempfile      = Path::Tiny->tempfile;
    my $tempfile_path = q{} . $tempfile->path;

    # Clear the file
    $tempfile->spew(q{});

    # Set up adapter with emergency level (highest level)
    require Log::Any::Adapter;
    Log::Any::Adapter->set(
        'JSONLines',
        file      => $tempfile_path,
        log_level => 'emergency'
    );

    require Log::Any;
    my $log = Log::Any->get_logger();

    # Log messages at different levels
    $log->trace('trace message');            # Should NOT be logged
    $log->debug('debug message');            # Should NOT be logged
    $log->info('info message');              # Should NOT be logged
    $log->warn('warn message');              # Should NOT be logged
    $log->error('error message');            # Should NOT be logged
    $log->critical('critical message');      # Should NOT be logged
    $log->emergency('emergency message');    # Should be logged

    my @lines = $tempfile->lines_utf8( { chomp => 1 } );

    is( scalar(@lines), 1, 'Only 1 message logged with emergency level' );

    my $emergency_entry = decode_json( $lines[0] );
    is( $emergency_entry->{message}, 'emergency message', 'emergency message logged' );
};

done_testing;
