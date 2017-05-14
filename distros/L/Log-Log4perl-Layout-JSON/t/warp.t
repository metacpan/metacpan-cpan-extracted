#!/usr/bin/env perl

use Test::Most;

use Log::Log4perl;

use utf8;
use Encode;

subtest "no_warp_message" => sub {

    my $conf = q(
        log4perl.rootLogger = INFO, Test
        log4perl.appender.Test = Log::Log4perl::Appender::String
        log4perl.appender.Test.layout = Log::Log4perl::Layout::JSON
        log4perl.appender.Test.layout.field.message = %m
        log4perl.appender.Test.layout.field.category = %c
        log4perl.appender.Test.layout.field.class = %C
        log4perl.appender.Test.layout.field.file = %F{1}
        log4perl.appender.Test.layout.field.sub = %M{1}
        log4perl.appender.Test.layout.canonical = 1
    );
    Log::Log4perl::init( \$conf );
    Log::Log4perl::MDC->remove;

    ok my $appender = Log::Log4perl->appender_by_name("Test");

    my $logger = Log::Log4perl->get_logger('foo');

    $Log::Log4perl::JOIN_MSG_ARRAY_CHAR="";
    $logger->info('info', 'message');
    is_deeply $appender->string(), '{"category":"foo","class":"main","file":"warp.t","message":"infomessage","sub":"__ANON__"}'."\n";
    $appender->string('');
};

subtest "warp_message_even" => sub {

    my $conf = q(
        log4perl.rootLogger = INFO, Test
        log4perl.appender.Test = Log::Log4perl::Appender::String
        log4perl.appender.Test.layout = Log::Log4perl::Layout::JSON
        log4perl.appender.Test.layout.field.message = %m
        log4perl.appender.Test.layout.field.category = %c
        log4perl.appender.Test.layout.field.class = %C
        log4perl.appender.Test.layout.field.file = %F{1}
        log4perl.appender.Test.layout.field.sub = %M{1}
        log4perl.appender.Test.layout.canonical = 1

        log4perl.appender.Test.warp_message = 0
    );
    Log::Log4perl::init( \$conf );
    Log::Log4perl::MDC->remove;

    ok my $appender = Log::Log4perl->appender_by_name("Test");

    my $logger = Log::Log4perl->get_logger('foo');

    $Log::Log4perl::JOIN_MSG_ARRAY_CHAR="";
    $logger->info('info', 'message');
    is_deeply $appender->string(), '{"category":"foo","class":"main","file":"warp.t","info":"message","sub":"__ANON__"}'."\n";
    $appender->string('');

    $logger->warn('info', 'message', 'info2', 'message2');
    is_deeply $appender->string(), '{"category":"foo","class":"main","file":"warp.t","info":"message","info2":"message2","sub":"__ANON__"}'."\n";
    $appender->string('');
};

subtest "warp_message_odd" => sub {

    my $conf = q(
        log4perl.rootLogger = INFO, Test
        log4perl.appender.Test = Log::Log4perl::Appender::String
        log4perl.appender.Test.layout = Log::Log4perl::Layout::JSON
        log4perl.appender.Test.layout.field.message = %m
        log4perl.appender.Test.layout.field.category = %c
        log4perl.appender.Test.layout.field.class = %C
        log4perl.appender.Test.layout.field.file = %F{1}
        log4perl.appender.Test.layout.field.sub = %M{1}
        log4perl.appender.Test.layout.canonical = 1

        log4perl.appender.Test.warp_message = 0
    );
    Log::Log4perl::init( \$conf );
    Log::Log4perl::MDC->remove;

    ok my $appender = Log::Log4perl->appender_by_name("Test");

    my $logger = Log::Log4perl->get_logger('foo');

    $Log::Log4perl::JOIN_MSG_ARRAY_CHAR="";
    $logger->info('info', 'foo', 'bar');
    is_deeply $appender->string(), '{"category":"foo","class":"main","file":"warp.t","foo":"bar","message":"info","sub":"__ANON__"}'."\n";
    $appender->string('');
};

done_testing();
