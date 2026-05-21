## no critic (RequireExtendedFormatting, ProhibitComplexRegexes)

use strict;
use warnings;

use Test::More import => [ qw( is is_deeply isa_ok like plan subtest ) ], tests => 16;
use Test::Fatal qw( exception );

use Log::Log4perl ();
use Log::Log4perl::Level;
use YAML::PP qw( Load );

use Log::Log4perl::Config::YamlConfigurator ();

( my $text = <<'EOT' ) =~ s/^ {2}//gm;
  ---
  rootLogger: INFO, SCREEN
  category:
    Foo:
      Bar:
        name: ${level}, SCREEN, FILE
        Baz: INFO, FILE
  additivity:
    Foo:
      Bar: 0
  appender:
    SCREEN: 
      name: Log::Log4perl::Appender::Screen
      layout: Log::Log4perl::Layout::SimpleLayout
    FILE: 
      name: Log::Log4perl::Appender::File
      filename: file.${DATE}.log
      mode: append
      create_at_logtime: 1
      layout:
        name: Log::Log4perl::Layout::PatternLayout::Multiline
        ConversionPattern: '%d{HH:mm:ss} %-5p [%M{3}, %L] - %m%n'
    LOG:
      name: Log::Log4perl::Appender::File
      filename: file.log
      mode: append
      create_at_logtime: 1
      layout:
        name: Log::Log4perl::Layout::PatternLayout::Multiline
        ConversionPattern: '%d{HH:mm:ss} %-5p [%M{3}, %L] - %m%n'
EOT

like exception { Log::Log4perl::Config::YamlConfigurator->new },
  qr/'text' parameter not set, stopped at/,
  'missing text parameter';

like exception { Log::Log4perl::Config::YamlConfigurator->new( data => [] ) },
  qr/'data' parameter has to be a HASH reference with the keys 'category', and 'appender', stopped/,
  'data parameter is not a HASH reference';
like exception { Log::Log4perl::Config::YamlConfigurator->new( data => { appender => {} } ) },
  qr/'data' parameter has to be a HASH reference with the keys 'category', and 'appender', stopped/,
  'data parameter has no category key';
like exception { Log::Log4perl::Config::YamlConfigurator->new( data => { category => {} } ) },
  qr/'data' parameter has to be a HASH reference with the keys 'category', and 'appender', stopped/,
  'data parameter has no appender key';

my $configurator = Log::Log4perl::Config::YamlConfigurator->new( subst => { level => 'DEBUG' }, text => [ $text ] );
isa_ok $configurator, 'Log::Log4perl::Config::YamlConfigurator';

local $ENV{ DATE } = '2026-05-05';

is_deeply $configurator->parse,
  {
  additivity => {
    Foo => {
      Bar => {
        value => 0
      }
    }
  },
  appender => {
    FILE => {
      value             => 'Log::Log4perl::Appender::File',
      create_at_logtime => { value => 1 },
      filename          => { value => "file.$ENV{ DATE }.log" },
      layout            => {
        value             => 'Log::Log4perl::Layout::PatternLayout::Multiline',
        ConversionPattern => { value => '%d{HH:mm:ss} %-5p [%M{3}, %L] - %m%n' }
      },
      mode => { value => 'append' }
    },
    LOG => {
      value             => 'Log::Log4perl::Appender::File',
      create_at_logtime => { value => 1 },
      filename          => { value => 'file.log' },
      layout            => {
        value             => 'Log::Log4perl::Layout::PatternLayout::Multiline',
        ConversionPattern => { value => '%d{HH:mm:ss} %-5p [%M{3}, %L] - %m%n' }
      },
      mode => { value => 'append' }
    },
    SCREEN => {
      value  => 'Log::Log4perl::Appender::Screen',
      layout => { value => 'Log::Log4perl::Layout::SimpleLayout' }
    }
  },
  category => {
    Foo => {
      Bar => {
        value => 'DEBUG, SCREEN, FILE',
        Baz   => {
          value => 'INFO, FILE'
        }
      }
    }
  },
  rootLogger => { value => 'INFO, SCREEN' }
  },
  'check parse()';

Log::Log4perl->init( $configurator );

subtest 'examine the root logger' => sub {
  plan tests => 2;

  my $rootLogger = Log::Log4perl->get_logger( '' );
  isa_ok $rootLogger, 'Log::Log4perl::Logger';
  is $rootLogger->level, $INFO, 'check log level';
};

subtest 'check appender definitions' => sub {
  plan tests => 4;

  is keys( %{ Log::Log4perl->appenders } ), 2, '3 appenders configured but only 2 were created';

  my $appender = Log::Log4perl->appender_by_name( 'SCREEN' );
  isa_ok $appender, 'Log::Log4perl::Appender::Screen';

  $appender = Log::Log4perl->appender_by_name( 'FILE' );
  isa_ok $appender, 'Log::Log4perl::Appender::File';

  is $appender->filename, "file.$ENV{ DATE }.log",
    'check filename attribute of File appender after variable substitution';
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
