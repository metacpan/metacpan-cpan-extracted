#!/usr/bin/env perl

use utf8;
use Log::Log4perl;
use Test::Most;
use Encode;

subtest "format prefix" => sub {
    my $conf = q(
        log4perl.rootLogger = INFO, Test
        log4perl.appender.Test = Log::Log4perl::Appender::String
        log4perl.appender.Test.layout = Log::Log4perl::Layout::JSON
        log4perl.appender.Test.layout.prefix = %m{chomp} @cee:
        log4perl.appender.Test.layout.format_prefix = 1
        log4perl.appender.Test.layout.field.category = %c
        log4perl.appender.Test.layout.field.class = %C
        log4perl.appender.Test.layout.field.file = %F{1}
        log4perl.appender.Test.layout.field.sub = %M{1}
        log4perl.appender.Test.layout.name_for_mdc = context
        log4perl.appender.Test.layout.canonical = 1
    );
    Log::Log4perl::init( \$conf );

    ok my $appender = Log::Log4perl->appender_by_name("Test");
    Log::Log4perl::MDC->get_context->{foo} = 'bar';

    my $logger = Log::Log4perl->get_logger('foo');

    $logger->info('info message');
    is $appender->string(),
        'info message @cee:{"category":"foo","class":"main","file":"format-prefix.t","sub":"__ANON__"}'."\n";
    $appender->string('');
};

# if format_prefix is off, then prefix is literal
subtest "unformat prefix" => sub {
    my $conf = q(
        log4perl.rootLogger = INFO, Test
        log4perl.appender.Test = Log::Log4perl::Appender::String
        log4perl.appender.Test.layout = Log::Log4perl::Layout::JSON
        log4perl.appender.Test.layout.prefix = %m{chomp} @cee:
        log4perl.appender.Test.layout.format_prefix = 0
        log4perl.appender.Test.layout.field.message = %m
        log4perl.appender.Test.layout.field.category = %c
        log4perl.appender.Test.layout.field.class = %C
        log4perl.appender.Test.layout.field.file = %F{1}
        log4perl.appender.Test.layout.field.sub = %M{1}
        log4perl.appender.Test.layout.name_for_mdc = context
        log4perl.appender.Test.layout.canonical = 1
    );
    Log::Log4perl::init( \$conf );

    ok my $appender = Log::Log4perl->appender_by_name("Test");
    Log::Log4perl::MDC->get_context->{foo} = 'bar';

    my $logger = Log::Log4perl->get_logger('foo');

    $logger->info('info message');
    is $appender->string(),
        '%m{chomp} @cee:{"category":"foo","class":"main","file":"format-prefix.t","message":"info message","sub":"__ANON__"}'."\n";
    $appender->string('');
};

done_testing;
