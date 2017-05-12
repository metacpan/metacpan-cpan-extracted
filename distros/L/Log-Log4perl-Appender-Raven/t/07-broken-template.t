#! perl -T
use strict;
use warnings;

use Test::More;
use Test::Fatal qw/dies_ok lives_ok/;
use Log::Log4perl;


my $conf = q|
log4perl.rootLogger=ERROR, Raven

layout_class=Log::Log4perl::Layout::PatternLayout
layout_pattern=%d %F{1} %L> %m %n

log4perl.appender.Raven=Log::Log4perl::Appender::Raven
log4perl.appender.Raven.sentry_dsn="http://user:key@host.com/project_id"
log4perl.appender.Raven.layout=${layout_class}
log4perl.appender.Raven.layout.ConversionPattern=${layout_pattern}
# This is the broken template string:
log4perl.appender.Raven.sentry_culprit_template="Dear {$kdokwod"

|;

lives_ok { Log::Log4perl::init(\$conf); } "Ok config is goo";

ok( my $ra =  Log::Log4perl->appender_by_name('Raven') , "Ok got appender 'Raven'");
ok( $ra->culprit_text_template(), "Ok got culprit template");

done_testing();
