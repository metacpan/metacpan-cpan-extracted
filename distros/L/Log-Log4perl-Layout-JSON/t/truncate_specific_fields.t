#!/usr/bin/env perl

use Test::Most;

use Log::Log4perl;

use utf8;
use Encode;

subtest "no complex fields" => sub {

    my $conf = q(
        log4perl.rootLogger = INFO, Test
        log4perl.appender.Test = Log::Log4perl::Appender::String
        log4perl.appender.Test.layout = Log::Log4perl::Layout::JSON

        log4perl.appender.Test.layout.field.message = %m
        log4perl.appender.Test.layout.maxkb.message = 1

        log4perl.appender.Test.layout.canonical = 1
    );
    Log::Log4perl::init( \$conf );
    Log::Log4perl::MDC->remove;

    ok my $appender = Log::Log4perl->appender_by_name("Test");

    my $logger = Log::Log4perl->get_logger('foo');

    $logger->info('very long message ' x 100);

    my $got = $appender->string();
    my $expected = '{"message":"very long message very long message very long message very'.
        ' long message very long message very long message very long message very long message'.
        ' very long message very long message very long message very long message very long'.
        ' message very long message very long message very long message very long message very'.
        ' long message very long message very long message very long message very long message very'.
        ' long message very long message very long message very long message very long message very long message very'.
        ' long message very long message very long message very long message very long message'.
        ' very long message very long message very long message very long message very long message'.
        ' very long message very long message very long message very long message very long message'.
        ' very long message very long message very long message very long message very long message'.
        ' very long message very long message very long message very long message very long message'.
        ' very long message very long mes...[truncated, was 1800 chars total]..."}'
        ."\n";

    is_deeply $got, $expected;

    $appender->string('');
};

subtest "with complex field" => sub {

    my $conf = q(
        log4perl.rootLogger = INFO, Test
        log4perl.appender.Test = Log::Log4perl::Appender::String
        log4perl.appender.Test.layout = Log::Log4perl::Layout::JSON

        log4perl.appender.Test.layout.field.deep.structure.message = %m
        log4perl.appender.Test.layout.maxkb.deep.structure.message = 1

        log4perl.appender.Test.layout.canonical = 1
    );
    Log::Log4perl::init( \$conf );
    Log::Log4perl::MDC->remove;

    ok my $appender = Log::Log4perl->appender_by_name("Test");

    my $logger = Log::Log4perl->get_logger('foo');

    $logger->info('very long message ' x 100);

    my $got = $appender->string();
    my $expected = '{"deep":{"structure":{"message":"very long message'.
        ' very long message very long message very long message very'.
        ' long message very long message very long message very long'.
        ' message very long message very long message very long message'.
        ' very long message very long message very long message very long'.
        ' message very long message very long message very long message very'.
        ' long message very long message very long message very long message very'.
        ' long message very long message very long message very long message very'.
        ' long message very long message very long message very long message very'.
        ' long message very long message very long message very long message very'.
        ' long message very long message very long message very long message very'.
        ' long message very long message very long message very long message very'.
        ' long message very long message very long message very long message very'.
        ' long message very long message very long message very long message very'.
        ' long message very long message very long message very long message very'.
        ' long mes...[truncated, was 1800 chars total]..."}}}'.
        "\n";

    is_deeply $got, $expected;

    $appender->string('');
};


done_testing();
