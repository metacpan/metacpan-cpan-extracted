# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Log-Log4perl-DataDumper.t'

#########################

use Test::More tests => 5;
BEGIN { use_ok('Log::Log4perl::DataDumper') };

#########################

use Log::Log4perl qw(:levels);

my $logger = Log::Log4perl->get_logger('Testing');

my $appender = Log::Log4perl::Appender->new('Log::Log4perl::Appender::String');

$appender->layout(Log::Log4perl::Layout::PatternLayout->new('[%m]%n'));

$logger->add_appender($appender);

$logger->level($INFO);

#----------------------------------------------------------------------

$logger->info('info message logged');
$logger->debug('debug message suppressed');

my $logoutput = $appender->string;

is($logoutput, "[info message logged]\n", 'Normal message.');

$appender->string('');

#----------------------------------------------------------------------

$logger->info('Object: ', { a => 'b' });

$logoutput = $appender->string;

like($logoutput,
     qr/^\[Object: HASH\(0x[0-9a-f]+\)\]\n$/,
     'Object pre-override');

$appender->string('');

#----------------------------------------------------------------------

Log::Log4perl::DataDumper::override($logger);

$logger->info('Object: ', { a => 'b' });

$logoutput = $appender->string;

is($logoutput, <<'LOG', 'Object override');
[Object: {
  a => 'b'
}
]
LOG

$appender->string('');

#----------------------------------------------------------------------

$logger->set_output_methods;

Log::Log4perl::DataDumper::override($logger, 1);

$logger->info('Object: ', { a => 'b' });

$logoutput = $appender->string;

is($logoutput, <<'LOG', 'Object override multiline');
[Object: ]
[{]
[  a => 'b']
[}]
LOG

$appender->string('');

#----------------------------------------------------------------------
