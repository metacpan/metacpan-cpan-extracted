#!/usr/bin/env perl

use strict;
use warnings;

package Log::Declare::t;

use Test::More tests => 5;

###
#
# This test looks a bit weird - its because we're testing *compile* time output
#
###

our $init_stderr;

BEGIN {
    no warnings 'once';

    # Capture STDERR and reopen it attached to a variable
    my $stderr;
    open SAVEERR, ">&STDERR";
    close STDERR;
    open STDERR, '>', \$stderr;

    # Needs to be done this way so we can capture STDERR
    # otherwise the use statement gets compiled earlier before the BEGIN{} block executes
    require "Log/Declare.pm"; # Needs to be imported so the test compiles
    "Log::Declare"->import;

    # Close the new STDERR and point it back to the original
    close STDERR;
    open STDERR, ">&SAVEERR";

    chomp $stderr if $stderr;

    $Log::Declare::t::init_stderr = $stderr;
}

test_method_import();
test_method_parser();
test_method_namespace();
test_method_auto();
test_method_capture();

done_testing();

# =============================================================================

sub test_method_import {
    subtest "Test import" => sub {
        plan tests => 6;

        ok(defined &{'Log::Declare::t::trace'}, "Trace level is defined");
        ok(defined &{'Log::Declare::t::debug'}, "Debug level is defined");
        ok(defined &{'Log::Declare::t::error'}, "Error level is defined");
        ok(defined &{'Log::Declare::t::warn' }, "Warn level is defined");
        ok(defined &{'Log::Declare::t::info' }, "Info level is defined");
        ok(defined &{'Log::Declare::t::audit'}, "Audit level is defined");
    };
    return;
}

# -----------------------------------------------------------------------------

sub test_method_parser {
    subtest "Test log statement parser" => sub {
        plan tests => 24;

        # Capture STDERR and reopen it attached to a variable
        open SAVEERR, ">&STDERR";
        close STDERR;
        my $stderr = '';
        open STDERR, '>', \$stderr;

        Log::Declare->startup_level('TRACE');

        trace "message";
        chomp $stderr;
        like($stderr, qr/\[\w+\s+\w+\s+\d+\s\d+:\d+:\d+\s\d+\]\s\[TRACE\]\s\[GENERAL\]\smessage/, 'Test trace level');
        $stderr = '';

        debug "message";
        chomp $stderr;
        like($stderr, qr/\[\w+\s+\w+\s+\d+\s\d+:\d+:\d+\s\d+\]\s\[DEBUG\]\s\[GENERAL\]\smessage/, 'Test debug level');
        $stderr = '';

        error "message";
        chomp $stderr;
        like($stderr, qr/\[\w+\s+\w+\s+\d+\s\d+:\d+:\d+\s\d+\]\s\[ERROR\]\s\[GENERAL\]\smessage/, 'Test error level');
        $stderr = '';

        warn "message";
        chomp $stderr;
        like($stderr, qr/\[\w+\s+\w+\s+\d+\s\d+:\d+:\d+\s\d+\]\s\[WARN\]\s\[GENERAL\]\smessage/, 'Test warn level');
        $stderr = '';

        info "message";
        chomp $stderr;
        like($stderr, qr/\[\w+\s+\w+\s+\d+\s\d+:\d+:\d+\s\d+\]\s\[INFO\]\s\[GENERAL\]\smessage/, 'Test info level');
        $stderr = '';

        audit "message";
        chomp $stderr;
        like($stderr, qr/\[\w+\s+\w+\s+\d+\s\d+:\d+:\d+\s\d+\]\s\[AUDIT\]\s\[GENERAL\]\smessage/, 'Test audit level');
        $stderr = '';

        my $a1 = 1;
        info "message" if $a1;
        chomp $stderr;
        like($stderr, qr/\[\w+\s+\w+\s+\d+\s\d+:\d+:\d+\s\d+\]\s\[INFO\]\s\[GENERAL\]\smessage/, 'Test statement with if conditional');
        $stderr = '';

        $a1 = 0;
        info "message" unless $a1;
        chomp $stderr;
        like($stderr, qr/\[\w+\s+\w+\s+\d+\s\d+:\d+:\d+\s\d+\]\s\[INFO\]\s\[GENERAL\]\smessage/, 'Test statement with unless conditional');
        $stderr = '';

        $a1 = 1;
        info "message" unless $a1;
        chomp $stderr;
        like($stderr, qr/^$/, 'Test statement with failing unless conditional');
        $stderr = '';

        $a1 = 0;
        info "message" if $a1;
        chomp $stderr;
        like($stderr, qr/^$/, 'Test statement with failing if conditional');
        $stderr = '';

        my $h = {
            test => [
                1,
                2,
                3
            ]
        };
        info "Test hashref array access %s", $h->{test}->[0];
        like($stderr, qr/Test hashref array access 1/, 'Hashref array access');
        $stderr = '';

        info "Test hashref array access %s", $h->{test}->[0] [cat1]
        like($stderr, qr/Test hashref array access 1/, 'Hashref array access with categories');
        $stderr = '';

        my $isweak = 1;
        info "Is event handler weak?  ".($isweak ? 'Yes' : 'No')."\n";
        like($stderr, qr/Is event handler weak\?  Yes\n/, 'Ternary operation');
        $stderr = '';

        info "message %s", 1;
        chomp $stderr;
        like($stderr, qr/\[\w+\s+\w+\s+\d+\s\d+:\d+:\d+\s\d+\]\s\[INFO\]\s\[GENERAL\]\smessage 1/, 'Test single argument sprintf');
        $stderr = '';

        info "message %s %s", 1, 2;
        chomp $stderr;
        like($stderr, qr/\[\w+\s+\w+\s+\d+\s\d+:\d+:\d+\s\d+\]\s\[INFO\]\s\[GENERAL\]\smessage 1 2/, 'Test multiple argument sprintf');
        $stderr = '';

        my $a = 'a'; my $b = 'b';

        info "message %s %s", $a, $b;
        chomp $stderr;
        like($stderr, qr/\[\w+\s+\w+\s+\d+\s\d+:\d+:\d+\s\d+\]\s\[INFO\]\s\[GENERAL\]\smessage a b/, 'Test multiple argument sprintf with variables');
        $stderr = '';

        info "message" [cat1];
        chomp $stderr;
        like($stderr, qr/\[\w+\s+\w+\s+\d+\s\d+:\d+:\d+\s\d+\]\s\[INFO\]\s\[CAT1\]\smessage/, 'Test single categories');
        $stderr = '';

        info "message" [cat1, cat2];
        chomp $stderr;
        like($stderr, qr/\[\w+\s+\w+\s+\d+\s\d+:\d+:\d+\s\d+\]\s\[INFO\]\s\[CAT1,\sCAT2\]\smessage/, 'Test multiple categories');
        $stderr = '';

        info "message %s", 1 [cat1];
        chomp $stderr;
        like($stderr, qr/\[\w+\s+\w+\s+\d+\s\d+:\d+:\d+\s\d+\]\s\[INFO\]\s\[CAT1\]\smessage 1/, 'Test single categories with single argument sprintf');
        $stderr = '';

        info "message %s %s", 1, 2 [cat1];
        chomp $stderr;
        like($stderr, qr/\[\w+\s+\w+\s+\d+\s\d+:\d+:\d+\s\d+\]\s\[INFO\]\s\[CAT1\]\smessage 1 2/, 'Test single categories with multiple argument sprintf');
        $stderr = '';

        info "message %s %s", $a [cat1];
        chomp $stderr;
        like($stderr, qr/\[\w+\s+\w+\s+\d+\s\d+:\d+:\d+\s\d+\]\s\[INFO\]\s\[CAT1\]\smessage a/, 'Test single categories with single argument sprintf with variables');
        $stderr = '';

        info "message %s %s", $a, $b [cat1];
        chomp $stderr;
        like($stderr, qr/\[\w+\s+\w+\s+\d+\s\d+:\d+:\d+\s\d+\]\s\[INFO\]\s\[CAT1\]\smessage a b/, 'Test single categories with multiple argument sprintf with variables');
        $stderr = '';

        info "message %s %s", $a, $b [cat1, cat2];
        chomp $stderr;
        like($stderr, qr/\[\w+\s+\w+\s+\d+\s\d+:\d+:\d+\s\d+\]\s\[INFO\]\s\[CAT1,\sCAT2\]\smessage a b/, 'Test multiple categories with multiple argument sprintf with variables');
        $stderr = '';

        my ($answer, $question, $foo) = ('','','');
        info "A [%s] B [%s]", $answer, $question [Consent, Validate];
        chomp $stderr;
        like($stderr, qr/\[\w+\s+\w+\s+\d+\s\d+:\d+:\d+\s\d+\]\s\[INFO\]\s\[CONSENT,\sVALIDATE\]\sA\s\[\]\sB\s\[\]/, 'Test bug');
        $stderr = '';

        # TODO this used to work with manual parsing, Devel::Declare::Lexer seems to struggle
        info
            "message %s %s",
            $a,
            $b
            [cat1, cat2];
        chomp $stderr;
        like($stderr, qr/\[\w+\s+\w+\s+\d+\s\d+:\d+:\d+\s\d+\]\s\[INFO\]\s\[CAT1,\sCAT2\]\smessage a b/, 'Test multiple categories with multiple argument sprintf with variables and newlines');
        $stderr = '';

        # Close the new STDERR and point it back to the original
        close STDERR;
        open STDERR, ">&SAVEERR";
    };
    return;
}

# -----------------------------------------------------------------------------

sub test_method_namespace {
    subtest "Test namespace awareness" => sub {
        plan tests => 3;

        # limit %levels changes to this scope
        local %Log::Declare::levels;

        # Capture STDERR and reopen it attached to a variable
        open SAVEERR, ">&STDERR";
        close STDERR;
        my $stderr = '';
        open STDERR, '>', \$stderr;

        Log::Declare->startup_level('TRACE');

        $Log::Declare::levels{'trace'} = sub {
            return 0;
        };
        trace "message";
        chomp $stderr;
        like($stderr, qr/^$/, 'Test disabled log level');
        $stderr = '';

        $Log::Declare::levels{'trace'} = sub {
            return 1;
        };
        trace "message";
        chomp $stderr;
        like($stderr, qr/\[\w+\s+\w+\s+\d+\s\d+:\d+:\d+\s\d+\]\s\[TRACE\]\s\[GENERAL\]\smessage/, 'Test enabled log level');
        $stderr = '';

        $Log::Declare::levels{'trace'} = sub {
            my @caller = caller;
            is($caller[0], 'Log::Declare::t', 'Caller is correct');
            return 0;
        };
        trace "message";

        # Close the new STDERR and point it back to the original
        close STDERR;
        open STDERR, ">&SAVEERR";
    };
    return;
}

# -----------------------------------------------------------------------------

sub test_method_auto {
    subtest "Test auto-dump and auto-ref" => sub {
        plan tests => 2;

        # Capture STDERR and reopen it attached to a variable
        open SAVEERR, ">&STDERR";
        close STDERR;
        my $stderr = '';
        open STDERR, '>', \$stderr;

        Log::Declare->startup_level('TRACE');

        my $var = 'test';
        trace "message %s", d:$var;
        chomp $stderr;
        like($stderr, qr/\[\w+\s+\w+\s+\d+\s\d+:\d+:\d+\s\d+\]\s\[TRACE\]\s\[GENERAL\]\smessage\s\$VAR1\s=\s'test'/, 'Test auto dump');
        $stderr = '';

        $var = {};
        trace "message %s", r:$var;
        chomp $stderr;
        like($stderr, qr/\[\w+\s+\w+\s+\d+\s\d+:\d+:\d+\s\d+\]\s\[TRACE\]\s\[GENERAL\]\smessage\sHASH/, 'Test auto ref');
        $stderr = '';

        # Close the new STDERR and point it back to the original
        close STDERR;
        open STDERR, ">&SAVEERR";
    };
    return;
}

# -----------------------------------------------------------------------------

sub test_method_capture {
    subtest "Test capture" => sub {
        plan tests => 2;

        # Capture STDERR and reopen it attached to a variable
        open SAVEERR, ">&STDERR";
        close STDERR;
        my $stderr = '';
        open STDERR, '>', \$stderr;

        Log::Declare->startup_level('TRACE');

        eval {
            package Test::Logger;

            sub new {
                return bless {}, 'Test::Logger';
            }

            sub log {
                my ($self, $message) = @_;
                print STDERR "FAIL: $message\n";
            }
        };

        my $logger = Test::Logger->new;

        Log::Declare->capture('Test::Logger::log');

        $logger->log("test");
        chomp $stderr;
        like($stderr, qr/\[\w+\s+\w+\s+\d+\s\d+:\d+:\d+\s\d+\]\s\[DEBUG\]\s\[Test::Logger\]\stest/, 'Test auto-capture');
        $stderr = '';

        Log::Declare->capture('Test::Logger::log' => sub {
            my ($self, $message) = @_;
            return "Intercepted";
        });

        $logger->log("test");
        chomp $stderr;
        like($stderr, qr/\[\w+\s+\w+\s+\d+\s\d+:\d+:\d+\s\d+\]\s\[DEBUG\]\s\[Test::Logger\]\sIntercepted/, 'Test intercepted capture');
        $stderr = '';

        # Close the new STDERR and point it back to the original
        close STDERR;
        open STDERR, ">&SAVEERR";
    };
    return;
}
