package Lemonldap::NG::Handler::Main::Init;

our $VERSION = '2.19.0';

package Lemonldap::NG::Handler::Main;

use strict;
use Lemonldap::NG::Common::Conf;

## @imethod void init(hashRef args)
# Read parameters and build the Lemonldap::NG::Common::Conf object.
# @param $args hash containing parameters
sub init($$) {
    my ( $class, $args ) = @_;

    # According to doc, localStorage can be declared in $args root,
    # but it must be in $args->{configStorage}
    foreach (qw(localStorage localStorageOptions)) {
        $args->{configStorage}->{$_} ||= $args->{$_};
    }

    my $tmp = Lemonldap::NG::Common::Conf->new( $args->{configStorage} );
    unless ( $class->confAcc($tmp) ) {
        die(    "$class : unable to build configuration: "
              . "$Lemonldap::NG::Common::Conf::msg" );
    }

    # Merge local configuration parameters so that params defined in
    # startup parameters have precedence over lemonldap-ng.ini params
    $class->localConfig(
        { %{ $class->confAcc->getLocalConf('handler') }, %{$args} } );

    $class->checkTime( $class->localConfig->{checkTime} || $class->checkTime );
    $class->checkMsg( $class->localConfig->{checkMsg}   || $class->checkMsg );

    # Few actions that must be done at server startup:
    # * set log level for Lemonldap::NG logs
    $class->logLevelInit();

    # * set server signature
    $class->serverSignatureInit unless ( $class->localConfig->{hideSignature} );
    1;
}

# @method void logLevelInit
# Set log level for Lemonldap::NG logs
sub logLevelInit {
    my ($class) = @_;
    my $logger = $class->localConfig->{logger} ||=
      $ENV{LLNG_DEFAULTLOGGER} || $class->defaultLogger;
    eval "require $logger";
    die $@ if ($@);
    my $err;
    unless ( $class->localConfig->{logLevel} =~
        /^(?:debug|info|notice|warn|error)$/ )
    {
        $err =
            'Bad logLevel value \''
          . $class->localConfig->{logLevel}
          . "', switching to 'info'\n";
        $class->localConfig->{logLevel} = 'info';
    }
    $class->logger( $logger->new( $class->localConfig ) );
    $class->logger->error($err) if $err;
    $class->logger->debug("Logger $logger loaded");
    $logger = $class->localConfig->{userLogger} || $logger;
    eval "require $logger";
    die $@ if ($@);
    require Lemonldap::NG::Common::Logger::_Duplicate;
    $class->userLogger(
        Lemonldap::NG::Common::Logger::_Duplicate->new(
            $class->localConfig,
            user   => 1,
            logger => $logger,
            dup    => $class->logger
        )
    );
    $class->logger->debug("User logger $logger loaded");

    my $auditlogger =
         $ENV{LLNG_AUDITLOGGER}
      || $class->localConfig->{auditLogger}
      || "Lemonldap::NG::Common::AuditLogger::UserLoggerCompat";
    eval "require $auditlogger";
    die $@ if ($@);
    $class->_auditLogger( $auditlogger->new($class) );
}

# @method void serverSignatureInit
# adapt server signature
sub serverSignatureInit {
    my $class = shift;
    require Lemonldap::NG::Handler;
    my $version = $Lemonldap::NG::Handler::VERSION;
    $class->setServerSignature("Lemonldap::NG/$version");
}

1;
