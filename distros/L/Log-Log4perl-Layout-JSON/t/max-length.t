#!/usr/bin/env perl

use Test::Most;

use Log::Log4perl;


my $too_long_string = 'f' x 120;
my $max_json_length_kb = ( length($too_long_string) * 0.8 ) / 1024;

my $conf = qq(
    log4perl.rootLogger = INFO, Test
    log4perl.appender.Test = Log::Log4perl::Appender::String
    log4perl.appender.Test.layout = Log::Log4perl::Layout::JSON
    log4perl.appender.Test.layout.field.message = %m
    log4perl.appender.Test.layout.include_mdc = 1
    log4perl.appender.Test.layout.max_json_length_kb = $max_json_length_kb
    log4perl.appender.Test.layout.canonical = 1
);
Log::Log4perl::init( \$conf );

ok my $appender = Log::Log4perl->appender_by_name("Test");
ok my $logger  = Log::Log4perl->get_logger('foo');



subtest "max_json_length_kb truncate mdc field" => sub {

    open my $fh, ">", \my $str or die $!;
    local *STDERR = $fh;

    Log::Log4perl::MDC->remove;
    Log::Log4perl::MDC->put('foo', $too_long_string);

    $logger->info('info message');
    is $str, "Error encoding Log::Log4perl::Layout::JSON: length 155 > 96 (truncated foo from 120 to 48, retrying)\n",
        'correct warning';
    is $appender->string(), '{"foo":"ffffffffff...[truncated, was 120 chars total]...","message":"info message"}'."\n",
        'correct log output';
    $str = '';                 # reset stderr message buffer
    $appender->string('');     # reset log output buffer

    is scalar Log::Log4perl::MDC->get('foo'), $too_long_string,
        "mdc field untouched";

};


subtest "max_json_length_kb truncate and drop" => sub {

    open my $fh, ">", \my $str or die $!;
    local *STDERR = $fh;

    Log::Log4perl::MDC->remove;
    Log::Log4perl::MDC->put('foo', $too_long_string);

    $logger->info($too_long_string);
    is $str, "Error encoding Log::Log4perl::Layout::JSON: length 263 > 96 (truncated message from 120 to 48, truncated foo from 120 to 48, retrying)\n"
            ."Error encoding Log::Log4perl::Layout::JSON: length 119 > 96 (retrying without foo)\n";
    is $appender->string(), '{"message":"ffffffffff...[truncated, was 120 chars total]..."}'."\n";
    $str = '';                 # reset stderr message buffer
    $appender->string('');     # reset log output buffer

};


subtest "max_json_length_kb drop many mdc fields" => sub {

    open my $fh, ">", \my $str or die $!;
    local *STDERR = $fh;

    Log::Log4perl::MDC->remove;
    Log::Log4perl::MDC->put($_, $_) for (10..20);

    $logger->info("hello world");
    is $str, "Error encoding Log::Log4perl::Layout::JSON: length 113 > 96 (retrying without 20)\n"
            ."Error encoding Log::Log4perl::Layout::JSON: length 105 > 96 (retrying without 20, 19)\n"
            ."Error encoding Log::Log4perl::Layout::JSON: length 97 > 96 (retrying without 20, 19, 18)\n";
    is $appender->string(), '{"10":10,"11":11,"12":12,"13":13,"14":14,"15":15,"16":16,"17":17,"message":"hello world"}'."\n";
    $str = '';                 # reset stderr message buffer
    $appender->string('');     # reset log output buffer

};



done_testing();
