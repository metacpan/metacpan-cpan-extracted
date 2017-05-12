#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;

use_ok 'Log::Log4perl';
use_ok('Log::Log4perl::Appender::Elasticsearch::Bulk');

isa_ok(
    'Log::Log4perl::Appender::Elasticsearch::Bulk',
    'Log::Log4perl::Appender::Elasticsearch'
);

can_ok(
    'Log::Log4perl::Appender::Elasticsearch::Bulk', qw/
        log
        DESTROY
        /
);

my %args = (
    nodes       => 'localhost:9200',
    'index'     => 'log4perl',
    type        => 'entry',
    flush_count => 3,
    use_https   => 0,
    user_agent  => { timeout => 5 },
    headers     => { 'User-Agent' => ['foo'] },
    body        => { module => '%M', level => '%p', line => '%L' }
);

new_ok 'Log::Log4perl::Appender::Elasticsearch::Bulk', [%args];

subtest 'log', sub {
    $ENV{LOG2NODE} || plan skip_all => 'log without $ENV{LOG2NODE}';

    ok(Log::Log4perl->init(\<<"HERE"), 'Log::Log4perl->init');
log4perl.logger = DEBUG, ESB

log4perl.appender.FileAppndr1      = Log::Log4perl::Appender::File
log4perl.appender.FileAppndr1.filename = sub {return "foo.log" }
log4perl.appender.FileAppndr1.layout   = \
                            Log::Log4perl::Layout::SimpleLayout

log4perl.appender.ESB=Log::Log4perl::Appender::Elasticsearch::Bulk
log4perl.appender.ESB.flush_count = 2

log4perl.appender.ESB.layout = Log::Log4perl::Layout::NoopLayout
log4perl.appender.ESB.body.level = %p
log4perl.appender.ESB.body.module = %M
log4perl.appender.ESB.body.line = %L
log4perl.appender.ESB.body.xxx = %X{xxx}

log4perl.appender.ESB.nodes = $ENV{LOG2NODE}
log4perl.appender.ESB.index = log4perl
log4perl.appender.ESB.type = entry

log4perl.appender.ESB.use_https = 0
log4perl.appender.ESB.ua.timeout = 5

HERE

    ok(my $l = Log::Log4perl::get_logger(), 'Log::Log4perl::get_logger()');

    foreach my $ll (qw/warn info debug/) {
        Log::Log4perl::MDC->put('xxx', 'x-' . $ll);
        ok $l->$ll("a $ll log message!"), "$ll";
    }
};

done_testing();

sub END { note "the end" }
