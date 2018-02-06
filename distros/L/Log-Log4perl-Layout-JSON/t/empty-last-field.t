#!/usr/bin/env perl
#
# Test for GitHub issue #2
#

use strict;
use warnings;
use Test::More;
use Log::Log4perl;
use Test::Warnings;

my $conf = <<'CONFEND';
log4perl.rootLogger = INFO, Test
log4perl.appender.Test = Log::Log4perl::Appender::String
log4perl.appender.Test.layout = Log::Log4perl::Layout::JSON
log4perl.appender.Test.layout.canonical = 1
log4perl.appender.Test.layout.field.message = %m
log4perl.appender.Test.layout.field.category = %c
log4perl.appender.Test.layout.field.class = %C
log4perl.appender.Test.layout.field.file = %F{1}
log4perl.appender.Test.layout.field.zzz = 
CONFEND

Log::Log4perl::init(\$conf);

ok my $appender = Log::Log4perl::appender_by_name('Test');
ok my $logger = Log::Log4perl->get_logger('foo');

$logger->info('test');

is_deeply $appender->string, '{"category":"foo","class":"main","file":"empty-last-field.t","message":"test","zzz":""}'."\n";

done_testing;
