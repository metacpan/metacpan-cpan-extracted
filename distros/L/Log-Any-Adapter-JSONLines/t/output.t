#!perl
## no critic (ValuesAndExpressions::ProhibitMagicNumbers)
use strict;
use warnings;

our $VERSION = 0.001;

use utf8;
use Test2::V0;
set_encoding('utf8');

use JSON qw( decode_json encode_json );

use Path::Tiny qw( path );

my $tempfile_path;

BEGIN {
    my $tempfile = Path::Tiny->tempfile;
    $tempfile_path = q{} . $tempfile->path;
}

use Log::Any qw($log);
use Log::Any::Adapter 'JSONLines', file => $tempfile_path;

# last line logged
sub last_line {
    my $line = ( path($tempfile_path)->lines_utf8( { chomp => 1 } ) )[-1];
    return decode_json $line;
}

subtest 'plain string' => sub {
    $log->debug('hello, world');
    is(
        last_line(),
        {
            message => 'hello, world',
        },
        'plain string logged as-is',
    );
    $log->debug('こんにちは世界');
    is(
        last_line(),
        {
            message => 'こんにちは世界',
        },
        'plain high-bit utf8 string logged as-is',
    );
};

subtest 'structure' => sub {
    $log->debug( 'hello, world', { age => 123, name => 'Smith' } );
    is(
        last_line(),
        {
            message => 'hello, world',
            age     => 123,
            name    => 'Smith',
        },
        'plain string with structure',
    );
    $log->debug( { age => '123', name => 'Smith' } );
    is(
        last_line(),
        {
            age  => '123',
            name => 'Smith',
        },
        'only structure',
    );
    $log->debug( { age => 123, name => 'Smith' }, { gender => 'F' } );
    is(
        last_line(),
        {
            messages => [
                {
                    age  => '123',
                    name => 'Smith',
                },
                {
                    gender => 'F',
                }
            ],
        },
        'two structures',
    );

    $log->debug( 'hello, world', sub { 'Tester'; } );
    is(
        last_line(),
        {
            messages => [ 'hello, world', 'Tester', ],
        },
        'plain string and code',
    );
    $log->debug( sub { 'Tester'; }, 'hello, world' );
    is(
        last_line(),
        {
            messages => [ 'Tester', 'hello, world', ],
        },
        'code and plain string',
    );
    $log->debug( 'hello, world', { age => 123, name => 'Smith' }, sub { 'Tester'; }, [ 1, 2, 3 ] );
    is(
        last_line(),
        {
            messages => [
                'hello, world',
                {
                    age  => '123',
                    name => 'Smith',
                },
                'Tester',
                [ 1, 2, 3 ],
            ],
        },
        'plain string, hash, code and array',
    );
    $log->debug( [ 1, 2, 3 ] );
    is(
        last_line(),
        {
            messages => [ 1, 2, 3, ],
        },
        'only array',
    );
};

subtest 'hooks' => sub {

    # Test that a single hook is called and can modify the log entry
    my $tempfile_hooks      = Path::Tiny->tempfile;
    my $tempfile_hooks_path = q{} . $tempfile_hooks->path;

    my $hook_called   = 0;
    my $add_hook_data = sub {
        my ( $level, $category, $log_entry ) = @_;
        $hook_called++;
        $log_entry->{hook_executed} = 1;
        $log_entry->{hook_level}    = $level;
        $log_entry->{hook_category} = $category;
        return;
    };

    Log::Any::Adapter->set(
        'JSONLines',
        file  => $tempfile_hooks_path,
        hooks => {
            before => [$add_hook_data],
        }
    );
    my $log_hooks = Log::Any->get_logger;

    $hook_called = 0;
    $log_hooks->info('test message');

    my $line   = ( path($tempfile_hooks_path)->lines_utf8( { chomp => 1 } ) )[-1];
    my $result = decode_json $line;

    is( $hook_called, 1, 'single hook was called once' );
    is(
        $result,
        {
            message       => 'test message',
            hook_executed => 1,
            hook_level    => 'info',
            hook_category => 'main',
        },
        'single hook modified the log entry',
    );
};

subtest 'multiple hooks in order' => sub {

    # Test that multiple hooks are executed in the order they are defined
    my $tempfile_multi      = Path::Tiny->tempfile;
    my $tempfile_multi_path = q{} . $tempfile_multi->path;

    my @hook_execution_order = ();

    my $first_hook = sub {
        my ( $level, $category, $log_entry ) = @_;
        push @hook_execution_order, 'first';
        $log_entry->{step1} = 'first';
        return;
    };

    my $second_hook = sub {
        my ( $level, $category, $log_entry ) = @_;
        push @hook_execution_order, 'second';
        $log_entry->{step2} = 'second';
        return;
    };

    my $third_hook = sub {
        my ( $level, $category, $log_entry ) = @_;
        push @hook_execution_order, 'third';
        $log_entry->{step3} = 'third';
        return;
    };

    Log::Any::Adapter->set(
        'JSONLines',
        file  => $tempfile_multi_path,
        hooks => {
            before => [ $first_hook, $second_hook, $third_hook ],
        }
    );
    my $log_multi = Log::Any->get_logger;

    @hook_execution_order = ();
    $log_multi->debug('testing order');

    is( \@hook_execution_order, [ 'first', 'second', 'third' ], 'hooks executed in correct order' );

    my $line   = ( path($tempfile_multi_path)->lines_utf8( { chomp => 1 } ) )[-1];
    my $result = decode_json $line;

    is(
        $result,
        {
            message => 'testing order',
            step1   => 'first',
            step2   => 'second',
            step3   => 'third',
        },
        'multiple hooks all modified the log entry',
    );
};

subtest 'hooks can transform log entry' => sub {

    # Test that hooks can transform the log entry (delete/rename fields)
    my $tempfile_transform      = Path::Tiny->tempfile;
    my $tempfile_transform_path = q{} . $tempfile_transform->path;

    my $TEST_TIMESTAMP = 1_234_567_890;

    my $transform_hook = sub {
        my ( $level, $category, $log_entry ) = @_;

        # Rename message to msg
        $log_entry->{msg} = delete $log_entry->{message};

        # Add timestamp (using variable for test reproducibility)
        $log_entry->{ts} = $TEST_TIMESTAMP;

        # Add level abbreviation
        $log_entry->{lvl} = $level;
        return;
    };

    Log::Any::Adapter->set(
        'JSONLines',
        file  => $tempfile_transform_path,
        hooks => {
            before => [$transform_hook],
        }
    );
    my $log_transform = Log::Any->get_logger;

    $log_transform->warn('original message');

    my $line   = ( path($tempfile_transform_path)->lines_utf8( { chomp => 1 } ) )[-1];
    my $result = decode_json $line;

    is(
        $result,
        {
            msg => 'original message',
            ts  => $TEST_TIMESTAMP,
            lvl => 'warning',
        },
        'hook transformed the log entry (renamed field, added fields)',
    );

    ok( !exists $result->{message}, 'original message field was deleted' );
};

subtest 'hooks with structured data' => sub {

    # Test that hooks work with structured logging
    my $tempfile_struct      = Path::Tiny->tempfile;
    my $tempfile_struct_path = q{} . $tempfile_struct->path;

    my $enrich_hook = sub {
        my ( $level, $category, $log_entry ) = @_;
        $log_entry->{enriched} = 'yes';
        $log_entry->{user}     = 'Harry';
        return;
    };

    Log::Any::Adapter->set(
        'JSONLines',
        file  => $tempfile_struct_path,
        hooks => {
            before => [$enrich_hook],
        }
    );
    my $log_struct = Log::Any->get_logger;

    $log_struct->error( 'error occurred', { code => 500, user => 'john' } );

    my $line   = ( path($tempfile_struct_path)->lines_utf8( { chomp => 1 } ) )[-1];
    my $result = decode_json $line;

    is(
        $result,
        {
            message  => 'error occurred',
            code     => 500,
            user     => 'Harry',
            enriched => 'yes',
        },
        'hook works with structured logging data',
    );
};

done_testing;
