#!/usr/bin/env perl

# Test use of local get_context->{foo} = ...

use Test::Most;

use Log::Log4perl;
use Log::Log4perl::MDC;

subtest "with include_mdc" => sub {

    my $conf = q(
        log4perl.rootLogger = INFO, Test
        log4perl.appender.Test = Log::Log4perl::Appender::String
        log4perl.appender.Test.layout = Log::Log4perl::Layout::JSON
        log4perl.appender.Test.layout.prefix = @cee:
        log4perl.appender.Test.layout.field.message = %m
        log4perl.appender.Test.layout.include_mdc = 1
        log4perl.appender.Test.layout.canonical = 1
    );
    Log::Log4perl::init( \$conf );
    Log::Log4perl::MDC->remove;

    ok my $appender = Log::Log4perl->appender_by_name("Test");

    my $logger = Log::Log4perl->get_logger('foo');

    {
        local Log::Log4perl::MDC->get_context->{foo} = 42;
        $logger->info('info message');
        is_deeply $appender->string(), '@cee:{"foo":42,"message":"info message"}'."\n";
    }
    $appender->string('');

    {
        local Log::Log4perl::MDC->get_context->{bar} = { baz => 1 };
        $logger->warn('warn message');
        is_deeply $appender->string(), '@cee:{"bar":{"baz":1},"message":"warn message"}'."\n";
    }
    $appender->string('');

};


subtest "with include_mdc with name_for_mdc" => sub {

    my $conf = q(
        log4perl.rootLogger = INFO, Test
        log4perl.appender.Test = Log::Log4perl::Appender::String
        log4perl.appender.Test.layout = Log::Log4perl::Layout::JSON
        log4perl.appender.Test.layout.prefix = @cee:
        log4perl.appender.Test.layout.field.message = %m
        log4perl.appender.Test.layout.include_mdc = 1
        log4perl.appender.Test.layout.name_for_mdc = mdc
        log4perl.appender.Test.layout.canonical = 1
    );
    Log::Log4perl::init( \$conf );
    Log::Log4perl::MDC->remove;

    ok my $appender = Log::Log4perl->appender_by_name("Test");

    my $logger = Log::Log4perl->get_logger('foo');

    {
        local Log::Log4perl::MDC->get_context->{foo} = 42;
        $logger->info('info message');
        is_deeply $appender->string(), '@cee:{"mdc":{"foo":42},"message":"info message"}'."\n";
    }
    $appender->string('');

};

done_testing();
