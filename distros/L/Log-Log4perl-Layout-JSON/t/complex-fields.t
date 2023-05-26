#!/usr/bin/env perl

use utf8;

use Encode;
use Log::Log4perl;
use Test::Most;
use Test::Warnings;

sub hello {
  +{ hello => 'world' };
}

subtest "no mdc" => sub {
    my $conf = q(
        log4perl.rootLogger = INFO, Test
        log4perl.appender.Test = Log::Log4perl::Appender::String
        log4perl.appender.Test.layout = Log::Log4perl::Layout::JSON
        log4perl.appender.Test.layout.field.message = %m
        log4perl.appender.Test.layout.field.category = %c
        log4perl.appender.Test.layout.field.class = %C
        log4perl.appender.Test.layout.field.file = %F{1}
        log4perl.appender.Test.layout.field.AAAA.BBBB.SUB = %M{1}
        log4perl.appender.Test.layout.field.AAAA.BBBB.CODE = sub {\&hello}
        log4perl.appender.Test.layout.field.BBBB.AAAA.FILE = %F{1}
        log4perl.appender.Test.layout.canonical = 1
    );
    Log::Log4perl::init( \$conf );
    Log::Log4perl::MDC->remove;

    ok my $appender = Log::Log4perl->appender_by_name("Test");

    my $logger = Log::Log4perl->get_logger('foo');

    $logger->info('info message');

    my $got = $appender->string();
    my $expected = '{"AAAA":{"BBBB":{"CODE":{"hello":"world"},"SUB":"__ANON__"}},"BBBB":{"AAAA":{"FILE":"complex-fields.t"}},"category":"foo","class":"main","file":"complex-fields.t","message":"info message"}'."\n";

    is_deeply $got, $expected;

    $appender->string('');
};

subtest "value field as hash" => sub {
    my $conf = q(
        log4perl.rootLogger = INFO, Test
        log4perl.appender.Test = Log::Log4perl::Appender::String
        log4perl.appender.Test.layout = Log::Log4perl::Layout::JSON
        log4perl.appender.Test.layout.canonical = 1
        log4perl.appender.Test.layout.field.AAAA.BBBB.value = %F{1}
        log4perl.appender.Test.layout.field.AAAA.value.CCCC = sub {\&hello}
        log4perl.appender.Test.layout.field.value.BBBB.CCCC = %M{1}
        log4perl.appender.Test.layout.field.AAAA.value.value = %M{1}
        log4perl.appender.Test.layout.field.value.BBBB.value = %M{1}
        log4perl.appender.Test.layout.field.value.value.CCCC = %M{1}
        log4perl.appender.Test.layout.field.value.value.value = %M{1}
    );
    Log::Log4perl::init( \$conf );
    Log::Log4perl::MDC->remove;

    ok my $appender = Log::Log4perl->appender_by_name("Test");

    my $logger = Log::Log4perl->get_logger('foo');

    $logger->info('info message');

    my $got = $appender->string();
    my $expected = '{"AAAA":{"BBBB":{"value":"complex-fields.t"},"value":{"CCCC":{"hello":"world"},"value":"__ANON__"}},"value":{"BBBB":{"CCCC":"__ANON__","value":"__ANON__"},"value":{"CCCC":"__ANON__","value":"__ANON__"}}}'."\n";

    is_deeply $got, $expected;

    $appender->string('');
};

subtest 'deep hash references fix' => sub {
    my $conf = q(
        log4perl.appender.Test = Log::Log4perl::Appender::String
        log4perl.appender.Test.layout = Log::Log4perl::Layout::JSON
        log4perl.appender.Test.layout.field.message = %m
        log4perl.appender.Test.layout.field.category = %c
        log4perl.appender.Test.layout.field.class = %C
        log4perl.appender.Test.layout.field.file = %F{1}
        log4perl.appender.Test.layout.field.sub = %M{1}
        log4perl.appender.Test.layout.canonical = 1

        log4perl.category.TestDebug = DEBUG, Test
        log4perl.category.TestInfo = INFO, Test
    );
    Log::Log4perl::init( \$conf );
    Log::Log4perl::MDC->remove;

    ok my $appender = Log::Log4perl->appender_by_name("Test");

    my $info_logger = Log::Log4perl->get_logger('TestInfo');
    $info_logger->debug('debug message');
    is_deeply $appender->string(), '';

    $info_logger->info('info message');
    is_deeply $appender->string(), '{"category":"TestInfo","class":"main","file":"complex-fields.t","message":"info message","sub":"__ANON__"}'."\n";
    $appender->string('');

    my $debug_logger = Log::Log4perl->get_logger('TestDebug');
    $debug_logger->debug('debug message');
    is_deeply $appender->string(), '{"category":"TestDebug","class":"main","file":"complex-fields.t","message":"debug message","sub":"__ANON__"}'."\n";
    $appender->string('');

};

done_testing();
