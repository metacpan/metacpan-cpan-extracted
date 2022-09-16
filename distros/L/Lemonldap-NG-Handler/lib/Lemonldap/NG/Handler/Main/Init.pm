package Lemonldap::NG::Handler::Main::Init;

our $VERSION = '2.0.15';

package Lemonldap::NG::Handler::Main;

use strict;
use Lemonldap::NG::Common::Conf;

our $statusInit = 1;

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

    # Few actions that must be done at server startup:
    # * set log level for Lemonldap::NG logs
    $class->logLevelInit();

    # * set server signature
    $class->serverSignatureInit unless ( $class->localConfig->{hideSignature} );

    # * launch status process
    $class->statusInit();
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
}

# @method void serverSignatureInit
# adapt server signature
sub serverSignatureInit {
    my $class = shift;
    require Lemonldap::NG::Handler;
    my $version = $Lemonldap::NG::Handler::VERSION;
    $class->setServerSignature("Lemonldap::NG/$version");
}

## @ifn protected void statusInit()
# Launch the status process
sub statusInit {
    my ($class) = @_;
    return unless ( $class->localConfig->{status} and $statusInit );
    $statusInit = 0;
    return if ( $class->tsv->{statusPipe} );
    if ( $ENV{LLNGSTATUSHOST} ) {
        require IO::Socket::INET;
        $class->tsv->{statusPipe} = IO::Socket::INET->new(
            Proto    => 'udp',
            PeerAddr => $ENV{LLNGSTATUSHOST}
        );
        $class->tsv->{statusOut} = undef;
    }
    else {
        require IO::Pipe;
        my $statusPipe = IO::Pipe->new;
        my $statusOut  = IO::Pipe->new;
        if ( my $pid = fork() ) {
            $class->logger->debug("Status collector launched ($pid)");
            $statusPipe->writer();
            $statusOut->reader();
            $statusPipe->autoflush(1);
            ( $class->tsv->{statusPipe}, $class->tsv->{statusOut} ) =
              ( $statusPipe, $statusOut );
        }
        else {
            $statusPipe->reader();
            $statusOut->writer();
            my $fdin  = $statusPipe->fileno;
            my $fdout = $statusOut->fileno;
            open STDIN,  "<&$fdin";
            open STDOUT, ">&$fdout";
            my $perl_exec = ( $^X =~ /perl/ ) ? $^X : 'perl';
            exec $perl_exec, '-MLemonldap::NG::Handler::Lib::Status',

              # Insert @INC in Perl path
              map( { "-I$_" } @INC ),

              # Command to launch
              '-e', '&Lemonldap::NG::Handler::Lib::Status::run()',

              # Optional arg: UDP socket to listen to
              (
                $ENV{LLNGSTATUSLISTEN}
                ? ( '--', '--udp', $ENV{LLNGSTATUSLISTEN} )
                : ()
              );
        }
    }
}

1;
