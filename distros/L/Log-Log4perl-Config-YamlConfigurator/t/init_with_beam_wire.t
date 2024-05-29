use strict;
use warnings;

use Test::More import => [ qw( is is_deeply isa_ok plan subtest ) ];

use Log::Log4perl ();
use Log::Log4perl::Level;

eval { require Beam::Wire } ? plan tests => 10 : plan skip_all => 'Beam::Wire is not installed!';

Beam::Wire->new( file => 't/container.yml' )->get( 'logging/log4perl-init' );

subtest 'examine the root logger' => sub {
  plan tests => 2;

  my $rootLogger = Log::Log4perl->get_logger( '' );
  isa_ok $rootLogger, 'Log::Log4perl::Logger';
  is $rootLogger->level, $INFO, 'check log level';
};

subtest 'check appender definitions' => sub {
  plan tests => 2;

  my $appender = Log::Log4perl->appender_by_name( 'SCREEN' );
  isa_ok $appender, 'Log::Log4perl::Appender::Screen';

  $appender = Log::Log4perl->appender_by_name( 'FILE' );
  isa_ok $appender, 'Log::Log4perl::Appender::File';
};

my $logger = Log::Log4perl->get_logger( 'Foo::Bar' );
isa_ok $logger, 'Log::Log4perl::Logger';

is $logger->level, $DEBUG, 'check log level';

is_deeply $logger->{ appender_names }, [ qw( FILE SCREEN ) ], 'check appender';

is $logger->additivity, 0, 'check additivity';

$logger = Log::Log4perl->get_logger( 'Foo::Bar::Baz' );
isa_ok $logger, 'Log::Log4perl::Logger';

is $logger->level, $INFO, 'check log level';

is_deeply $logger->{ appender_names }, [ qw( FILE ) ], 'check appender';

is $logger->additivity, 1, 'check additivity';
