
use strict;
use warnings;
use Test::More;
use Log::Any;

plan tests => 14;

my $out;
my $log = Log::Any->get_logger;
isa_ok $log, 'Log::Any::Proxy::Null', 'no adapter proxy is Null';

my $log_complex = Log::Any->get_logger(
    category => 'Category:',
    prefix => 'Prefix: ',
    formatter => sub { "Formatter: @_" },
    filter => sub { "Filter: @_" },
);
isa_ok $log_complex, 'Log::Any::Proxy::Null',
    'no adapter proxy with formatter is Null';

my $log_explicit = Log::Any->get_logger( proxy_class => 'Test' );
isa_ok $log_explicit, 'Log::Any::Proxy::Test', 'explicit proxy class is correct';

$out = $log->info("test");
is $out, 'test', 'output of test method is returned';
isa_ok $log, 'Log::Any::Proxy::Null',
    'no adapter proxy is still Null after logging';

$out = $log_complex->infof('test');
is $out, 'Prefix: Filter: Category: 6 Formatter: Category: 6 test',
    'output of test method is returned';
isa_ok $log_complex, 'Log::Any::Proxy::Null',
    'no adapter proxy with formatter is still Null after logging';

Log::Any->set_adapter( 'Test' );

isa_ok $log, 'Log::Any::Proxy', 'existing logger reblessed';
isa_ok $log_complex, 'Log::Any::Proxy', 'existing logger reblessed';
isa_ok $log_explicit, 'Log::Any::Proxy::Test', 'explicit proxy class is not reblessed';

$out = $log->info("test");
is Log::Any::Adapter::Test->msgs->[-1]{message}, 'test', 'log is logged';
is $out, 'test', 'output of test method is returned';

$out = $log_complex->infof('test');
is Log::Any::Adapter::Test->msgs->[-1]{message},
    'Prefix: Filter: Category: 6 Formatter: Category: 6 test',
    'proxy attributes are preserved';
is $out, 'Prefix: Filter: Category: 6 Formatter: Category: 6 test',
    'output of test method is returned';

