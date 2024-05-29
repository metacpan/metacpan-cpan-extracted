## no critic (RequireExtendedFormatting, ProhibitComplexRegexes)

use strict;
use warnings;

use Test::More import => [ qw( explain isa_ok like note ok plan subtest ) ], tests => 5;
use Test::Fatal  qw( exception );
use Test::Output qw( stderr_is );

use Log::Log4perl qw();
use Log::Log4perl::Level;
use YAML qw( Load );

use Log::Log4perl::Config::YamlConfigurator ();

( my $text = <<'EOT' ) =~ s/^ {2}//gm;
  ---
  rootLogger: INFO, SCREEN
  category:
    Foo:
      Bar:
        name: DEBUG, SCREEN, FILE
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
      filename: file.log
      mode: append
      create_at_logtime: 1
      layout:
        name: Log::Log4perl::Layout::PatternLayout::Multiline
        ConversionPattern: '%d{HH:mm:ss} %-5p [%M{3}, %L] - %m%n'
    STDERR: 
      name: Log::Log4perl::Appender::Screen
      stderr: 1
      utf8: 1
      layout: Log::Log4perl::Layout::SimpleLayout
EOT

# Find a workaround to overcome this issue:
# https://github.com/mschilli/log4perl/issues/124

isa_ok my $configurator = Log::Log4perl::Config::YamlConfigurator->new( text => [ $text ] ),
  'Log::Log4perl::Config::YamlConfigurator';
#note explain $configurator;

my $appender_name = 'SOCKET';
like exception {
  $configurator->create_appender_instance( $appender_name )
},
  qr/ERROR: you didn't tell me how to implement your appender '$appender_name' at /,
  "\$data does not know anything about an appender with the name $appender_name";

$appender_name = 'STDERR';
isa_ok my $parentAppender = $configurator->create_appender_instance( $appender_name ), 'Log::Log4perl::Appender';
#note explain $parentAppender;

# The parent appender contains a reference to its child appender (weird?!)
# The parent appender deligates method calls that he does not understand to
# its child appender. Have a look at Log::Log4perl::Appender::AUTOLOAD().
isa_ok my $childAppender = $parentAppender->{ appender }, 'Log::Log4perl::Appender::Screen';
#note explain $childAppender;

subtest 'now use (add) the parent(!) appender' => sub {
  plan tests => 4;

  isa_ok my $logger = Log::Log4perl->get_logger( '' ), 'Log::Log4perl::Logger';
  $logger->level( $ERROR );

  ok not( Log::Log4perl->initialized ), 'not initialized before adding appender'; ## no critic (RequireTestLabels)
  $logger->add_appender( $parentAppender );
  ok +Log::Log4perl->initialized, 'initialized after adding appender';

  stderr_is { $logger->error( 'some error message' ) } "ERROR - some error message\n",
    "check that the $appender_name appender works";
};
