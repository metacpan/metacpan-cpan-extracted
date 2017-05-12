
use strict;
use warnings;
use Test::More;
use Log::Any;

plan tests => 8;

my $log = Log::Any->get_logger;
isa_ok $log, 'Log::Any::Proxy::Null', 'no adapter proxy is Null';

my $log_complex = Log::Any->get_logger(
    category => 'Category:',
    prefix => 'Prefix: ',
    formatter => sub { "Formatter: @_" },
    filter => sub { "Filter: @_" },
);
isa_ok $log_complex, 'Log::Any::Proxy::Null', 'no adapter proxy is Null';

my $log_explicit = Log::Any->get_logger( proxy_class => 'Test' );
isa_ok $log_explicit, 'Log::Any::Proxy::Test', 'explicit proxy class is correct';

Log::Any->set_adapter( 'Test' );

isa_ok $log, 'Log::Any::Proxy', 'existing logger reblessed';
isa_ok $log_complex, 'Log::Any::Proxy', 'existing logger reblessed';
isa_ok $log_explicit, 'Log::Any::Proxy::Test', 'explicit proxy class is not reblessed';

$log->info("test");
is Log::Any::Adapter::Test->msgs->[-1]{message}, 'test', 'log is logged';

$log_complex->infof('test');
is Log::Any::Adapter::Test->msgs->[-1]{message},
    'Prefix: Filter: Category: 6 Formatter: Category: 6 test',
    'proxy attributes are preserved';

